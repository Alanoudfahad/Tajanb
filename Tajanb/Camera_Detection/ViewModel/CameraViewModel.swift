//
//  CameraViewModel.swift
//  Text_Detection
//
//  Created by Afrah Saleh on 11/03/1446 AH.
//

import Foundation
import AVFoundation
import Vision
import CoreHaptics
import SwiftData
import SwiftUICore
import UIKit

class CameraViewModel: NSObject, ObservableObject {
    @Published var detectedText: [(category: String, word: String, hiddenSynonyms: [String])] = []
    private var matchedWordsSet: Set<String> = [] // To keep track of matched words
    private var hapticManager = HapticManager()
    @Published var availableCategories = [Category]()
    @Published var freeAllergenMessage: String?
    @Published var selectedWords = [String]()
    private var session: AVCaptureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput() // Add photo output for capturing still images
    private var capturedPhotoCompletion: ((UIImage?) -> Void)? // Completion handler for captured photo
    @Published var cameraPermissionGranted: Bool = false
    private var textRequest = VNRecognizeTextRequest(completionHandler: nil)
    private var regionOfInterest: CGRect = .zero
    private let screenBounds = UIScreen.main.bounds
    override init() {
        super.init()
        loadCategories()
        configureTextRecognitions()
    }
    
    func updateROI(boxWidthPercentage: CGFloat, boxHeightPercentage: CGFloat) {
        let boxWidth = screenBounds.width * boxWidthPercentage
        let boxHeight = screenBounds.height * boxHeightPercentage
        let boxOriginX = (screenBounds.width - boxWidth) / 2
        let boxOriginY = (screenBounds.height - boxHeight) / 2

        regionOfInterest = CGRect(x: boxOriginX, y: boxOriginY, width: boxWidth, height: boxHeight)

        // Debugging: Log the region of interest values
        print("Region of Interest: \(regionOfInterest)")
    }

    private func transformBoundingBox(_ boundingBox: CGRect) -> CGRect {
        // Convert the bounding box from normalized coordinates (0.0 - 1.0) to screen coordinates
        let x = boundingBox.origin.x * screenBounds.width
        let y = (1.0 - boundingBox.origin.y - boundingBox.height) * screenBounds.height // Invert y-axis
        let width = boundingBox.width * screenBounds.width
        let height = boundingBox.height * screenBounds.height

        let transformedRect = CGRect(x: x, y: y, width: width, height: height)

        // Debugging: Log the transformed bounding box
        print("Transformed Bounding Box: \(transformedRect)")

        return transformedRect
    }
    
    private func loadCategories() {
        let languageCode = Locale.current.language.languageCode?.identifier
        let fileName = languageCode == "ar" ? "categories_ar" : "categories_en"
        
        guard let path = Bundle.main.path(forResource: fileName, ofType: "json") else {
            print("Error finding \(fileName).json")
            return
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let decoder = JSONDecoder()
            availableCategories = try decoder.decode([Category].self, from: data)
            print("Loaded Categories: \(availableCategories)")
        } catch {
            print("Error loading categories from JSON: \(error)")
        }
    }
    
    func saveSelectedWords(using modelContext: ModelContext) {
        let fetchDescriptor = FetchDescriptor<SelectedWord>()
        if let existingWords = try? modelContext.fetch(fetchDescriptor) {
            for word in existingWords {
                modelContext.delete(word)
            }
        }
        
        for word in selectedWords {
            let newWord = SelectedWord(word: word)
            modelContext.insert(newWord)
        }
        
        try? modelContext.save()
    }
    
    func loadSelectedWords(using modelContext: ModelContext) {
        let fetchDescriptor = FetchDescriptor<SelectedWord>()
        if let savedWordsData = try? modelContext.fetch(fetchDescriptor) {
            selectedWords = savedWordsData.map { $0.word }
        } else {
            selectedWords = []
        }
    }
    
    func updateSelectedWords(with words: [String], using modelContext: ModelContext) {
        selectedWords = words
        saveSelectedWords(using: modelContext)
        print("Selected words updated: \(selectedWords)")
    }
    
    private func configureCaptureSession() {
           session.beginConfiguration()
           session.sessionPreset = .hd1280x720

           if let currentInput = session.inputs.first {
               session.removeInput(currentInput)
           }

           guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                 let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }

           if session.canAddInput(videoInput) {
               session.addInput(videoInput)
           }
           
           // Add photo output to the session
           if session.canAddOutput(photoOutput) {
               session.addOutput(photoOutput)
           }

           session.commitConfiguration()

           do {
               try videoDevice.lockForConfiguration()

               if videoDevice.isFocusModeSupported(.continuousAutoFocus) {
                   videoDevice.focusMode = .continuousAutoFocus
               }

               if videoDevice.isExposureModeSupported(.continuousAutoExposure) {
                   videoDevice.exposureMode = .continuousAutoExposure
               }

               videoDevice.unlockForConfiguration()
           } catch {
               print("Error configuring camera: \(error)")
           }
       }

       // Capture a still photo
       func capturePhoto(completion: @escaping (UIImage?) -> Void) {
           let settings = AVCapturePhotoSettings()
           photoOutput.capturePhoto(with: settings, delegate: self)
           capturedPhotoCompletion = completion
       }
    private func configureTextRecognitions() {
        textRequest = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }

            if let error = error {
                print("Error recognizing text: \(error)")
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                return
            }

            let filteredObservations = observations.filter { observation in
                // Project the bounding box of detected text from the camera feed into screen coordinates
                let transformedBoundingBox = self.transformBoundingBox(observation.boundingBox)

                // Debugging: Log whether the bounding box intersects with the ROI
                let intersects = self.regionOfInterest.intersects(transformedBoundingBox)
                print("Bounding Box: \(transformedBoundingBox), Intersects ROI: \(intersects)")

                // Check if the transformed bounding box intersects with the region of interest
                return intersects
            }

            let detectedStrings = filteredObservations.compactMap { $0.topCandidates(1).first?.string }
            DispatchQueue.main.async {
                self.processDetectedText(detectedStrings)
            }
        }

        textRequest.recognitionLevel = .accurate
        textRequest.recognitionLanguages = ["ar", "en"]
        textRequest.usesLanguageCorrection = true
        textRequest.minimumTextHeight = 0.02 // Adjust this to filter out small/noisy text
    }
    func startTextRecognition(from image: UIImage) {
        guard let cgImage = image.cgImage else {
            print("Failed to convert UIImage to CGImage")
            return
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([textRequest])
        } catch {
            print("Failed to perform text recognition request: \(error.localizedDescription)")
        }
    }

    func processDetectedText(_ detectedStrings: [String]) {
        let combinedText = detectedStrings.joined(separator: " ")
        let cleanedText = preprocessText(combinedText)

        print("Detected Combined Text: \(cleanedText)")

        let words = cleanedText.split(separator: " ").map { $0.trimmingCharacters(in: .punctuationCharacters).lowercased() }

        var foundAllergens = false

        for word in words {
            if checkAllergy(for: word) {
                foundAllergens = true
            }
        }

        if !foundAllergens {
            if fuzzyContains(cleanedText, keyword: "المكونات") {
                freeAllergenMessage = getLocalizedMessage()
            } else {
                freeAllergenMessage = Locale.current.language.languageCode == "ar" ? "خطأ: لم يتم العثور على المكونات" : "Error: Ingredients not found"
            }
        } else {
            freeAllergenMessage = nil
        }
        
        print("Free Allergen Message: \(freeAllergenMessage ?? "No Message")")
    }
    
    func fuzzyContains(_ text: String, keyword: String) -> Bool {
        // Build a pattern that allows the keyword to be surrounded by non-letter characters or spaces
        let pattern = "\\b\(keyword)\\b"
        
        // Search for the keyword using case insensitivity and diacritic insensitivity
        let result = text.range(of: pattern, options: [.regularExpression, .caseInsensitive, .diacriticInsensitive]) != nil
        print("Fuzzy match for keyword '\(keyword)': \(result)")  // Log the result
        return result
    }
    
    private func checkAllergy(for word: String) -> Bool {
        let cleanedWord = word.trimmingCharacters(in: .punctuationCharacters).lowercased() // Clean the word

        if let result = isTargetWord(cleanedWord) {
            // Check if this word has already been detected to avoid duplicates
            if !matchedWordsSet.contains(cleanedWord) {
                // Check if the detected word matches a selected allergen
                if selectedWords.contains(result.1) {
                    DispatchQueue.main.async {
                        self.detectedText.append((category: result.0, word: result.1, hiddenSynonyms: result.2))
                        
                        // Perform haptic feedback only if the detected word matches a selected allergen
                        self.hapticManager.performHapticFeedback()
                        
                        self.matchedWordsSet.insert(cleanedWord)
                    }
                    return true // Allergen found
                }
            }
        } else {
            // Remove the word from the matched set if no longer matching
            matchedWordsSet.remove(cleanedWord)
        }
        return false // No allergen found for this word
    }

    private func getLocalizedMessage() -> String {
        return Locale.current.language.languageCode == "ar" ? "خالي من مسببات الحساسية" : "Allergen-free"
    }

    // Method to reset detected text and matched words
    func resetPredictions() {
        detectedText.removeAll() // Clear the existing predictions
        matchedWordsSet.removeAll() // Clear matched words set
        freeAllergenMessage = getLocalizedMessage() // Reset the message to allergen-free
    }



    func isTargetWord(_ text: String) -> (String, String, [String])? {
        let lowercasedText = text.lowercased()
        for category in availableCategories {
            for word in category.words {
                if word.word.lowercased() == lowercasedText ||
                    word.hiddenSynonyms?.contains(where: { $0.lowercased() == lowercasedText }) == true {
                    let synonyms = word.hiddenSynonyms ?? []
                    return (category.name, word.word, synonyms)
                }
            }
        }
        return nil
    }
    
    // Assuming 'selectedWords' is a list of user-selected allergens
    private func isSelectedWord(_ word: String) -> Bool {
        // Check if the word is in the list of selected allergens
        let isMatch = selectedWords.contains { selectedWord in
            // Use case-insensitive and diacritic-insensitive comparison
            return word.compare(selectedWord, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
        
        // Log the result for debugging
        print("Ingredient '\(word)' is a selected word: \(isMatch)")
        
        return isMatch
    }
    
    func preprocessText(_ text: String) -> String {
        var cleanedText = text
            .replacingOccurrences(of: "\n", with: " ")  // Replace newlines with space
            .replacingOccurrences(of: "-", with: " ")   // Replace hyphens with space
            .replacingOccurrences(of: "[^\\p{L}\\p{Z}]", with: " ", options: .regularExpression)  // Remove non-letters and non-spaces
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)  // Replace multiple spaces with a single space
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Fix common OCR mistakes (e.g., "االمكونات" -> "المكونات")
        cleanedText = cleanedText.replacingOccurrences(of: "االمكونات", with: "المكونات")
        
        return cleanedText.applyingTransform(.stripCombiningMarks, reverse: false) ?? cleanedText
    }

    
    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            if !self.session.isRunning {
                self.session.startRunning()  // Ensure the session starts running
            }
        }
    }

       func stopSession() {
           session.stopRunning()
       }

       func getSession() -> AVCaptureSession {
           return session
       }
    
    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async {
                self.cameraPermissionGranted = true
                completion(true)
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.cameraPermissionGranted = granted
                    completion(granted)
                }
            }
        default:
            DispatchQueue.main.async {
                self.cameraPermissionGranted = false
                completion(false)
            }
        }
    }
    
    func prepareSession() {
        // Check if permission is already granted before requesting it
        if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
            cameraPermissionGranted = true
            configureAndStartSession()  // Start session immediately when already authorized
        } else {
            requestCameraPermission { [weak self] granted in
                if granted {
                    self?.configureAndStartSession()  // Immediately configure and start session when permission is granted
                } else {
                    print("Camera permission not granted.")
                }
            }
        }
    }

    private func configureAndStartSession() {
        configureCaptureSession()
        
        // Ensure session starts immediately after configuration
        startSession()
    }
}

extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil, let imageData = photo.fileDataRepresentation() else {
            print("Error capturing photo: \(error?.localizedDescription ?? "Unknown error")")
            capturedPhotoCompletion?(nil)
            return
        }
        let image = UIImage(data: imageData)
        capturedPhotoCompletion?(image)
    }
}


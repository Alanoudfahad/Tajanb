//
//  CameraViewModel.swift
//  Text_Detection
//
//  Created by Afrah Saleh on 11/03/1446 AH.
//

import Foundation
import AVFoundation
import Vision
import UIKit
import Combine

// Main ViewModel to handle camera input, text recognition, and allergen detection
class CameraViewModel: NSObject, ObservableObject, CameraManagerDelegate {
    // Published properties to update UI with detected text, allergen messages, and camera permissions
    @Published var detectedText: [DetectedTextItem] = []
    @Published var freeAllergenMessage: String?
    @Published var cameraPermissionGranted: Bool = false
    @Published var hasDetectedIngredients: Bool = false
    @Published var liveDetectedText: String = ""
    
    // Set to keep track of matched words to avoid duplicates
    var matchedWordsSet: Set<String> = []
    // Flag to track if allergens have been found in the text
    var foundAllergens = false

    // ViewModels to manage Firebase and user-selected allergen words
    let firestoreViewModel: FirestoreViewModel
    let selectedWordsViewModel: SelectedWordsViewModel
    let cameraManager: CameraManager  // Manages camera input
    
    // Vision request for text recognition
    var textRequest = VNRecognizeTextRequest(completionHandler: nil)
    var hapticManager = HapticManager()  // Manages haptic feedback

    private let screenBounds = UIScreen.main.bounds  // Screen dimensions for ROI calculations
    var regionOfInterest: CGRect = .zero  // Defines region of interest for text recognition
    
    // Initialize with dependencies and configure text recognition
    override init() {
        self.firestoreViewModel = FirestoreViewModel()
        self.selectedWordsViewModel = SelectedWordsViewModel(firestoreViewModel: firestoreViewModel)
        self.cameraManager = CameraManager()
        super.init()
        cameraManager.delegate = self
        configureTextRecognitions()
    }
    
    // MARK: - CameraManagerDelegate methods
    
    // Called when a new frame is captured from the camera
    func cameraManager(_ manager: CameraManager, didOutput sampleBuffer: CMSampleBuffer) {
        processFrame(sampleBuffer: sampleBuffer)
    }

    // Called when a photo is captured, initiates text recognition on the photo
    func cameraManager(_ manager: CameraManager, didCapturePhoto image: UIImage?) {
        guard let image = image else { return }
        startTextRecognition(from: image)
        
        // Process text from live preview and detect allergens
        let detectedTextArray = liveDetectedText.split(separator: " ").map { String($0) }
        processAllergensFromCapturedText(detectedTextArray)
    }

    
    // MARK: - Camera Permission and Session Handling
    
    // Request camera permission and update the UI
    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        cameraManager.requestCameraPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.cameraPermissionGranted = granted
                completion(granted)
            }
        }
    }

    // Prepare the camera session based on permission status
    func prepareSession() {
        if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
            cameraPermissionGranted = true
            cameraManager.prepareSession()
        } else {
            requestCameraPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.cameraPermissionGranted = granted
                    if granted {
                        self?.cameraManager.prepareSession()
                    } else {
                        print("Camera permission not granted.")
                    }
                }
            }
        }
    }

    // Process each frame from the camera feed for text recognition
    func processFrame(sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try requestHandler.perform([textRequest])
        } catch {
            print("Error processing frame: \(error)")
        }
    }
    
    // Update the region of interest for text recognition based on screen dimensions
    func updateROI(boxWidthPercentage: CGFloat, boxHeightPercentage: CGFloat) {
        let boxWidth = screenBounds.width * boxWidthPercentage
        let boxHeight = screenBounds.height * boxHeightPercentage
        let boxOriginX = (screenBounds.width - boxWidth) / 2
        let boxOriginY = (screenBounds.height - boxHeight) / 2
        regionOfInterest = CGRect(x: boxOriginX, y: boxOriginY, width: boxWidth, height: boxHeight)
    }
    
    // Transform bounding box from normalized coordinates to screen coordinates
    func transformBoundingBox(_ boundingBox: CGRect) -> CGRect {
        let x = boundingBox.origin.x * screenBounds.width
        let y = (1.0 - boundingBox.origin.y - boundingBox.height) * screenBounds.height  // Invert y-axis
        let width = boundingBox.width * screenBounds.width
        let height = boundingBox.height * screenBounds.height
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    
    // MARK: - Text Recognition Functions
    
    // Configure Vision text recognition request with region of interest and error handling
    func configureTextRecognitions() {
        textRequest = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error recognizing text: \(error)")
                return
            }

            // Filter recognized text within the region of interest
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            let filteredObservations = observations.filter { observation in
                let transformedBoundingBox = self.transformBoundingBox(observation.boundingBox)
                return self.regionOfInterest.intersects(transformedBoundingBox)
            }

            // Extract recognized strings from filtered observations
            let detectedStrings = filteredObservations.compactMap { $0.topCandidates(1).first?.string }
            DispatchQueue.main.async {
                self.processDetectedText(detectedStrings)
            }
        }

        textRequest.recognitionLevel = .accurate
        textRequest.recognitionLanguages = ["ar", "en"]
        textRequest.usesLanguageCorrection = true
        textRequest.minimumTextHeight = 0.02  // Filter out very small text
    }

    // Check if text matches a target allergen word
    func isTargetWord(_ text: String) -> (String, String, [String])? {
        let lowercasedText = text.lowercased()
        for category in firestoreViewModel.availableCategories {
            for word in category.words {
                if word.word.lowercased() == lowercasedText ||
                    word.hiddenSynonyms.contains(where: { $0.lowercased() == lowercasedText }) == true {
                    return (category.name, word.word, word.hiddenSynonyms)
                }
            }
        }
        return nil
    }

    // Verify if a word is selected by the user as an allergen
    private func isSelectedWord(_ word: String) -> Bool {
        return selectedWordsViewModel.selectedWords.contains { selectedWord in
            word.compare(selectedWord, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
    }
    
    // Start text recognition from a static image
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

    // Reset detected text and flags
    func resetState() {
        DispatchQueue.main.async {
            self.detectedText = []
            self.freeAllergenMessage = nil
            self.hasDetectedIngredients = false
            self.foundAllergens = false
            self.matchedWordsSet.removeAll()
            self.liveDetectedText = ""
        }
    }

    // Process detected text, checking for allergen-related keywords
    func processDetectedText(_ detectedStrings: [String]) {
        let combinedText = detectedStrings.joined(separator: " ")
        let cleanedText = preprocessText(combinedText)
        
        self.liveDetectedText = cleanedText

        // Synonyms to check for "ingredients"
        let ingredientSynonyms = [
            "المكونات", "مكونات", "مواد", "عناصر", "المحتويات", "محتويات", "تركيبة",
            "تركيب", "خليط", "تركيبات", "مواد خام", "مكونات الغذاء",
            "مكونات المنتج", "Ingredients", "Contents", "Composition",
            "Components", "Formula", "Constituents", "Mixture", "Blend",
            "Ingredients List", "Product Ingredients", "Food Ingredients",
            "Raw Materials"
        ]
        
        // Detect presence of "ingredient" words
        if ingredientSynonyms.contains(where: { fuzzyContains(cleanedText, keyword: $0) }) {
            hasDetectedIngredients = true
        } else {
            hasDetectedIngredients = false
        }

        // Update allergen-free message based on detection
        if foundAllergens {
            freeAllergenMessage = nil
            hasDetectedIngredients = true
        } else if hasDetectedIngredients {
            freeAllergenMessage = getLocalizedMessage()
        } else {
            freeAllergenMessage = Locale.current.language.languageCode == "ar" ? "خطأ: لم يتم العثور على المكونات" : "Error: Ingredients not found"
        }
    }


    
    // Process allergens in detected text and update message state
    func processAllergensFromCapturedText(_ detectedStrings: [String]) {
        let combinedText = detectedStrings.joined(separator: " ")
        let cleanedText = preprocessText(combinedText)
        let words = cleanedText.split(separator: " ").map { $0.trimmingCharacters(in: .punctuationCharacters).lowercased() }
        
        foundAllergens = false  // Reset allergens flag
        
        // Check for allergens in phrases
        let maxPhraseLength = 4
        let N = words.count

        for i in 0..<N {
            for L in 1...maxPhraseLength {
                if i + L <= N {
                    let phrase = words[i..<i+L].joined(separator: " ")
                    if checkAllergy(for: phrase) {
                        foundAllergens = true
                    }
                }
            }
        }

        // Update message if no allergens are found
        if !foundAllergens {
            freeAllergenMessage = Locale.current.language.languageCode == "ar" ? "خالي من مسببات الحساسية" : "Allergen-free"
        }
    }

    // Helper for fuzzy matching keywords in text
    func fuzzyContains(_ text: String, keyword: String) -> Bool {
        let pattern = "\\b\(keyword)\\b"
        return text.range(of: pattern, options: [.regularExpression, .caseInsensitive, .diacriticInsensitive]) != nil
    }

    // Check if a phrase matches any user-selected allergens
    private func checkAllergy(for phrase: String) -> Bool {
        let cleanedPhrase = phrase.trimmingCharacters(in: .punctuationCharacters).lowercased()
        
        if let result = isTargetWord(cleanedPhrase) {
            if !matchedWordsSet.contains(cleanedPhrase), selectedWordsViewModel.selectedWords.contains(result.1) {
                DispatchQueue.main.async {
                    self.detectedText.append(DetectedTextItem(category: result.0, word: result.1, hiddenSynonyms: result.2))
                    self.hapticManager.performHapticFeedback()
                    self.matchedWordsSet.insert(cleanedPhrase)
                }
                return true
            }
        } else {
            matchedWordsSet.remove(cleanedPhrase)
        }
        return false
    }

    // Get localized allergen-free message
    private func getLocalizedMessage() -> String {
        return Locale.current.language.languageCode == "ar" ? "خالي من مسببات الحساسية" : "Allergen-free"
    }

    // Preprocess text to handle OCR errors and normalize content
    func preprocessText(_ text: String) -> String {
        var cleanedText = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "[^\\p{L}\\p{Z}]", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .applyingTransform(.stripCombiningMarks, reverse: false) ?? text
        return cleanedText.lowercased()
    }

    
    
    // MARK: - Camera View Helper Functions
    
    // Reset predictions and clear stored matches
    func resetPredictions() {
        detectedText.removeAll()
        matchedWordsSet.removeAll()
        freeAllergenMessage = getLocalizedMessage()
    }
    
    // Allow retaking photo and restart camera session
    func retakePhoto() {
        resetState()
        resetPredictions()
        cameraManager.startSession()
    }
}
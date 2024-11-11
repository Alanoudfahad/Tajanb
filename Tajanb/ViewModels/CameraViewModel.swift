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
    @Published var detectedText: [(category: String, word: String, hiddenSynonyms: [String])] = []
    @Published var freeAllergenMessage: String?
    @Published var cameraPermissionGranted: Bool = false
    @Published var hasDetectedIngredients: Bool = false
    @Published var liveDetectedText: String = ""
    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    var matchedWordsSet: Set<String> = []
    var foundAllergens = false
    let firestoreViewModel: FirestoreViewModel
    let selectedWordsViewModel: SelectedWordsViewModel
    let cameraManager: CameraManager  // Manages camera input
    let cameraFunctions: CameraFunctionalitiesViewModel
    var textRequest = VNRecognizeTextRequest(completionHandler: nil)
    var hapticManager = HapticManager()  // Manages haptic feedback
    @Published var currentZoom: CGFloat = 1.0  // Bind to UI if needed
    
    override init() {
        self.firestoreViewModel = FirestoreViewModel()
        self.selectedWordsViewModel = SelectedWordsViewModel(firestoreViewModel: firestoreViewModel)
        self.cameraManager = CameraManager()
        self.cameraFunctions = CameraFunctionalitiesViewModel(CameraManager: cameraManager)
        
        super.init()
        
        cameraManager.delegate = self
        configureTextRecognitions()
    }
    

    // MARK: - CameraManagerDelegate methods
   
   // Called when a new frame is captured from the camera
   func cameraManager(_ manager: CameraManager, didOutput sampleBuffer: CMSampleBuffer) {
       processFrame(sampleBuffer: sampleBuffer)
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
      // Handle zoom changes from the UI
        func handleZoom(delta: CGFloat) {
            let newZoom = currentZoom * delta
            cameraManager.setZoomFactor(newZoom)
            // Optionally, update the published property
            DispatchQueue.main.async {
                self.currentZoom = newZoom
            }
        }
      // MARK: - Focus Handling
         
         /// Sets the focus at the given normalized point
         /// - Parameter point: CGPoint with x and y in [0, 1]
         func setFocus(at point: CGPoint) {
             cameraFunctions.setFocusPoint(point)
         }

    
    // Handle tap gestures by setting the focus (focus indicator is managed in the view)
    func handleTap(location: CGPoint) {
        let screenSize = UIScreen.main.bounds.size
        let normalizedX = location.x / screenSize.width
        let normalizedY = location.y / screenSize.height
        
        // Set focus in CameraManager (ViewModel handles the camera logic)
        setFocus(at: CGPoint(x: normalizedX, y: normalizedY))
        
        // Trigger haptic feedback (optional)
        impactFeedback.impactOccurred()
    }

    func toggleFlash(isOn: Bool) {
        cameraManager.toggleFlash(isOn: isOn)
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

    // MARK: - Text Recognition Functions
    
     //Configure Vision text recognition request with region of interest and error handling
    func configureTextRecognitions() {
        textRequest = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error recognizing text: \(error)")
                return
            }
            // Process recognized text observations
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                print("No recognized text found")
                return
            }

            let detectedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
            DispatchQueue.main.async {
                self.processDetectedText(detectedStrings)
            }
        }

        textRequest.recognitionLevel = .accurate
        textRequest.recognitionLanguages = ["ar", "en"]
        textRequest.usesLanguageCorrection = true
        textRequest.minimumTextHeight = 0.01
        textRequest.revision = 1 // Ensures proper handling of different text formats
    }

    func isTargetWord(_ text: String) -> (String, String, [String])? {
        for category in firestoreViewModel.availableCategories {
            for word in category.words {
                if word.word.compare(text, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame ||
                   word.hiddenSynonyms.contains(where: { $0.compare(text, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame }) {
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

    func startTextRecognition(from image: UIImage) {
        guard let cgImage = image.cgImage else {
            print("Failed to convert UIImage to CGImage")
            return
        }

        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }

            if let error = error {
                print("Error recognizing text from image: \(error)")
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                print("No recognized text found")
                return
            }

            // Filter out text with low confidence
            let detectedStrings = observations.compactMap { observation -> String? in
                guard let topCandidate = observation.topCandidates(1).first else {
                    return nil
                }
                // Use confidence threshold (e.g., 0.8)
                return observation.confidence >= 0.8 ? topCandidate.string : nil
            }

            DispatchQueue.main.async {
                let combinedText = detectedStrings.joined(separator: " ")
                let cleanedText = self.preprocessText(combinedText)

                // Update 'liveDetectedText' and other variables as needed
                self.liveDetectedText = cleanedText

                // Process allergens from the captured text
                self.processAllergensFromCapturedText(cleanedText)
            }
        }

        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["ar", "en"]
        request.usesLanguageCorrection = true
        request.minimumTextHeight = 0.01  // set as needed

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
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

   //  Process detected text, checking for allergen-related keywords
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

    }

    func processAllergensFromCapturedText(_ text: String) {
        let words = text.split(separator: " ").map { $0.trimmingCharacters(in: .punctuationCharacters).lowercased() }
        
        foundAllergens = false  // Reset allergens flag
        
        // Check for allergens in phrases
        let maxPhraseLength = 4
        let N = words.count

        // Look for allergens in the captured text
        for i in 0..<N {
            for L in 1...maxPhraseLength {
                if i + L <= N {
                    let phrase = words[i..<i+L].joined(separator: " ")
                    if checkAllergy(for: phrase) {
                        foundAllergens = true
                        break
                    }
                }
            }
        }

        // If allergens are found, do not display any free allergen message
        if foundAllergens {
            freeAllergenMessage = nil
        } else {
            // If allergens are not found, check for ingredient-related synonyms
            let ingredientSynonyms = [
                "المكونات", "مكونات", "مواد", "عناصر", "المحتويات", "محتويات", "تركيبة",
                "تركيب", "خليط", "تركيبات", "مواد خام", "مكونات الغذاء",
                "مكونات المنتج", "Ingredients", "Contents", "Composition",
                "Components", "Formula", "Constituents", "Mixture", "Blend",
                "Ingredients List", "Product Ingredients", "Food Ingredients",
                "Raw Materials"
            ]
            
            // Check if any of the ingredient-related synonyms exist in the text
            let containsIngredients = ingredientSynonyms.contains(where: { fuzzyContains(text, keyword: $0) })
            
            // Update the allergen-free message based on detection
            if containsIngredients {
                freeAllergenMessage = Locale.current.language.languageCode == "ar" ? "بناءً على الصورة، المنتج خالٍ من المواد المسببة للحساسية." : "Based on the picture, product is Allergen free"
            } else {
                freeAllergenMessage = Locale.current.language.languageCode == "ar" ? "عذرًا، لم يتم العثور على مكونات. حاول مرة أخرى." : "Sorry, no ingredients found. Please try again."
            }
        }
    }

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        cameraManager.capturePhoto { [weak self] (image: UIImage?) in  // Specify the type of 'image'
            if let capturedImage = image {
                // Process the captured image to enhance it
                if let processedImage = self?.cameraManager.processCapturedImageForTextRecognition(capturedImage) {
                    // Use processed image for text recognition
                    self?.startTextRecognition(from: processedImage)
                }
            }
        }
    }


    // Helper for fuzzy matching keywords in text
    func fuzzyContains(_ text: String, keyword: String) -> Bool {
        let pattern = "\\b\(keyword)\\b"
        return text.range(of: pattern, options: [.regularExpression, .caseInsensitive, .diacriticInsensitive]) != nil
    }

    
    func checkAllergy(for phrase: String) -> Bool {
        let cleanedPhrase = phrase.trimmingCharacters(in: .punctuationCharacters).lowercased()

        if let result = isTargetWord(cleanedPhrase) {
            let detectedWord = result.1.lowercased()

            // Match any synonym variations
            let synonyms = result.2.map { $0.lowercased() }
            let allMatchedWords = [detectedWord] + synonyms

                // Check if any variant of the detected word is already in matchedWordsSet
                if !allMatchedWords.contains(where: { matchedWordsSet.contains($0) }),
                   selectedWordsViewModel.selectedWords.contains(detectedWord) {
            
            // Check if any variant of the detected word matches the user's selection
            if selectedWordsViewModel.selectedWords.contains(where: { selectedWord in
                allMatchedWords.contains { $0.compare(selectedWord, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame }
            }) {
                DispatchQueue.main.async {
                    // Proceed with allergen detection logic
                    self.detectedText.append((category: result.0, word: result.1, hiddenSynonyms: result.2))
                    self.hapticManager.performHapticFeedback()
                }
                return true
            }
            }
        }else {
              matchedWordsSet.remove(cleanedPhrase)
            }
        return false
    }

    // Preprocess text to handle OCR errors and normalize content
    func preprocessText(_ text: String) -> String {
        let cleanedText = text
            .replacingOccurrences(of: "\n", with: " ") //// Replace newline characters with spaces
            .replacingOccurrences(of: "-", with: " ") //// Replace hyphens with spaces (common OCR artifact)
            .replacingOccurrences(of: "[^\\p{L}\\p{Z}]", with: " ", options: .regularExpression) //// Remove non-alphabetic characters that might have appeared due to OCR artifacts
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression) //// Reduce multiple spaces to a single space
            .trimmingCharacters(in: .whitespacesAndNewlines) //// Trim any leading or trailing whitespace
            .applyingTransform(.stripCombiningMarks, reverse: false) ?? text //// Remove combining marks (diacritics, etc.)
        //// Replace commas or other punctuation marks that may erroneously appear between words
            .replacingOccurrences(of: ",", with: " ")
        ////Replace Arabic comma (٫) and Arabic full stop (۔) with spaces
           .replacingOccurrences(of: "٫", with: " ")
           .replacingOccurrences(of: "۔", with: " ")
        //// Replace Arabic semicolon (؛) with a space
        .replacingOccurrences(of: "؛", with: " ")
        //// Replace Arabic quotation marks with regular quotation marks (for OCR mistakes)
        .replacingOccurrences(of: "«", with: "\"")
        .replacingOccurrences(of: "»", with: "\"")
        //// Remove Arabic diacritics (marks above/below letters) which may appear due to OCR errors
        .replacingOccurrences(of: "[\\u064B-\\u0652]", with: "", options: .regularExpression)
        //// Remove Arabic tatweel (ـ) used for stretching text and can be misinterpreted by OCR
        .replacingOccurrences(of: "ـ", with: " ")
        //// Normalize Arabic letter forms that may be misinterpreted due to OCR
        .replacingOccurrences(of: "أ", with: "ا")
        .replacingOccurrences(of: "إ", with: "ا")
        .replacingOccurrences(of: "آ", with: "ا")
        .replacingOccurrences(of: "\n", with: " ") // Replace newline characters with spaces
        .replacingOccurrences(of: "-", with: " ") // Replace hyphens with spaces (common OCR artifact)
        .trimmingCharacters(in: .whitespacesAndNewlines) // Trim any leading or trailing whitespace
        .applyingTransform(.stripCombiningMarks, reverse: false) ?? text // Remove combining marks (diacritics)
        .replacingOccurrences(of: "٬", with: ",") // Replace Arabic comma with standard comma
        .replacingOccurrences(of: "؟", with: "?") // Replace Arabic question mark with standard one
        .replacingOccurrences(of: "ـ", with: " ") // Remove Arabic tatweel (used for stretching text)
        .replacingOccurrences(of: "«", with: "\"") // Replace Arabic opening quotation marks
        .replacingOccurrences(of: "»", with: "\"") // Replace Arabic closing quotation marks
        .replacingOccurrences(of: "٠", with: "0") // Replace Arabic numeral zero with standard zero
        .replacingOccurrences(of: "١", with: "1") // Replace Arabic numeral one with standard one
        .replacingOccurrences(of: "٢", with: "2") // Replace Arabic numeral two with standard two
        .replacingOccurrences(of: "٣", with: "3") // Replace Arabic numeral three with standard three
        return cleanedText.lowercased()
    }

    // MARK: - Camera View Helper Functions
    
    // Reset predictions and clear stored matches
    func resetPredictions() {
        detectedText.removeAll()
        matchedWordsSet.removeAll()
        cameraManager.toggleFlash(isOn: false)
    }
    
    // Allow retaking photo and restart camera session
    func retakePhoto() {
        resetState()
        resetPredictions()
        cameraManager.startSession()
        cameraManager.toggleFlash(isOn: false)
    }
}

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
    
    // Haptic feedback generator
    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
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

    // Zoom related properties
          @Published var currentZoom: CGFloat = 1.0  // Bind to UI if needed
    
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
             cameraManager.setFocusPoint(point)
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
    
    // Configure Vision text recognition request with region of interest and error handling
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
        textRequest.minimumTextHeight = 0.01  // Filter out very small text
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
            freeAllergenMessage = Locale.current.language.languageCode == "ar" ? "بناءً على الصورة، المنتج خالٍ من المواد المسببة للحساسية." : "Based on the picture, product is Allergen free"
        } else {
            freeAllergenMessage = Locale.current.language.languageCode == "ar" ? "عذرًا، لم يتم العثور على مكونات. حاول مرة أخرى." : "Sorry, no ingredients found. Please try again."
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
            freeAllergenMessage = Locale.current.language.languageCode == "ar" ? "بناءً على الصورة، المنتج خالٍ من المواد المسببة للحساسية." : "Based on the picture, product is Allergen free"
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
            let detectedWord = result.1.lowercased()
            
            // Use result.2 directly as the synonyms array
            let synonyms = result.2
            let allMatchedWords = [detectedWord] + synonyms.map { $0.lowercased() }
            
            // Check if any variant of the detected word is already in matchedWordsSet
            if !allMatchedWords.contains(where: { matchedWordsSet.contains($0) }),
               selectedWordsViewModel.selectedWords.contains(detectedWord) {
                
                DispatchQueue.main.async {
                    // Append detected item only if it's not already present
                    if !self.detectedText.contains(where: { $0.word == result.1 }) {
                        self.detectedText.append(DetectedTextItem(category: result.0, word: result.1, hiddenSynonyms: result.2))
                        self.hapticManager.performHapticFeedback()
                        
                        // Add main word and its synonyms to matchedWordsSet
                        self.matchedWordsSet.formUnion(allMatchedWords)
                    }
                }
                return true
            }
        } else {
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
        return cleanedText.lowercased()
    }
//    func preprocessText(_ text: String) -> String {
//        let cleanedText = text

//        
//            // Replace newline characters with spaces
//            .replacingOccurrences(of: "\n", with: " ")
//            // Replace hyphens with spaces (common OCR artifact)
//            .replacingOccurrences(of: "-", with: " ")
//            // Replace commas or other punctuation marks that may erroneously appear between words
//            .replacingOccurrences(of: ",", with: " ")
//            // Replace Arabic comma (٫) and Arabic full stop (۔) with spaces
//            .replacingOccurrences(of: "٫", with: " ")
//            .replacingOccurrences(of: "۔", with: " ")
//            // Replace Arabic semicolon (؛) with a space
//            .replacingOccurrences(of: "؛", with: " ")
//            // Replace Arabic quotation marks with regular quotation marks (for OCR mistakes)
//            .replacingOccurrences(of: "«", with: "\"")
//            .replacingOccurrences(of: "»", with: "\"")
//            // Remove Arabic diacritics (marks above/below letters) which may appear due to OCR errors
//            .replacingOccurrences(of: "[\\u064B-\\u0652]", with: "", options: .regularExpression)
//            // Remove Arabic tatweel (ـ) used for stretching text and can be misinterpreted by OCR
//            .replacingOccurrences(of: "ـ", with: " ")
//            // Normalize Arabic letter forms that may be misinterpreted due to OCR
//            .replacingOccurrences(of: "أ", with: "ا")
//            .replacingOccurrences(of: "إ", with: "ا")
//            .replacingOccurrences(of: "آ", with: "ا")
//            .replacingOccurrences(of: "ؤ", with: "و")
//            .replacingOccurrences(of: "ئ", with: "ي")
//            .replacingOccurrences(of: "ج", with: "غ") // Handle possible misrecognition of similar characters
//            // Handle Arabic letters that might be confused with English letters
//            .replacingOccurrences(of: "ل", with: "ل") // Special cases for misrecognized Arabic letters
//            .replacingOccurrences(of: "ع", with: "ع") // Handle OCR-specific errors
//            // Remove non-alphabetic characters that might have appeared due to OCR artifacts
//            .replacingOccurrences(of: "[^\\p{L}\\p{Z}]", with: " ", options: .regularExpression)
//            // Reduce multiple spaces to a single space
//            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
//            // Trim any leading or trailing whitespace
//            .trimmingCharacters(in: .whitespacesAndNewlines)
//            // Remove combining marks (diacritics, etc.)
//            .applyingTransform(.stripCombiningMarks, reverse: false) ?? text
//        return cleanedText.lowercased()
//    }
    
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

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
    var isProcessingCapturedImage = false
    private let ingredientSynonyms = [
        "المكونات", "مكونات", "مواد", "عناصر", "المحتويات", "محتويات", "تركيبة",
        "تركيب", "خليط", "تركيبات", "مواد خام", "مكونات الغذاء",
        "مكونات المنتج", "Ingredients", "Contents", "Composition",
        "Components", "Formula", "Constituents", "Mixture", "Blend",
        "Ingredients List", "Product Ingredients", "Food Ingredients",
        "Raw Materials"
    ]
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

    
    func cameraManager(_ manager: CameraManager, didCapturePhoto image: UIImage?) {
        guard let image = image else { return }
        startTextRecognition(from: image)
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
    
    func configureTextRecognitions(){
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
                if self.isProcessingCapturedImage {
                    // Process detected text from captured image
                    self.processAllergensFromCapturedText(detectedStrings)
                    self.isProcessingCapturedImage = false  // Reset the flag
                } else {
                    // Process detected text from live frames
                    self.processDetectedText(detectedStrings)
                }
            }
        }
                textRequest.recognitionLevel = .accurate
        textRequest.recognitionLanguages = ["ar-SA", "en-US"];
        textRequest.usesLanguageCorrection = true
                textRequest.minimumTextHeight = 0.01
                //textRequest.revision = 1 // Ensures proper handling of different text formats
        textRequest.revision = VNRecognizeTextRequestRevision3
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

        self.isProcessingCapturedImage = true  // Set the flag before processing

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
        
        self.liveDetectedText = cleanedText

        // Detect presence of "ingredient" words
        if ingredientSynonyms.contains(where: { fuzzyContains(cleanedText, keyword: $0) }) {
            hasDetectedIngredients = true
        } else {
            hasDetectedIngredients = false
        }
    }


    func processAllergensFromCapturedText(_ detectedStrings: [String]) {
        let combinedText = detectedStrings.joined(separator: " ")
        let cleanedText = preprocessText(combinedText)
        let words = cleanedText.split(separator: " ").map { $0.trimmingCharacters(in: .punctuationCharacters).lowercased() }

        foundAllergens = false
        detectedText.removeAll()
        matchedWordsSet.removeAll()
        
        // Check if there's no text detected at all
        if cleanedText.isEmpty {
            freeAllergenMessage = Locale.current.language.languageCode == "ar" ?
                "عذرًا، لم يتم العثور على مكونات. حاول مرة أخرى." :
                "Sorry, no ingredients found. Please try again."
            return
        }

        // Use a dictionary to track detected allergens to avoid duplicates
        var uniqueDetectedAllergens: [String: (category: String, word: String, hiddenSynonyms: [String])] = [:]
        let maxPhraseLength = 4

        for i in 0..<words.count {
            for L in 1...maxPhraseLength where i + L <= words.count {
                let phrase = words[i..<i+L].joined(separator: " ")
                if let allergenInfo = checkAllergy(for: phrase), !uniqueDetectedAllergens.keys.contains(allergenInfo.word) {
                    uniqueDetectedAllergens[allergenInfo.word] = allergenInfo
                    foundAllergens = true
                }
            }
        }

        // Check for language mismatch, only if ingredient keywords are detected and no allergens found
        if ingredientSynonyms.contains(where: { fuzzyContains(cleanedText, keyword: $0) }) && !foundAllergens {
            // Only trigger mismatch check if ingredientSynonyms were detected in the text
            if checkLanguageMismatch(for: cleanedText) {
                return
            }
        }

        // Update detectedText with unique allergens if any found
        detectedText = Array(uniqueDetectedAllergens.values)
        
        // Determine the allergen-free message or "no ingredients" message
        if foundAllergens {
            freeAllergenMessage = nil
        } else if ingredientSynonyms.contains(where: { fuzzyContains(cleanedText, keyword: $0) }) {
            freeAllergenMessage = getLocalizedMessage()
        } else {
            // No allergens or ingredient synonyms detected
            freeAllergenMessage = Locale.current.language.languageCode == "ar" ?
                "عذرًا، لم يتم العثور على مكونات. حاول مرة أخرى." :
                "Sorry, no ingredients found. Please try again."
        }
    }

    func checkLanguageMismatch(for text: String) -> Bool {
        let currentLanguageCode = Locale.current.language.languageCode?.identifier ?? ""
        let containsArabic = text.range(of: "\\p{Arabic}", options: .regularExpression) != nil

        // Check if there are ingredient-related terms in the text that are mismatched with the device language
        if ingredientSynonyms.contains(where: { fuzzyContains(text, keyword: $0) }) &&
           ((containsArabic && currentLanguageCode != "ar") || (!containsArabic && currentLanguageCode == "ar")) {
            freeAllergenMessage = containsArabic ?
                "Please change the app language to Arabic for better results." :
                "يرجى تغيير لغة التطبيق إلى الإنجليزية للحصول على نتائج أفضل."
            return true
        }
        return false
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
    func checkAllergy(for phrase: String) -> (category: String, word: String, hiddenSynonyms: [String])? {
        let cleanedPhrase = phrase.trimmingCharacters(in: .punctuationCharacters).lowercased()
        
        if let result = isTargetWord(cleanedPhrase) {
            let detectedWord = result.1.lowercased()
            
            // Match any synonym variations
            let synonyms = result.2.map { $0.lowercased() }
            let allMatchedWords = [detectedWord] + synonyms
            
            // Normalize all words for comparison
            let normalizedMatchedWords = allMatchedWords.map { $0.folding(options: .diacriticInsensitive, locale: Locale(identifier: "ar")).lowercased() }
            
            // Normalize selected words
            let normalizedSelectedWords = selectedWordsViewModel.selectedWords.map { $0.folding(options: .diacriticInsensitive, locale: Locale(identifier: "ar")).lowercased() }
            
            // Check if the detected word matches the user's selected words
            if normalizedSelectedWords.contains(where: { selectedWord in
                normalizedMatchedWords.contains { $0 == selectedWord }
            }) {
                DispatchQueue.main.async {
                    self.hapticManager.performHapticFeedback()
                }
                return (category: result.0, word: result.1, hiddenSynonyms: result.2)
            }
        }
        return nil
    }

    
}
//func processAllergensFromCapturedText(_ detectedStrings: [String]) {
//       let combinedText = detectedStrings.joined(separator: " ")
//       let cleanedText = preprocessText(combinedText)
//       let words = cleanedText.split(separator: " ").map { $0.trimmingCharacters(in: .punctuationCharacters).lowercased() }
//       
//       foundAllergens = false  // Reset allergens flag
//       detectedText.removeAll() // Clear previous detections
//       matchedWordsSet.removeAll()  // Clear previous matched words set
//
//       // Use a dictionary to track detected allergens and avoid duplicates
//       var uniqueDetectedAllergens: [String: (category: String, word: String, hiddenSynonyms: [String])] = [:]
//       
//       // Check for allergens in phrases
//       let maxPhraseLength = 4
//       let N = words.count
//
//       for i in 0..<N {
//           for L in 1...maxPhraseLength {
//               if i + L <= N {
//                   let phrase = words[i..<i+L].joined(separator: " ")
//                   let cleanedPhrase = preprocessText(phrase)
//
//                   if let allergenInfo = checkAllergy(for: phrase), !uniqueDetectedAllergens.keys.contains(allergenInfo.word) {
//                       // Add to dictionary if not already detected
//                       uniqueDetectedAllergens[allergenInfo.word] = allergenInfo
//                       foundAllergens = true
//                   }
//               }
//           }
//       }
//
//       // Check for language mismatch first
//       checkLanguageAndPrompt(detectedText: combinedText)
//       if freeAllergenMessage != nil {
//           // If a language mismatch message is set, skip further processing
//           return
//       }
//
//       // Update detectedText with unique items
//       detectedText = Array(uniqueDetectedAllergens.values)
//       
//       if foundAllergens {
//           freeAllergenMessage = nil
//       } else if ingredientSynonyms.contains(where: { fuzzyContains(cleanedText, keyword: $0) }) {
//           freeAllergenMessage = getLocalizedMessage()
//       } else {
//           freeAllergenMessage = Locale.current.language.languageCode == "ar" ?
//               "عذرًا، لم يتم العثور على مكونات. حاول مرة أخرى." :
//               "Sorry, no ingredients found. Please try again."
//       }
//   }
//
//
//   func checkLanguageAndPrompt(detectedText: String) {
//       let arabicCode = "ar"
//       let englishCode = "en"
//       
//       // Get the current app language code
//       let currentLanguageCode = Locale.current.language.languageCode?.identifier ?? ""
//       
//       // Check if detected text contains predominantly Arabic characters
//       let containsArabic = detectedText.range(of: "\\p{Arabic}", options: .regularExpression) != nil
//       
//       // Determine the mismatch between text language and app language
//       if containsArabic && currentLanguageCode != arabicCode {
//           // Mismatch: Arabic text detected, app is not in Arabic
//           freeAllergenMessage = currentLanguageCode == arabicCode
//               ? "يرجى تغيير لغة التطبيق إلى العربية للحصول على نتائج أفضل."
//               : "Please change the app language to Arabic for better results."
//       } else if !containsArabic && currentLanguageCode != englishCode {
//           // Mismatch: Non-Arabic text detected, app is not in English
//           freeAllergenMessage = currentLanguageCode == arabicCode
//               ? "يرجى تغيير لغة التطبيق إلى الإنجليزية للحصول على نتائج أفضل."
//               : "Please change the app language to English for better results."
//       } else {
//           // No mismatch, clear the message
//           freeAllergenMessage = nil
//       }
//   }

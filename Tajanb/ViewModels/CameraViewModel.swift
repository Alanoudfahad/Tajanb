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
    // Called when a photo is captured, initiates text recognition on the photo
//    func cameraManager(_ manager: CameraManager, didCapturePhoto image: UIImage?) {
//        guard let image = image else { return }
//        startTextRecognition(from: image)
//        
//        // Process text from live preview and detect allergens
//        let detectedTextArray = liveDetectedText.split(separator: " ").map { String($0) }
//        processAllergensFromCapturedText(detectedTextArray)
//    }
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
        textRequest.recognitionLanguages = ["ar-SA", "en-US"];                textRequest.usesLanguageCorrection = true
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
        
        foundAllergens = false  // Reset allergens flag
        detectedText.removeAll() // Remove previous detections
        matchedWordsSet.removeAll()  // Reset matched words set
        
        // Check for allergens in phrases
        let maxPhraseLength = 4
        let N = words.count

        // Look for allergens in the captured text
           for i in 0..<N {
               for L in 1...maxPhraseLength {
                   if i + L <= N {
                       let phrase = words[i..<i+L].joined(separator: " ")

                       // Prevent duplicate phrases from being processed
                       let cleanedPhrase = preprocessText(phrase)

                       // Check if this phrase has already been processed
                       if !matchedWordsSet.contains(cleanedPhrase) {
                           if checkAllergy(for: phrase) {
                               foundAllergens = true
                               matchedWordsSet.insert(cleanedPhrase)  // Mark this phrase as processed
                               break
                           }
                       }
                   }
               }
           }

        if foundAllergens {
            // Allergens found; display them
            freeAllergenMessage = nil
        } else if ingredientSynonyms.contains(where: { fuzzyContains(cleanedText, keyword: $0) }) {
            // No allergens found but ingredients detected
            freeAllergenMessage = getLocalizedMessage()  // Display allergen-free message
        } else {
            // No ingredients found
            freeAllergenMessage = Locale.current.language.languageCode == "ar" ?
                "عذرًا، لم يتم العثور على مكونات. حاول مرة أخرى." :
                "Sorry, no ingredients found. Please try again."
        }
    }
    // Helper for fuzzy matching keywords in text
    func fuzzyContains(_ text: String, keyword: String) -> Bool {
        let pattern = "\\b\(keyword)\\b"
        return text.range(of: pattern, options: [.regularExpression, .caseInsensitive, .diacriticInsensitive]) != nil
    }



    // Get localized allergen-free message
    private func getLocalizedMessage() -> String {
        return Locale.current.language.languageCode  == "ar" ? "بناءً على الصورة، المنتج خالٍ من المواد المسببة للحساسية." : "Based on the picture, product is Allergen free"
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

    func checkAllergy(for phrase: String) -> Bool {
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
                // Proceed with allergen detection logic
                DispatchQueue.main.async {
                    self.detectedText.append((category: result.0, word: result.1, hiddenSynonyms: result.2))
                    self.hapticManager.performHapticFeedback()
                }
                return true
            }
        }
        return false
    }

    func preprocessText(_ text: String) -> String {
        var cleanedText = text
            .replacingOccurrences(of: "\n", with: " ")  // Replace newline characters with spaces
            .replacingOccurrences(of: "-", with: " ")  // Replace hyphens with spaces (common OCR artifact)
            .replacingOccurrences(of: "[^\\p{L}\\p{Z}]", with: " ", options: .regularExpression)  // Remove non-alphabetic characters
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)  // Reduce multiple spaces to a single space
            .trimmingCharacters(in: .whitespacesAndNewlines)  // Trim leading/trailing whitespaces
            .applyingTransform(.stripCombiningMarks, reverse: false) ?? text  // Remove diacritics

            // Normalize Arabic characters with or without dots
            .replacingOccurrences(of: "أ", with: "ا")  // Normalize alif with hamza to alif
            .replacingOccurrences(of: "إ", with: "ا")  // Normalize alif with hamza below to alif
            .replacingOccurrences(of: "آ", with: "ا")  // Normalize alif with madda to alif
            .replacingOccurrences(of: "ء", with: "ا")  // Normalize hamza alone to alif
            .replacingOccurrences(of: "ى", with: "ي")  // Final ya to normal ya
            .replacingOccurrences(of: "ة", with: "ه")  // Replace ta marbuta (final form) with ha
            .replacingOccurrences(of: "و", with: "و")  // No change needed for waw
            .replacingOccurrences(of: "ز", with: "ز")  // No change needed for zay
            .replacingOccurrences(of: "ر", with: "ر")  // No change needed for ra
            .replacingOccurrences(of: "ل", with: "ل")  // No change needed for lam
            .replacingOccurrences(of: "م", with: "م")  // No change needed for meem
            .replacingOccurrences(of: "ن", with: "ن")  // No change needed for noon
            .replacingOccurrences(of: "ه", with: "ه")  // No change needed for heh
            .replacingOccurrences(of: "و", with: "و")  // No change needed for waw

            // Normalize letters with dots (1, 2, 3 dots)
            .replacingOccurrences(of: "ب", with: "ب")  // Beh (1 dot below)
            .replacingOccurrences(of: "ت", with: "ت")  // Teh (2 dots above)
            .replacingOccurrences(of: "ث", with: "ث")  // Theh (3 dots above)
            .replacingOccurrences(of: "ج", with: "ج")  // Jeem (1 dot below)
            .replacingOccurrences(of: "ح", with: "ح")  // Hhaa (no dots)
            .replacingOccurrences(of: "خ", with: "خ")  // Khaa (1 dot above)
            .replacingOccurrences(of: "د", with: "د")  // Dal (no dots)
            .replacingOccurrences(of: "ذ", with: "ذ")  // Dhal (1 dot above)
            .replacingOccurrences(of: "ش", with: "ش")  // Sheen (3 dots above)
            .replacingOccurrences(of: "ص", with: "ص")  // Saad (no dots)
            .replacingOccurrences(of: "ض", with: "ض")  // Daad (1 dot above)
            .replacingOccurrences(of: "ط", with: "ط")  // Taa (no dots)
            .replacingOccurrences(of: "ظ", with: "ظ")  // Thaa (1 dot above)
            .replacingOccurrences(of: "ع", with: "ع")  // Ain (no dots)
            .replacingOccurrences(of: "غ", with: "غ")  // Ghain (1 dot above)
            .replacingOccurrences(of: "ف", with: "ف")  // Feh (1 dot above)
            .replacingOccurrences(of: "ق", with: "ق")  // Qaf (1 dot above)
            .replacingOccurrences(of: "ك", with: "ك")  // Kaf (no dots)
            .replacingOccurrences(of: "ي", with: "ي")  // Yeh (1 dot below)

            // Handle other common punctuation issues
            .replacingOccurrences(of: "٫", with: " ") // Arabic comma
            .replacingOccurrences(of: "۔", with: " ") // Arabic full stop
            .replacingOccurrences(of: "٬", with: ",") // Arabic comma to standard comma
            .replacingOccurrences(of: "؟", with: "?") // Arabic question mark
            .replacingOccurrences(of: "ـ", with: " ") // Remove tatweel (used for stretching text)

            // Normalize numbers and special characters
            .replacingOccurrences(of: "٠", with: "0")
            .replacingOccurrences(of: "١", with: "1")
            .replacingOccurrences(of: "٢", with: "2")
            .replacingOccurrences(of: "٣", with: "3")
        
        return cleanedText.lowercased()  // Convert to lowercase for consistency
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

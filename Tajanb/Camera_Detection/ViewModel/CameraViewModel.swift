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

class CameraViewModel: NSObject, ObservableObject {

    @Published var detectedText: [(category: String, word: String, hiddenSynonyms: [String])] = []
    @Published var availableCategories = [Category]()
    @Published var freeAllergenMessage: String? // New variable to display the message
    private var hapticManager = HapticManager() // Haptic feedback manager.
    @Published var selectedWords = [String]() {
        didSet {
            saveSelectedWords()
        }
    }
    @Published var cameraPermissionGranted: Bool = false // Track permission state
    //private var session: AVCaptureSession!
    private var textRequest = VNRecognizeTextRequest(completionHandler: nil)
    private var frameCount = 0
    private let frameSkipCount = 3 // Process every 3rd frame
    
    private var session: AVCaptureSession!
    
    override init() {
        super.init()
        loadCategories()
        loadSelectedWords()
        configureCaptureSession()
        configureTextRecognition()
        
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
    private func saveSelectedWords() {
        UserDefaults.standard.set(selectedWords, forKey: "selectedWords")
    }
    
    func updateSelectedWords(with words: [String]) {
        selectedWords = words
        UserDefaults.standard.set(words, forKey: "selectedWords")
        print("Selected words updated: \(selectedWords)")
    }
       
       func loadSelectedWords() {
           // Load words from UserDefaults when the app starts
           if let savedWords = UserDefaults.standard.array(forKey: "selectedWords") as? [String] {
               selectedWords = savedWords
           }
       }

     func isTargetWord(_ text: String) -> (String, String, [String])? {
        for category in availableCategories {
            for word in category.words {
                if word.word.caseInsensitiveCompare(text) == .orderedSame ||
                   word.hiddenSynonyms?.contains(where: { $0.caseInsensitiveCompare(text) == .orderedSame }) == true {
                    let synonyms = word.hiddenSynonyms ?? []
                    return (category.name, word.word, synonyms)  // Return category, word, and synonyms
                }
            }
        }
        return nil
    }

    private func configureCaptureSession() {
        session = AVCaptureSession()
        session.sessionPreset = .high
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }

        session.addInput(videoInput)
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "cameraQueue"))
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        session.addOutput(videoOutput)
        
        // Set focus mode to continuous
        do {
            try videoDevice.lockForConfiguration()
            if videoDevice.isFocusModeSupported(.continuousAutoFocus) {
                videoDevice.focusMode = .continuousAutoFocus
            }
            videoDevice.unlockForConfiguration()
        } catch {
            print("Error configuring focus: \(error)")
        }
    }
    
    private func configureTextRecognition() {
        textRequest = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }

            if let error = error {
                print("Error recognizing text: \(error)")
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                return
            }

            let detectedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
            DispatchQueue.main.async {
                self.processDetectedText(detectedStrings)
            }
        }

        textRequest.recognitionLevel = .accurate  // Switch to .fast for performance improvement
        textRequest.recognitionLanguages = ["ar", "en"] // Arabic and English
        textRequest.usesLanguageCorrection = true
        textRequest.minimumTextHeight = 0.005
    }


    func processDetectedText(_ detectedStrings: [String]) {
        let combinedText = detectedStrings.joined(separator: " ")
        let cleanedText = preprocessText(combinedText)
        print("Detected Combined Text: \(cleanedText)")
        
        // Determine the keyword to use based on the device's language
        let isArabic = Locale.current.language.languageCode == "ar"
        let keyword = isArabic ? "المكونات" : "ingredients"
        
        // Only detect text in the specified language
        if fuzzyContains(cleanedText, keyword: keyword) {
            // When the keyword is detected, process ingredients accordingly
            let ingredientsDetected = extractAndProcessIngredients(from: cleanedText, keyword: keyword)
            freeAllergenMessage = ingredientsDetected.isEmpty ? getLocalizedMessage() : nil
        } else {
            // Reset the message if the keyword is not in the text
            freeAllergenMessage = nil
        }
    }

    private func extractAndProcessIngredients(from text: String, keyword: String) -> [String] {
        if let range = text.range(of: keyword)?.upperBound {
            let ingredientsText = String(text[range...]).trimmingCharacters(in: .whitespaces)
            let ingredients = ingredientsText
                .components(separatedBy: CharacterSet(charactersIn: ",، "))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            let filteredIngredients = ingredients.filter { ingredient in
                isSelectedWord(ingredient)
            }
            updateDetectedIngredients(filteredIngredients)
            return filteredIngredients
        }
        print("Failed to extract ingredients.")
        detectedText = []
        return []
    }

    
    private func getLocalizedMessage() -> String {
        return Locale.current.language.languageCode == "ar" ? "خالي من مسببات الحساسيه" : "Free allergens"
    }
    private func isSelectedWord(_ ingredient: String) -> Bool {
        // Check if the ingredient matches any selected word (case-insensitive)
        if selectedWords.contains(where: { $0.caseInsensitiveCompare(ingredient) == .orderedSame }) {
            return true
        }

        // Check if the ingredient matches any synonym of the selected words
        for category in availableCategories {
            for word in category.words {
                if selectedWords.contains(where: { $0.caseInsensitiveCompare(word.word) == .orderedSame }) {
                    if word.word.caseInsensitiveCompare(ingredient) == .orderedSame ||
                       word.hiddenSynonyms?.contains(where: { $0.caseInsensitiveCompare(ingredient) == .orderedSame }) == true {
                        return true
                    }
                }
            }
        }

        return false
    }


    func preprocessText(_ text: String) -> String {
        var cleanedText = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: ",", with: ", ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        cleanedText = cleanedText.replacingOccurrences(of: "االمكونات", with: "المكونات")
        return cleanedText.applyingTransform(.stripCombiningMarks, reverse: false) ?? cleanedText
    }

    func fuzzyContains(_ text: String, keyword: String) -> Bool {
        let pattern = "\\b\(keyword)\\b"
        return text.range(of: pattern, options: [.regularExpression, .caseInsensitive, .diacriticInsensitive]) != nil
    }
    // Example Levenshtein Distance implementation for fuzzy matching
    func levenshtein(_ aStr: String, _ bStr: String) -> Int {
        let a = Array(aStr)
        let b = Array(bStr)
        var dist = [[Int]]()
        for i in 0...a.count { dist.append([i]) }
        for j in 1...b.count { dist[0].append(j) }
        for i in 1...a.count {
            for j in 1...b.count {
                if a[i - 1] == b[j - 1] {
                    dist[i].append(dist[i - 1][j - 1])
                } else {
                    dist[i].append(min(dist[i - 1][j - 1], dist[i][j - 1], dist[i - 1][j]) + 1)
                }
            }
        }
        return dist[a.count][b.count]
    }



    private func updateDetectedIngredients(_ ingredients: [String]) {
        let targetWords = ingredients.compactMap { ingredient -> (String, String, [String])? in
            // Reset the free allergen message if ingredients are detected
            if !ingredients.isEmpty {
                freeAllergenMessage = nil
            }
            if let (category, word, hiddenSynonyms) = isTargetWord(ingredient.lowercased()) {
                let detectedSynonyms = hiddenSynonyms.filter { selectedWords.contains($0.lowercased()) }
                return (category, word, detectedSynonyms)
            }
            return nil
        }

        if !detectedText.elementsEqual(targetWords, by: { $0 == $1 }) {
            detectedText = targetWords
            print("Updated Detected Ingredients: \(detectedText)")

            if !targetWords.isEmpty {
                hapticManager.performHapticFeedback()
            }
        }
    }
    
    func startSession() {
          DispatchQueue.global(qos: .userInitiated).async {
              self.session.startRunning()
          }
      }
      
      func stopSession() {
          session.stopRunning()
      }
      
      func getSession() -> AVCaptureSession {
          return session
      }
    func updateDetectedWords() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Extract the relevant information: category, word, and matched hidden synonyms.
            let targetWords = self.detectedText.compactMap { item -> (String, String, [String])? in
                if let (category, word, hiddenSynonyms) = self.isTargetWord(item.word) {
                    // Filter only the detected synonyms (those matching the scanned text).
                    let detectedSynonyms = hiddenSynonyms.filter { self.selectedWords.contains($0.lowercased()) }
                    return (category, word, detectedSynonyms)
                }
                return nil
            }

            // Update the detected text only if there are changes.
            if !self.detectedText.elementsEqual(targetWords, by: { $0.0 == $1.0 && $0.1 == $1.1 }) {
                self.detectedText = targetWords
                print("Updated Detected Words: \(self.detectedText)")
            }
        }
    }

    

}

extension CameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try requestHandler.perform([textRequest])
        } catch {
            print("Failed to perform text recognition request: \(error)")
        }
    }
}

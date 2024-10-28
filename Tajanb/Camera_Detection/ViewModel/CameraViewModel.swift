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

class CameraViewModel: NSObject, ObservableObject {

    @Published var detectedText: [(category: String, word: String, hiddenSynonyms: [String])] = []
    @Published var availableCategories = [Category]()
    @Published var freeAllergenMessage: String?
    private var hapticManager = HapticManager()
//    @Published var selectedWords = [String]() {
//        didSet {
//            saveSelectedWords()
//        }
//    }
    @Published var selectedWords = [String]()

    @Published var cameraPermissionGranted: Bool = false
    private var textRequest = VNRecognizeTextRequest(completionHandler: nil)
    private var session: AVCaptureSession!

    override init() {
        super.init()
        loadCategories()
       // loadSelectedWords()
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
        session = AVCaptureSession()
        session.sessionPreset = .high
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
        
        session.addInput(videoInput)
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "cameraQueue"))
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        session.addOutput(videoOutput)
        
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

        textRequest.recognitionLevel = .accurate
        textRequest.recognitionLanguages = ["ar", "en"]
        textRequest.usesLanguageCorrection = true
        textRequest.minimumTextHeight = 0.005
    }

    func processDetectedText(_ detectedStrings: [String]) {
        let combinedText = detectedStrings.joined(separator: " ")
        let cleanedText = preprocessText(combinedText)
        print("Detected Combined Text: \(cleanedText)")
        
        let keyword = Locale.current.language.languageCode == "ar" ? "المكونات" : "ingredients"
        
        if fuzzyContains(cleanedText, keyword: keyword) {
            let ingredientsDetected = extractAndProcessIngredients(from: cleanedText, keyword: keyword)
            freeAllergenMessage = ingredientsDetected.isEmpty ? getLocalizedMessage() : nil
        } else {
            freeAllergenMessage = nil
        }
    }

    private func extractAndProcessIngredients(from text: String, keyword: String) -> [String] {
        if let range = text.range(of: keyword, options: [.caseInsensitive])?.upperBound {
            let ingredientsText = String(text[range...]).trimmingCharacters(in: .whitespaces)
            let ingredients = ingredientsText
                .components(separatedBy: CharacterSet(charactersIn: ",، "))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            let filteredIngredients = ingredients.filter { isSelectedWord($0) }
            updateDetectedIngredients(filteredIngredients)
            return filteredIngredients
        }
        print("Failed to extract ingredients.")
        detectedText = []
        return []
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

    private func isSelectedWord(_ ingredient: String) -> Bool {
        let lowercasedIngredient = ingredient.lowercased()
        return selectedWords.contains(where: { $0.lowercased() == lowercasedIngredient }) ||
               availableCategories.flatMap { $0.words }
                   .contains { word in
                       word.word.lowercased() == lowercasedIngredient ||
                       word.hiddenSynonyms?.contains { $0.lowercased() == lowercasedIngredient } == true
                   }
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

    private func getLocalizedMessage() -> String {
        return Locale.current.language.languageCode == "ar" ? "خالي من مسببات الحساسيه" : "Free allergens"
    }

    private func updateDetectedIngredients(_ ingredients: [String]) {
        let targetWords = ingredients.compactMap { ingredient -> (String, String, [String])? in
            if let (category, word, hiddenSynonyms) = isTargetWord(ingredient) {
                return (category, word, hiddenSynonyms)
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
//
//    private func saveSelectedWords() {
//        UserDefaults.standard.set(selectedWords, forKey: "selectedWords")
//    }
//
//    func updateSelectedWords(with words: [String]) {
//        selectedWords = words
//        UserDefaults.standard.set(words, forKey: "selectedWords")
//        print("Selected words updated: \(selectedWords)")
//    }
//
//    func loadSelectedWords() {
//        if let savedWords = UserDefaults.standard.array(forKey: "selectedWords") as? [String] {
//            selectedWords = savedWords
//        }
//    }

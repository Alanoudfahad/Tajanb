//
//  PhotoViewModel.swift
//  Tajanb
//
//  Created by Alanoud Alshuaibi on 19/04/1446 AH.
//

import Foundation
import Vision
import UIKit
import Photos

class PhotoViewModel: NSObject, ObservableObject {
    @Published var detectedText: [(category: String, word: String, hiddenSynonyms: [String])] = []
    @Published var freeAllergenMessage: String? // Updated to manage the message state
    private var textRequest = VNRecognizeTextRequest(completionHandler: nil)
    private var hapticManager = HapticManager()
    var ViewModel: CameraViewModel
    private var matchedWordsSet: Set<String> = [] // To keep track of matched words

    init(viewmodel: CameraViewModel) {
        self.ViewModel = viewmodel
        super.init()
        configureTextRecognition()
    }

    private func configureTextRecognition() {
        textRequest = VNRecognizeTextRequest { [weak self] (request, error) in
            guard let self = self else { return }

            if let error = error {
                print("Error recognizing text: \(error.localizedDescription)")
                return
            }

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

    private func processDetectedText(_ detectedStrings: [String]) {
        let combinedText = detectedStrings.joined(separator: " ")
        let cleanedText = ViewModel.preprocessText(combinedText)

        print("Detected Combined Text: \(cleanedText)")

        // Split the cleaned text into words
        let words = cleanedText.split(separator: " ").map { $0.trimmingCharacters(in: .punctuationCharacters).lowercased() }
        print("Detected Words List: \(words)")

        var foundAllergens = false

        let maxPhraseLength = 4 // Adjust this based on the maximum length of phrases you expect
        let N = words.count

        // Iterate over words and check for phrases
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

        // Check for "المكونات" if no allergens were found
        if !foundAllergens {
            if fuzzyContains(cleanedText, keyword: "المكونات") {
                // No allergens but "المكونات" found
                freeAllergenMessage = getLocalizedMessage() // Display "Free from allergens" message
            } else {
                // "المكونات" not found, show an error message
                freeAllergenMessage = Locale.current.language.languageCode == "ar" ? "خطأ: لم يتم العثور على المكونات" : "Error: Ingredients not found"
            }
        } else {
            // Reset the free allergen message if allergens are found
            freeAllergenMessage = nil
        }
    }
    
    func fuzzyContains(_ text: String, keyword: String) -> Bool {
        // Build a pattern that allows the keyword to be surrounded by non-letter characters or spaces
        let pattern = "\\b\(keyword)\\b"
        
        // Search for the keyword using case insensitivity and diacritic insensitivity
        let result = text.range(of: pattern, options: [.regularExpression, .caseInsensitive, .diacriticInsensitive]) != nil
        print("Fuzzy match for keyword '\(keyword)': \(result)")  // Log the result
        return result
    }
    
    private func checkAllergy(for phrase: String) -> Bool {
        let cleanedPhrase = phrase.trimmingCharacters(in: .punctuationCharacters).lowercased()
        
        if let result = ViewModel.isTargetWord(cleanedPhrase) {
            // Check if this phrase has already been detected to avoid duplicates
            if !matchedWordsSet.contains(cleanedPhrase) {
                // Check if the detected phrase matches a selected allergen
                if ViewModel.selectedWords.contains(result.1) {
                    DispatchQueue.main.async {
                        self.detectedText.append((category: result.0, word: result.1, hiddenSynonyms: result.2))
                        
                        // Perform haptic feedback only if the detected phrase matches a selected allergen
                        self.hapticManager.performHapticFeedback()
                        
                        self.matchedWordsSet.insert(cleanedPhrase)
                    }
                    return true // Allergen found
                }
            }
        } else {
            // Remove the phrase from the matched set if no longer matching
            matchedWordsSet.remove(cleanedPhrase)
        }
        return false // No allergen found for this phrase
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

    // Request access to photo library
    func requestPhotoLibraryAccess() {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("Photo library access granted.")
                case .denied, .restricted:
                    print("Photo library access denied or restricted.")
                case .notDetermined:
                    print("Photo library access not determined.")
                case .limited:
                    print("Photo library access granted with limitations.")
                @unknown default:
                    print("Unknown photo library access status.")
                }
            }
        }
    }
}

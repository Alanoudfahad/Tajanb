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

// ViewModel for handling photo-based text recognition and allergen detection
class PhotoViewModel: NSObject, ObservableObject {
    @Published var detectedText: [(category: String, word: String, hiddenSynonyms: [String])] = []  // Holds detected allergens with categories and synonyms
    @Published var freeAllergenMessage: String?  // Message indicating allergen-free status or error
    private var textRequest = VNRecognizeTextRequest(completionHandler: nil)  // Text recognition request
    private var hapticManager = HapticManager()  // Manages haptic feedback on allergen detection
    var ViewModel: CameraViewModel  // Reference to CameraViewModel
    private var matchedWordsSet: Set<String> = []  // Tracks words already detected to avoid duplicates

    // List of ingredient-related keywords to detect, in multiple languages
    private let ingredientKeywords = [
        "المكونات", "مكونات", "مواد", "عناصر", "المحتويات", "محتويات", "تركيبة",
        "تركيب", "خليط", "تركيبات", "مواد خام", "مكونات الغذاء",
        "مكونات المنتج", "Ingredients", "Contents", "Composition",
        "Components", "Formula", "Constituents", "Mixture", "Blend",
        "Ingredients List", "Product Ingredients", "Food Ingredients",
        "Raw Materials"
    ]
    
    // Initialize with CameraViewModel reference and configure text recognition
    init(viewmodel: CameraViewModel) {
        self.ViewModel = viewmodel
        super.init()
        configureTextRecognition()
    }

    // Set up the text recognition request with completion handler and language options
    private func configureTextRecognition() {
        textRequest = VNRecognizeTextRequest { [weak self] (request, error) in
            guard let self = self else { return }

            if let error = error {
                print("Error recognizing text: \(error.localizedDescription)")
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

        // Configure recognition settings
        textRequest.recognitionLevel = .accurate
        textRequest.recognitionLanguages = ["ar", "en"]
        textRequest.usesLanguageCorrection = true
    }

    // Start text recognition on a captured image
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

    // Process detected text, checking for allergens or ingredient-related keywords
    private func processDetectedText(_ detectedStrings: [String]) {
        let combinedText = detectedStrings.joined(separator: " ")
        let cleanedText = ViewModel.preprocessText(combinedText)  // Preprocess text for consistency

        print("Detected Combined Text: \(cleanedText)")

        // Split combined text into words and clean each
        let words = cleanedText.split(separator: " ").map { $0.trimmingCharacters(in: .punctuationCharacters).lowercased() }
        print("Detected Words List: \(words)")

        var foundAllergens = false
        let maxPhraseLength = 4  // Maximum phrase length to check for allergens
        let N = words.count

        // Check each phrase in the detected words for allergen-related matches
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

        // If no allergens found, check for ingredient keywords and set appropriate message
        if !foundAllergens {
            if ingredientKeywords.contains(where: { fuzzyContains(cleanedText, keyword: $0) }) {
                freeAllergenMessage = getLocalizedMessage()  // Display allergen-free message
            } else {
                // Display error if no ingredient-related keywords found
                freeAllergenMessage = Locale.current.language.languageCode == "ar" ? "عذرًا، لم يتم العثور على مكونات. حاول مرة أخرى." : "Sorry, no ingredients found. Please try again."
            }
        } else {
            freeAllergenMessage = nil  // Clear message if allergens found
        }
    }

    // Fuzzy search to check if the keyword is present in the text
    func fuzzyContains(_ text: String, keyword: String) -> Bool {
        // Define pattern to match keyword as a standalone word
        let pattern = "\\b\(keyword)\\b"
        let result = text.range(of: pattern, options: [.regularExpression, .caseInsensitive, .diacriticInsensitive]) != nil
        print("Fuzzy match for keyword '\(keyword)': \(result)")
        return result
    }

    // Check if a detected phrase matches any allergen and update state if found
    private func checkAllergy(for phrase: String) -> Bool {
        let cleanedPhrase = phrase.trimmingCharacters(in: .punctuationCharacters).lowercased()

        if let result = ViewModel.isTargetWord(cleanedPhrase) {
            if !matchedWordsSet.contains(cleanedPhrase) {
                // If the word matches a selected allergen, add to detected list and provide haptic feedback
                if ViewModel.selectedWordsViewModel.selectedWords.contains(result.1) {
                    DispatchQueue.main.async {
                        self.detectedText.append((category: result.0, word: result.1, hiddenSynonyms: result.2))
                        self.hapticManager.performHapticFeedback()  // Provide feedback
                        self.matchedWordsSet.insert(cleanedPhrase)  // Track detected phrase
                    }
                    return true  // Allergen found
                }
            }
        } else {
            matchedWordsSet.remove(cleanedPhrase)  // Remove if not matching
        }
        return false  // No allergen found
    }

    // Get localized message for allergen-free status
    private func getLocalizedMessage() -> String {
        return Locale.current.language.languageCode == "ar" ? "خالي من مسببات الحساسية" : "Allergen-free"
    }

    // Reset detected text and clear matched words
    func resetPredictions() {
        detectedText.removeAll()  // Clear detected allergen list
        matchedWordsSet.removeAll()  // Clear matched words
        freeAllergenMessage = getLocalizedMessage()  // Reset to allergen-free message
    }

    // Request access to the photo library
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

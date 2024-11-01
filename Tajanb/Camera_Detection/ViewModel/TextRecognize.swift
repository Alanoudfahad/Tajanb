//
//  TextRecognize.swift
//  Tajanb
//
//  Created by Afrah Saleh on 29/04/1446 AH.
//

import SwiftData
import UIKit
import AVFoundation
import Vision

extension CameraViewModel {
    
    // Save the user-selected words to the model context
    func saveSelectedWords(using modelContext: ModelContext) {
        let fetchDescriptor = FetchDescriptor<SelectedWord>()
        
        // Delete existing selected words from the model context
        if let existingWords = try? modelContext.fetch(fetchDescriptor) {
            for word in existingWords {
                modelContext.delete(word)
            }
        }
        
        // Insert the new selected words
        for word in selectedWords {
            let newWord = SelectedWord(word: word)
            modelContext.insert(newWord)
        }
        
        // Save changes to the model context
        try? modelContext.save()
    }

    // Load saved words from the model context into selectedWords array
    func loadSelectedWords(using modelContext: ModelContext) {
        let fetchDescriptor = FetchDescriptor<SelectedWord>()
        
        // Fetch and map saved words; if unavailable, reset to an empty array
        if let savedWordsData = try? modelContext.fetch(fetchDescriptor) {
            selectedWords = savedWordsData.map { $0.word }
        } else {
            selectedWords = []
        }
    }

    // Update selected words with a new list and save them to the model context
    func updateSelectedWords(with words: [String], using modelContext: ModelContext) {
        selectedWords = words
        saveSelectedWords(using: modelContext)
        print("Selected words updated: \(selectedWords)")
    }

    // Configure Vision request to recognize text and filter based on Region of Interest (ROI)
    func configureTextRecognitions() {
        textRequest = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }
            
            // Handle recognition errors
            if let error = error {
                print("Error recognizing text: \(error)")
                return
            }

            // Process recognized text observations that intersect with the ROI
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            let filteredObservations = observations.filter { observation in
                let transformedBoundingBox = self.transformBoundingBox(observation.boundingBox)
                let intersects = self.regionOfInterest.intersects(transformedBoundingBox)
                print("Bounding Box: \(transformedBoundingBox), Intersects ROI: \(intersects)")  // Debugging
                return intersects
            }

            let detectedStrings = filteredObservations.compactMap { $0.topCandidates(1).first?.string }
            print("Detected Strings: \(detectedStrings)")  // Debugging output
            
            // Process detected text on the main thread
            DispatchQueue.main.async {
                self.processDetectedText(detectedStrings)
            }
        }

        textRequest.recognitionLevel = .accurate
        textRequest.recognitionLanguages = ["ar", "en"]
        textRequest.usesLanguageCorrection = true
        textRequest.minimumTextHeight = 0.02  // Filter out small/noisy text
    }

    // Start text recognition from a provided image
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

    // Reset the state of detected text and flags
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

    // Process detected strings and check for specific keywords
    func processDetectedText(_ detectedStrings: [String]) {
        let combinedText = detectedStrings.joined(separator: " ")
        let cleanedText = preprocessText(combinedText)

        print("Detected Combined Text (Live): \(cleanedText)")  // Debugging
        
        self.liveDetectedText = cleanedText

        // Check for "المكونات" to detect ingredients
        if fuzzyContains(cleanedText, keyword: "المكونات") {
            hasDetectedIngredients = true
        } else {
            hasDetectedIngredients = false
        }

        // Update allergen message based on detection results
        if foundAllergens {
            freeAllergenMessage = nil
            hasDetectedIngredients = true
        } else {
            if fuzzyContains(cleanedText, keyword: "المكونات") {
                freeAllergenMessage = getLocalizedMessage()
                hasDetectedIngredients = true
            } else {
                freeAllergenMessage = Locale.current.language.languageCode == "ar" ? "خطأ: لم يتم العثور على المكونات" : "Error: Ingredients not found"
                hasDetectedIngredients = false
            }
        }

        print("hasDetectedIngredients: \(hasDetectedIngredients), freeAllergenMessage: \(freeAllergenMessage ?? "No Message")")
    }
    
    // Process allergens in detected text and update state accordingly
    func processAllergensFromCapturedText(_ detectedStrings: [String]) {
        let combinedText = detectedStrings.joined(separator: " ")
        let cleanedText = preprocessText(combinedText)
        
        print("Detected Combined Text: \(cleanedText)")
        let words = cleanedText.split(separator: " ").map { $0.trimmingCharacters(in: .punctuationCharacters).lowercased() }
        
        foundAllergens = false  // Reset allergens flag
        
        // Check each word for allergens
        for word in words {
            if checkAllergy(for: word) {
                foundAllergens = true
            }
        }
        
        // Update allergen-free message if no allergens found
        if foundAllergens {
            freeAllergenMessage = nil
        } else {
            freeAllergenMessage = Locale.current.language.languageCode == "ar" ? "خالي من مسببات الحساسية" : "Allergen-free"
        }
        
        print("Free Allergen Message: \(freeAllergenMessage ?? "No Message"), foundAllergens: \(foundAllergens)")
    }
    
    // Perform a fuzzy search for a keyword in the text
    func fuzzyContains(_ text: String, keyword: String) -> Bool {
        let pattern = "\\b\(keyword)\\b"
        let result = text.range(of: pattern, options: [.regularExpression, .caseInsensitive, .diacriticInsensitive]) != nil
        print("Fuzzy match for keyword '\(keyword)': \(result)")
        return result
    }

    // Check if the word matches any selected allergen
    private func checkAllergy(for word: String) -> Bool {
        let cleanedWord = word.trimmingCharacters(in: .punctuationCharacters).lowercased()
        
        if let result = isTargetWord(cleanedWord) {
            if !matchedWordsSet.contains(cleanedWord) {
                if selectedWords.contains(result.1) {
                    DispatchQueue.main.async {
                        self.detectedText.append((category: result.0, word: result.1, hiddenSynonyms: result.2))
                        self.hapticManager.performHapticFeedback()
                        self.matchedWordsSet.insert(cleanedWord)
                    }
                    return true
                }
            }
        } else {
            matchedWordsSet.remove(cleanedWord)
        }
        return false
    }

    // Get localized message for allergen-free status
    private func getLocalizedMessage() -> String {
        return Locale.current.language.languageCode == "ar" ? "خالي من مسببات الحساسية" : "Allergen-free"
    }

    // Reset predictions and clear stored matches
    func resetPredictions() {
        detectedText.removeAll()
        matchedWordsSet.removeAll()
        freeAllergenMessage = getLocalizedMessage()
    }

    // Check if text matches a target word in any category
    func isTargetWord(_ text: String) -> (String, String, [String])? {
        let lowercasedText = text.lowercased()
        for category in availableCategories {
            for word in category.words {
                if word.word.lowercased() == lowercasedText ||
                    word.hiddenSynonyms?.contains(where: { $0.lowercased() == lowercasedText }) == true {
                    return (category.name, word.word, word.hiddenSynonyms ?? [])
                }
            }
        }
        return nil
    }

    // Check if a word is user-selected allergen
    private func isSelectedWord(_ word: String) -> Bool {
        let isMatch = selectedWords.contains { selectedWord in
            return word.compare(selectedWord, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
        print("Ingredient '\(word)' is a selected word: \(isMatch)")
        return isMatch
    }

    // Preprocess text by removing unwanted characters and normalizing spaces
    func preprocessText(_ text: String) -> String {
        var cleanedText = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "[^\\p{L}\\p{Z}]", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Fix OCR errors like repeated characters in Arabic
        cleanedText = cleanedText.replacingOccurrences(of: "االمكونات", with: "المكونات")
        
        return cleanedText.applyingTransform(.stripCombiningMarks, reverse: false) ?? cleanedText
    }
}

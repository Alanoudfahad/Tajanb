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
    
    // MARK: - Swift Data functions

    // Save the selected words to UserDefaults
       func saveSelectedWords() {
           UserDefaults.standard.set(selectedWords, forKey: userDefaultsKey)
           print("Words successfully saved to UserDefaults: \(selectedWords)")
       }

    func loadSelectedWords() {
        if let savedWords = UserDefaults.standard.array(forKey: userDefaultsKey) as? [String] {
            selectedWords = savedWords.map { word in
                // Translate word to current device language
                if Locale.current.languageCode == "ar" {
                    // Find the Arabic version if saved in English
                    return wordMappings.first(where: { $0.value.english == word })?.value.arabic ?? word
                } else {
                    // Find the English version if saved in Arabic
                    return wordMappings.first(where: { $0.value.arabic == word })?.value.english ?? word
                }
            }
        }
    }
       // Update selected words and save them to UserDefaults
       func updateSelectedWords(with words: [String]) {
           selectedWords = words
           saveSelectedWords()
           print("Selected words updated: \(selectedWords)")
       }

    //Save all words
       func saveSelectedWords(for selectedCategories: Set<String>) {
           var wordsToSave: [String] = []
           
           // Collect words from selected categories
           for category in availableCategories where selectedCategories.contains(category.name) {
               for word in category.words {
                   wordsToSave.append(word.word)
                   wordsToSave.append(contentsOf: word.hiddenSynonyms)
               }
           }
           
           updateSelectedWords(with: wordsToSave)
           print("Words saved: \(wordsToSave)")
       }
    //Toggle Word Selection
    func toggleSelection(for word: String, language: String, isSelected: Bool) {
        // Find the word’s ID and mapping in the wordMappings dictionary
        let wordId = wordMappings.first { language == "ar" ? $0.value.arabic == word : $0.value.english == word }?.key
        
        // Make sure the ID exists and has corresponding entries in both languages
        guard let id = wordId, let mapping = wordMappings[id] else { return }
        
        if isSelected {
            // Add the selected word and its counterpart
            if !selectedWords.contains(word) {
                selectedWords.append(word)
            }
            
            let correspondingWord = language == "ar" ? mapping.english : mapping.arabic
            if !selectedWords.contains(correspondingWord) {
                selectedWords.append(correspondingWord)
            }
        } else {
            // Remove the selected word and its counterpart
            selectedWords.removeAll { $0 == word }
            let correspondingWord = language == "ar" ? mapping.english : mapping.arabic
            selectedWords.removeAll { $0 == correspondingWord }
        }

        saveSelectedWords() // Save updated selections
    }
//       func toggleSelection(for word: String, isSelected: Bool) {
//           if isSelected {
//               if !selectedWords.contains(word) {
//                   selectedWords.append(word)
//               }
//           } else {
//               selectedWords.removeAll { $0 == word }
//
//           }
//           saveSelectedWords() // Save to UserDefaults whenever selection changes
//       }
    
    
    // MARK: - Text recognition Functions
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

    // Check if text matches a target word in any category
    func isTargetWord(_ text: String) -> (String, String, [String])? {
        let lowercasedText = text.lowercased()
        for category in availableCategories {
            for word in category.words {
                if word.word.lowercased() == lowercasedText ||
                    word.hiddenSynonyms.contains(where: { $0.lowercased() == lowercasedText }) == true {
                    return (category.name, word.word, word.hiddenSynonyms)
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

        // Define and use expanded synonyms for "ingredients"
        let ingredientSynonyms = [
            "المكونات", "مكونات", "مواد", "عناصر", "محتويات", "تركيبة",
            "تركيب", "خليط", "تركيبات", "مواد خام", "مكونات الغذاء",
            "مكونات المنتج", "Ingredients", "Contents", "Composition",
            "Components", "Formula", "Constituents", "Mixture", "Blend",
            "Ingredients List", "Product Ingredients", "Food Ingredients",
            "Raw Materials"
        ]

        // Check if any synonym for "ingredients" is present
        if ingredientSynonyms.contains(where: { fuzzyContains(cleanedText, keyword: $0) }) {
            hasDetectedIngredients = true
        } else {
            hasDetectedIngredients = false
        }

        // Update allergen message based on detection results
        if foundAllergens {
            freeAllergenMessage = nil
            hasDetectedIngredients = true
        } else {
            if hasDetectedIngredients {
                freeAllergenMessage = getLocalizedMessage()
            } else {
                freeAllergenMessage = Locale.current.language.languageCode == "ar" ? "خطأ: لم يتم العثور على المكونات" : "Error: Ingredients not found"
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



    func preprocessText(_ text: String) -> String {
        var cleanedText = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "[^\\p{L}\\p{Z}]", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Common OCR error corrections in Arabic and English
        let ocrCorrections: [String: String] = [
            // Arabic OCR corrections
            "االمكونات": "المكونات",
            "تتكوين": "تكوين",
            "الترريبه": "التركيبة",
            "الممحتويات": "المحتويات",
            "منتتج": "منتج",
            
            // English OCR corrections
            "Ingrediants": "Ingredients", // Common OCR misspelling
            "Composion": "Composition",
            "Ingrdients": "Ingredients",
            "Contnts": "Contents"
            
            // Add additional corrections as needed
        ]

        for (incorrect, correct) in ocrCorrections {
            cleanedText = cleanedText.replacingOccurrences(of: incorrect, with: correct)
        }

        // Normalize Arabic diacritics and other combining marks for both languages
        cleanedText = cleanedText.applyingTransform(.stripCombiningMarks, reverse: false) ?? cleanedText
        
        // Lowercase for English words to handle case inconsistencies
        cleanedText = cleanedText.lowercased()
        
        return cleanedText
    }
}

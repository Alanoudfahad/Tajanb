//
//  SelectedWordsViewModel.swift
//  Tajanb
//
//  Created by Afrah Saleh on 04/05/1446 AH.
//

import Foundation
import SwiftData
import Combine

// ViewModel for managing selected allergen words, including saving to and loading from UserDefaults
class SelectedWordsViewModel: ObservableObject {
    @Published var selectedWords: [String] = []  // List of selected allergen words
    @Published var isSelectAllEnabled: Bool = false  // Tracks "Select All" state for UI

    private let firestoreViewModel: FirestoreViewModel  // Reference to Firestore for word mappings
    var modelContext: ModelContext?  // SwiftData context to interact with database

    init(firestoreViewModel: FirestoreViewModel) {
        self.firestoreViewModel = firestoreViewModel
        loadSelectedWords()
    }

    
    // MARK: - Load Selected Words from SwiftData
       func loadSelectedWords() {
           guard let modelContext = modelContext else { return }
           
           let fetchDescriptor = FetchDescriptor<SelectedWord>()
           if let fetchedWords = try? modelContext.fetch(fetchDescriptor) {
               selectedWords = fetchedWords.map { $0.word }
               print("Loaded selected words from SwiftData: \(selectedWords)")
           }
       }

    
       // MARK: - Save Selected Words to SwiftData
       func saveSelectedWords() {
           guard let modelContext = modelContext else { return }
           
           // Clear existing selected words in the database
           let fetchDescriptor = FetchDescriptor<SelectedWord>()
           if let fetchedWords = try? modelContext.fetch(fetchDescriptor) {
               fetchedWords.forEach { modelContext.delete($0) }
           }
           
           // Save each word in selectedWords to SwiftData
           for word in selectedWords {
               let newSelectedWord = SelectedWord(word: word, category: "General") // Adjust category as needed
               modelContext.insert(newSelectedWord)
           }
           
           try? modelContext.save()
           print("Selected words saved to SwiftData: \(selectedWords)")
       }

    
       // MARK: - Update Selected Words with SwiftData
       func updateSelectedWords(with words: [String]) {
           selectedWords = words
           saveSelectedWords()
           print("Selected words updated: \(selectedWords)")
       }

    
       // MARK: - Save Words for Specific Categories

    func saveSelectedWords(for selectedCategories: Set<String>) {
        var wordsToSave: [String] = []

        // Add words and their synonyms from each selected category
        for category in firestoreViewModel.availableCategories where selectedCategories.contains(category.name) {
            for word in category.words {
                // Fetch the Arabic and English words using the wordMappings
                if let wordPair = firestoreViewModel.wordMappings[word.id] {
                    wordsToSave.append(wordPair.arabic)
                    wordsToSave.append(wordPair.english)
                } else {
                    // Fallback to the word data if mapping is not available
                    wordsToSave.append(word.word)
                    wordsToSave.append(contentsOf: word.hiddenSynonyms)
                }
            }
        }

        updateSelectedWords(with: wordsToSave)
        print("Words saved: \(wordsToSave)")
    }
    
       // MARK: - Toggle and Selection Management
    func handleSelectAllToggleChange(for category: Category, isSelected: Bool) {
        // Retrieve all words and their hidden synonyms in the category
        let allWords = category.words.flatMap { [$0.word] + $0.hiddenSynonyms }

        // Retrieve both Arabic and English versions for each word, defaulting to an empty array if no mapping is found
        let allWordsWithTranslations = allWords.flatMap { word -> [String] in
            if let wordMapping = firestoreViewModel.wordMappings.first(where: { $0.value.arabic == word || $0.value.english == word }) {
                return [wordMapping.value.arabic, wordMapping.value.english]
            }
            return []
        }

        if isSelected {
            // Append only words not already selected to avoid duplicates
            selectedWords.append(contentsOf: allWordsWithTranslations.filter { !selectedWords.contains($0) })
        } else {
            // Remove all related translations
            selectedWords.removeAll { allWordsWithTranslations.contains($0) }
        }

        saveSelectedWords()  // Persist updated selection to SwiftData
        updateSelectAllStatus(for: category)
    }

    func toggleSelection(for category: Category, word: String, isSelected: Bool) {
           // Check if word exists in `wordMappings` to fetch both languages
           guard let wordMapping = firestoreViewModel.wordMappings.first(where: { $0.value.arabic == word || $0.value.english == word }) else { return }

           // Update selection for both language variants
           let arabicWord = wordMapping.value.arabic
           let englishWord = wordMapping.value.english
           
           if isSelected {
               if !selectedWords.contains(arabicWord) { selectedWords.append(arabicWord) }
               if !selectedWords.contains(englishWord) { selectedWords.append(englishWord) }
           } else {
               selectedWords.removeAll { $0 == arabicWord || $0 == englishWord }
           }

           saveSelectedWords()
           updateSelectAllStatus(for: category)
       }
    

    func updateSelectAllStatus(for category: Category) {
        // Retrieve all primary words in the category
        let allWords = category.words.map { $0.word }

        // Retrieve both Arabic and English versions for each word, defaulting to an empty array if no mapping is found
        let allWordsWithTranslations = allWords.flatMap { word -> [String] in
            if let wordMapping = firestoreViewModel.wordMappings.first(where: { $0.value.arabic == word || $0.value.english == word }) {
                return [wordMapping.value.arabic, wordMapping.value.english]
            }
            return []
        }

        // Check if all translated words are in selectedWords
        if selectedWords.isEmpty {
            isSelectAllEnabled = false
        } else if allWordsWithTranslations.allSatisfy({ selectedWords.contains($0) }) {
            isSelectAllEnabled = true
        } else {
            isSelectAllEnabled = false
        }
    }
   }
// Extension to check if a collection contains all elements from another array
extension Collection where Element: Equatable {
    func containsAll(_ elements: [Element]) -> Bool {
        return elements.allSatisfy { self.contains($0) }
    }
}

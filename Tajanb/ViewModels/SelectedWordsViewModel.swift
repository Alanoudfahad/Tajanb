//
//  SelectedWordsViewModel.swift
//  Tajanb
//
//  Created by Afrah Saleh on 04/05/1446 AH.
//

import Foundation
import Combine

// ViewModel for managing selected allergen words, including saving to and loading from UserDefaults
class SelectedWordsViewModel: ObservableObject {
    @Published var selectedWords: [String] = []  // List of selected allergen words
    @Published var isSelectAllEnabled: Bool = false  // Tracks "Select All" state for UI

    private let userDefaultsKey = "selectedWords"  // Key to store words in UserDefaults
    private let firestoreViewModel: FirestoreViewModel  // Reference to Firestore for word mappings

    // Initialize with FirestoreViewModel and load any previously selected words
    init(firestoreViewModel: FirestoreViewModel) {
        self.firestoreViewModel = firestoreViewModel
        loadSelectedWords()
    }

    // Save the currently selected words to UserDefaults for persistent storage
    func saveSelectedWords() {
        UserDefaults.standard.set(selectedWords, forKey: userDefaultsKey)
        print("Words successfully saved to UserDefaults: \(selectedWords)")
    }

    // Load selected words from UserDefaults, translating them based on the device's current language
    func loadSelectedWords() {
        if let savedWords = UserDefaults.standard.array(forKey: userDefaultsKey) as? [String] {
            selectedWords = savedWords.map { word in
                // Translate each word to the current device language
                if Locale.current.languageCode == "ar" {
                    // Convert English word to Arabic if saved in English
                    return self.firestoreViewModel.wordMappings.first(where: { $0.value.english == word })?.value.arabic ?? word
                } else {
                    // Convert Arabic word to English if saved in Arabic
                    return self.firestoreViewModel.wordMappings.first(where: { $0.value.arabic == word })?.value.english ?? word
                }
            }
        }
    }

    // Update the list of selected words and save to UserDefaults
    func updateSelectedWords(with words: [String]) {
        selectedWords = words
        saveSelectedWords()
        print("Selected words updated: \(selectedWords)")
    }

    // Save words from specific categories as selected, including hidden synonyms
    func saveSelectedWords(for selectedCategories: Set<String>) {
        var wordsToSave: [String] = []

        // Add words and their synonyms from each selected category
        for category in firestoreViewModel.availableCategories where selectedCategories.contains(category.name) {
            for word in category.words {
                wordsToSave.append(word.word)
                wordsToSave.append(contentsOf: word.hiddenSynonyms)
            }
        }

        updateSelectedWords(with: wordsToSave)
        print("Words saved: \(wordsToSave)")
    }

    
    // MARK: - Functions Toggles in WordListView

    // Handle "Select All" toggle for a specific category
    func handleSelectAllToggleChange(for category: Category, isSelected: Bool) {
        let allWords = category.words.flatMap { [$0.word] + $0.hiddenSynonyms }

        if isSelected {
            // Add all words in the category to selectedWords if not already selected
            selectedWords.append(contentsOf: allWords.filter { !selectedWords.contains($0) })
        } else {
            // Remove all words in the category from selectedWords
            selectedWords.removeAll { allWords.contains($0) }
        }

        saveSelectedWords()  // Save updated selectedWords to UserDefaults
        updateSelectAllStatus(for: category)  // Update the "Select All" status
    }

    // Toggle selection for a single word within a category
    func toggleSelection(for category: Category, word: String, isSelected: Bool) {
        guard let categoryWord = category.words.first(where: { $0.word == word }) else { return }

        if isSelected {
            // Add word and its synonyms if not already selected
            if !selectedWords.contains(word) {
                selectedWords.append(word)
                selectedWords.append(contentsOf: categoryWord.hiddenSynonyms)
            }
        } else {
            // Remove the word and its synonyms from selectedWords
            selectedWords.removeAll { $0 == word || categoryWord.hiddenSynonyms.contains($0) }
            isSelectAllEnabled = false  // Disable "Select All" if deselecting an item
        }

        saveSelectedWords()  // Save updated selectedWords to UserDefaults
        updateSelectAllStatus(for: category)  // Update "Select All" status for the category
    }

    // Update the "Select All" status based on the selection of individual words in the category
    func updateSelectAllStatus(for category: Category) {
        let allWords = category.words.map { $0.word }

        // Enable "Select All" only if all words in the category are selected
        if selectedWords.isEmpty {
            isSelectAllEnabled = false
        } else if selectedWords.containsAll(allWords) {
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

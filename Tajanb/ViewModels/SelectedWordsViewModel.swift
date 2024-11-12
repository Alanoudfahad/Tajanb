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

    private let userDefaultsKey = "selectedWords"  // Key to store words in UserDefaults
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
                   wordsToSave.append(word.word)
                   wordsToSave.append(contentsOf: word.hiddenSynonyms)
               }
           }

           updateSelectedWords(with: wordsToSave)
           print("Words saved: \(wordsToSave)")
       }

    
       // MARK: - Toggle and Selection Management

       func handleSelectAllToggleChange(for category: Category, isSelected: Bool) {
           let allWords = category.words.flatMap { [$0.word] + $0.hiddenSynonyms }

           if isSelected {
               selectedWords.append(contentsOf: allWords.filter { !selectedWords.contains($0) })
           } else {
               selectedWords.removeAll { allWords.contains($0) }
           }

           saveSelectedWords()  // Persist updated selection to SwiftData
           updateSelectAllStatus(for: category)
       }

    
       func toggleSelection(for category: Category, word: String, isSelected: Bool) {
           guard let categoryWord = category.words.first(where: { $0.word == word }) else { return }

           if isSelected {
               if !selectedWords.contains(word) {
                   selectedWords.append(word)
                   selectedWords.append(contentsOf: categoryWord.hiddenSynonyms)
               }
           } else {
               selectedWords.removeAll { $0 == word || categoryWord.hiddenSynonyms.contains($0) }
               isSelectAllEnabled = false
           }

           saveSelectedWords()
           updateSelectAllStatus(for: category)
       }

       func updateSelectAllStatus(for category: Category) {
           let allWords = category.words.map { $0.word }

           if selectedWords.isEmpty {
               isSelectAllEnabled = false
           } else if allWords.allSatisfy({ selectedWords.contains($0) }) {
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

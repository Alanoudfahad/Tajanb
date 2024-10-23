////
////  CategoryManagerViewModel.swift
////  Tajanb
////
////  Created by Afrah Saleh on 17/04/1446 AH.
////
//
//import Foundation
//// handle category management, selected words, and ingredient detection.
//class CategoryManagerViewModel: ObservableObject {
//
//    @Published var availableCategories = [Category]()
//    @Published var selectedWords = [String]() {
//        didSet {
//            saveSelectedWords()
//        }
//    }
//
//    init() {
//        loadCategories()
//        loadSelectedWords()
//    }
//
//    private func loadCategories() {
//        guard let path = Bundle.main.path(forResource: "TargetWords", ofType: "json") else {
//            print("Error finding TargetWords.json")
//            return
//        }
//        
//        do {
//            let data = try Data(contentsOf: URL(fileURLWithPath: path))
//            let decoder = JSONDecoder()
//            availableCategories = try decoder.decode([Category].self, from: data)
//            print("Loaded Categories: \(availableCategories)")
//        } catch {
//            print("Error loading categories from JSON: \(error)")
//        }
//    }
//    // New method to load default categories from JSON when no user defaults are available
//       func loadDefaultCategoriesFromJson() {
//           guard let path = Bundle.main.path(forResource: "DefaultTargetWords", ofType: "json") else {
//               print("Error finding DefaultTargetWords.json")
//               return
//           }
//
//           do {
//               let data = try Data(contentsOf: URL(fileURLWithPath: path))
//               let decoder = JSONDecoder()
//               let defaultCategories = try decoder.decode([Category].self, from: data)
//               availableCategories = defaultCategories
//               print("Loaded Default Categories: \(availableCategories)")
//           } catch {
//               print("Error loading default categories from JSON: \(error)")
//           }
//       }
//
//    private func saveSelectedWords() {
//        UserDefaults.standard.set(selectedWords, forKey: "selectedWords")
//    }
//
//    private func loadSelectedWords() {
//        if let words = UserDefaults.standard.array(forKey: "selectedWords") as? [String] {
//            selectedWords = words
//        }
//    }
//
//    func updateSelectedWords(with words: [String]) {
//        selectedWords = words.map { $0.lowercased() }
//    }
//
//    func isTargetWord(_ text: String) -> (String, String, [String])? {
//        for category in availableCategories {
//            for word in category.words {
//                if word.word.caseInsensitiveCompare(text) == .orderedSame ||
//                   word.hiddenSynonyms?.contains(where: { $0.caseInsensitiveCompare(text) == .orderedSame }) == true {
//                    let synonyms = word.hiddenSynonyms ?? []
//                    return (category.name, word.word, synonyms)
//                }
//            }
//        }
//        return nil
//    }
//
//    func isSelectedWord(_ ingredient: String) -> Bool {
//        if selectedWords.contains(where: { $0.caseInsensitiveCompare(ingredient) == .orderedSame }) {
//            return true
//        }
//
//        for category in availableCategories {
//            for word in category.words {
//                if selectedWords.contains(where: { $0.caseInsensitiveCompare(word.word) == .orderedSame }) {
//                    if word.word.caseInsensitiveCompare(ingredient) == .orderedSame ||
//                       word.hiddenSynonyms?.contains(where: { $0.caseInsensitiveCompare(ingredient) == .orderedSame }) == true {
//                        return true
//                    }
//                }
//            }
//        }
//
//        return false
//    }
//
//    func preprocessText(_ text: String) -> String {
//        var cleanedText = text
//            .replacingOccurrences(of: "\n", with: " ")
//            .replacingOccurrences(of: "-", with: " ")
//            .replacingOccurrences(of: ",", with: ", ")
//            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
//            .trimmingCharacters(in: .whitespacesAndNewlines)
//
//        cleanedText = cleanedText.replacingOccurrences(of: "االمكونات", with: "المكونات")
//        cleanedText = cleanedText.replacingOccurrences(of: "المحتويات", with: "المكونات")
//        return cleanedText.applyingTransform(.stripCombiningMarks, reverse: false) ?? cleanedText
//    }
//
//    func fuzzyContains(_ text: String, keyword: String) -> Bool {
//        let pattern = "\\b\(keyword)\\b"
//        return text.range(of: pattern, options: [.regularExpression, .caseInsensitive, .diacriticInsensitive]) != nil
//    }
//
//    func splitIngredients(from text: String) -> [String] {
//        return text.components(separatedBy: CharacterSet(charactersIn: ",، "))
//            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
//            .filter { !$0.isEmpty }
//    }
//}

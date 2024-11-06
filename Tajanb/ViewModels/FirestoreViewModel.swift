//
//  FirestoreViewModel.swift
//  Tajanb
//
//  Created by Afrah Saleh on 04/05/1446 AH.
//

import Foundation
import FirebaseFirestore
import Combine

// ViewModel for handling Firestore operations related to categories, words, and suggestions
class FirestoreViewModel: ObservableObject {
    @Published var wordMappings: [String: (arabic: String, english: String)] = [:]  // Dictionary for word translations
    @Published var availableCategories = [Category]()  // List of categories available in Firestore

    
    // MARK: - Fetch categories and associated words from Firestore

    // Fetch mappings of words in Arabic and English from Firestore
    func fetchWordMappings(completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        let dispatchGroup = DispatchGroup()  // Group for managing asynchronous tasks

        // Fetch Arabic words from Firestore collection
        dispatchGroup.enter()
        db.collection("categories_arabic").getDocuments { [weak self] snapshot, error in
            guard let self = self else { dispatchGroup.leave(); return }
            guard let documents = snapshot?.documents, error == nil else { dispatchGroup.leave(); return }

            for document in documents {
                let data = document.data()
                if let words = data["words"] as? [[String: Any]] {
                    for wordData in words {
                        if let id = wordData["id"] as? String,
                           let word = wordData["word"] as? String {
                            // Store Arabic word, preserving any existing English translation
                            self.wordMappings[id] = (arabic: word, english: self.wordMappings[id]?.english ?? "")
                        }
                    }
                }
            }
            dispatchGroup.leave()  // Signal completion of Arabic words fetching
        }

        // Fetch English words from Firestore collection
        dispatchGroup.enter()
        db.collection("categories_english").getDocuments { [weak self] snapshot, error in
            guard let self = self else { dispatchGroup.leave(); return }
            guard let documents = snapshot?.documents, error == nil else { dispatchGroup.leave(); return }

            for document in documents {
                let data = document.data()
                if let words = data["words"] as? [[String: Any]] {
                    for wordData in words {
                        if let id = wordData["id"] as? String,
                           let word = wordData["word"] as? String {
                            // Store English word, preserving any existing Arabic translation
                            self.wordMappings[id] = (arabic: self.wordMappings[id]?.arabic ?? "", english: word)
                        }
                    }
                }
            }
            dispatchGroup.leave()  // Signal completion of English words fetching
        }

        // Notify completion when all asynchronous fetches are finished
        dispatchGroup.notify(queue: .main) {
            completion()
        }
    }

    // Fetch categories and their words, based on the device language, from Firestore
    func fetchCategories(completion: @escaping () -> Void) {
        let db = Firestore.firestore()

        // Determine language code (e.g., "en" for English, "ar" for Arabic)
        let deviceLanguageCode = Locale.preferredLanguages.first?.prefix(2) ?? "en"
        let collectionName = deviceLanguageCode == "ar" ? "categories_arabic" : "categories_english"

        db.collection(collectionName).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching categories: \(error)")
                completion()
                return
            }

            guard let documents = snapshot?.documents else {
                print("No categories found")
                completion()
                return
            }

            // Decode documents into Category objects and update available categories
            self.availableCategories = documents.compactMap { document in
                try? document.data(as: Category.self)
            }
            completion()
        }
    }

    // MARK: - Upload .json categories and words to Firestore

    // Upload categories and their associated words from JSON files to Firestore
    func uploadJSONToFirestore() {
        // Load JSON files for English and Arabic categories from the app bundle
        guard let englishFileURL = Bundle.main.url(forResource: "categories_en", withExtension: "json"),
              let arabicFileURL = Bundle.main.url(forResource: "categories_ar", withExtension: "json"),
              let englishData = try? Data(contentsOf: englishFileURL),
              let arabicData = try? Data(contentsOf: arabicFileURL) else {
            print("Failed to load JSON files")
            return
        }

        do {
            // Decode JSON data into Category objects
            let englishCategories = try JSONDecoder().decode([Category].self, from: englishData)
            let arabicCategories = try JSONDecoder().decode([Category].self, from: arabicData)

            let db = Firestore.firestore()

            // Upload each category to Firestore under respective collections
            for category in englishCategories {
                let documentRef = db.collection("categories_english").document(category.name)
                documentRef.setData(category.toDictionary())
            }

            for category in arabicCategories {
                let documentRef = db.collection("categories_arabic").document(category.name)
                documentRef.setData(category.toDictionary())
            }

            print("Data uploaded successfully")
        } catch {
            print("Error decoding JSON: \(error)")
        }
    }

    // Save user suggestions to Firestore
    func saveSuggestion(_ suggestionText: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()
        db.collection("User_Suggestions").addDocument(data: [
            "suggestion": suggestionText,
            "timestamp": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}

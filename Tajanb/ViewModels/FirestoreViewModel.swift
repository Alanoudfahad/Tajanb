
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
    private let lastFetchedKey = "lastFetchedDate"
    
    
    
    
    // MARK: - Fetch word mappings with daily refresh check
      func fetchWordMappings(completion: @escaping () -> Void) {
          let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
          let lastFetched = UserDefaults.standard.object(forKey: lastFetchedKey) as? Date ?? .distantPast

          if lastFetched < oneDayAgo {
              print("Data is stale. Fetching word mappings from server...")
              fetchFromServer(completion: completion)
          } else {
              print("Using cached data for word mappings. Last fetched: \(lastFetched)")
              fetchFromCacheOrServer(completion: completion)
          }
      }
      
      // Fetch from server if data is stale or on first launch
      private func fetchFromServer(completion: @escaping () -> Void) {
          let dispatchGroup = DispatchGroup()
          let db = Firestore.firestore()
          // Fetch Arabic words from server
          dispatchGroup.enter()
          db.collection("categories_arabic").getDocuments { [weak self] snapshot, error in
              guard let self = self else { dispatchGroup.leave(); return }
              guard let documents = snapshot?.documents, error == nil else {
                  print("Error fetching Arabic words: \(error?.localizedDescription ?? "No error info")")
                  dispatchGroup.leave()
                  return
              }
              self.processWordDocuments(documents, isArabic: true)
              dispatchGroup.leave()
          }

          // Fetch English words from server
          dispatchGroup.enter()
          db.collection("categories_english").getDocuments { [weak self] snapshot, error in
              guard let self = self else { dispatchGroup.leave(); return }
              guard let documents = snapshot?.documents, error == nil else {
                  print("Error fetching English words: \(error?.localizedDescription ?? "No error info")")
                  dispatchGroup.leave()
                  return
              }
              self.processWordDocuments(documents, isArabic: false)
              dispatchGroup.leave()
          }

          dispatchGroup.notify(queue: .main) {
              UserDefaults.standard.set(Date(), forKey: self.lastFetchedKey)  // Update the last fetch timestamp
              print("Data fetched from server and cache updated.")
              completion()
          }
      }
      
      // Fetch data from cache and fall back to server if cache is unavailable
      private func fetchFromCacheOrServer(completion: @escaping () -> Void) {
          let dispatchGroup = DispatchGroup()
          let db = Firestore.firestore()
          dispatchGroup.enter()
          db.collection("categories_arabic").getDocuments(source: .cache) { [weak self] snapshot, error in
              if let error = error {
                  print("Cache fetch failed for Arabic words: \(error.localizedDescription). Fetching from server...")
                  self?.fetchFromServer(completion: completion)
                  return
              }
              
              // Process cached documents if available
              if let documents = snapshot?.documents {
                  self?.processWordDocuments(documents, isArabic: true)
              }
              dispatchGroup.leave()
          }
          
          dispatchGroup.enter()
          db.collection("categories_english").getDocuments(source: .cache) { [weak self] snapshot, error in
              if let error = error {
                  print("Cache fetch failed for English words: \(error.localizedDescription). Fetching from server...")
                  self?.fetchFromServer(completion: completion)
                  return
              }
              
              // Process cached documents if available
              if let documents = snapshot?.documents {
                  self?.processWordDocuments(documents, isArabic: false)
              }
              dispatchGroup.leave()
          }

          dispatchGroup.notify(queue: .main) {
              print("Data fetched from cache.")
              completion()
          }
      }
      
      // Helper to process documents for both Arabic and English categories
    private func processWordDocuments(_ documents: [QueryDocumentSnapshot], isArabic: Bool) {
        for document in documents {
            let data = document.data()
            if let words = data["words"] as? [[String: Any]] {
                for wordData in words {
                    if let id = wordData["id"] as? String, let word = wordData["word"] as? String {
                        if isArabic {
                            // Add/Update Arabic word and ensure the English word is also fetched
                            self.wordMappings[id] = (arabic: word, english: self.wordMappings[id]?.english ?? "")
                        } else {
                            // Add/Update English word and ensure the Arabic word is also fetched
                            self.wordMappings[id] = (arabic: self.wordMappings[id]?.arabic ?? "", english: word)
                        }
                    }
                }
            }
        }
        print(isArabic ? "Processed Arabic words." : "Processed English words.")
    }

      // MARK: - Fetch categories with daily refresh check
      func fetchCategories(completion: @escaping () -> Void) {
          let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
          let lastFetched = UserDefaults.standard.object(forKey: lastFetchedKey) as? Date ?? .distantPast

          if lastFetched < oneDayAgo {
              print("Data is stale. Fetching categories from server...")
              fetchCategoriesFromServer(completion: completion)
          } else {
              print("Using cached data for categories. Last fetched: \(lastFetched)")
              fetchCategoriesFromCacheOrServer(completion: completion)
          }
      }

      private func fetchCategoriesFromServer(completion: @escaping () -> Void) {
          let db = Firestore.firestore()
          let languageCode = Locale.preferredLanguages.first?.prefix(2) ?? "en"
          let collectionName = (languageCode == "ar") ? "categories_arabic" : "categories_english"

          db.collection(collectionName).getDocuments { [weak self] snapshot, error in
              guard let self = self else { return }
              if let error = error {
                  print("Error fetching categories from server: \(error)")
                  completion()
                  return
              }

              self.availableCategories = snapshot?.documents.compactMap { document in
                  try? document.data(as: Category.self)
              } ?? []
              UserDefaults.standard.set(Date(), forKey: self.lastFetchedKey)
              print("Categories fetched from server and cache updated.")
              completion()
          }
      }

      private func fetchCategoriesFromCacheOrServer(completion: @escaping () -> Void) {
          let db = Firestore.firestore()
          let languageCode = Locale.preferredLanguages.first?.prefix(2) ?? "en"
          let collectionName = (languageCode == "ar") ? "categories_arabic" : "categories_english"

          db.collection(collectionName).getDocuments(source: .cache) { [weak self] snapshot, error in
              if let error = error {
                  print("Cache fetch for categories failed: \(error.localizedDescription). Fetching from server...")
                  self?.fetchCategoriesFromServer(completion: completion)
                  return
              }

              self?.availableCategories = snapshot?.documents.compactMap { document in
                  try? document.data(as: Category.self)
              } ?? []
              print("Categories fetched from cache.")
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

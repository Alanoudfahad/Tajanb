//
//  Word.swift
//  Tajanb
//
//  Created by Afrah Saleh on 09/05/1446 AH.
//
import Foundation

struct Word: Codable {
    var id: String // Unique identifier for each word to match across languages
    var word: String
    var hiddenSynonyms: [String]

    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "word": word,
            "hiddenSynonyms": hiddenSynonyms
        ]
    }
}
struct SearchableWord: Identifiable {
    var id: String
    var wordText: String
    var category: Category
}

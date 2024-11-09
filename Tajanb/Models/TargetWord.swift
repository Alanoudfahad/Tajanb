//
//  TargetWord.swift
//  Tajanb
//
//  Created by Afrah Saleh on 17/04/1446 AH.
//

import Foundation

class SelectedWord: Identifiable {
    var word: String
    var category: String

    init(word: String, category: String) {
        self.word = word
        self.category = category
    }
}
struct Category: Codable {
    var name: String
    var icon: String // Property for the emoji
    var words: [Word]

    func toDictionary() -> [String: Any] {
        let wordsDict = words.map { $0.toDictionary() }
        return [
            "name": name,
            "icon": icon,
            "words": wordsDict
        ]
    }
}

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
// In CameraViewModel
struct DetectedTextItem: Identifiable , Hashable{
    let id = UUID()
    let category: String
    let word: String
    let hiddenSynonyms: [String]
}





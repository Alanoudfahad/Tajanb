//
//  TargetWord.swift
//  Tajanb
//
//  Created by Afrah Saleh on 17/04/1446 AH.
//

import Foundation
import SwiftData

@Model
class SelectedWord: Identifiable {
    var id: UUID = UUID() // Unique identifier
    var word: String      // The selected word

    init(word: String) {
        self.word = word
    }
}

struct Category: Decodable {
    let name: String
    let words: [Word]
}

struct Word: Decodable {
    let word: String
    let hiddenSynonyms: [String]?
}

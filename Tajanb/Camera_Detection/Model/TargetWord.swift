//
//  TargetWord.swift
//  Tajanb
//
//  Created by Afrah Saleh on 17/04/1446 AH.
//

import Foundation
import SwiftData

@Model
class TargetWord: Identifiable {
    var id: UUID = UUID()
    var word: String

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

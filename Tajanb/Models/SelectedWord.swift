//
//  SelectedWord.swift
//  Tajanb
//
//  Created by Afrah Saleh on 09/05/1446 AH.
//

import Foundation
import SwiftData

@Model
class SelectedWord {
    @Attribute(.unique) var word: String
    var category: String

    init(word: String, category: String) {
        self.word = word
        self.category = category
    }
}

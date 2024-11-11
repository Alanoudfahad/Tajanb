//
//  Category.swift
//  Tajanb
//
//  Created by Afrah Saleh on 09/05/1446 AH.
//
import Foundation

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

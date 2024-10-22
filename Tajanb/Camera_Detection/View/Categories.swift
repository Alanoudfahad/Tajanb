//
//  Categories.swift
//  Tajanb
//
//  Created by Afrah Saleh on 17/04/1446 AH.
//

import SwiftUI

struct Categories: View {
    @ObservedObject var viewModel: CategoryManagerViewModel

    var body: some View {
        VStack {
            List(viewModel.availableCategories, id: \.name) { category in
                Section(header: Text(category.name).font(.headline)) {
                    ForEach(category.words, id: \.word) { word in
                        Button(action: {
                            toggleSelection(for: word.word)
                        }) {
                            HStack {
                                Text(word.word)
                                Spacer()
                                if viewModel.selectedWords.contains(word.word) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
            
        }
    }

    private func toggleSelection(for word: String) {
        if let selectedWord = viewModel.availableCategories
            .flatMap({ $0.words })
            .first(where: { $0.word == word }) {
            
            if viewModel.selectedWords.contains(selectedWord.word) {
                // Remove word and its synonyms if unselected
                viewModel.selectedWords.removeAll { $0 == selectedWord.word || selectedWord.hiddenSynonyms?.contains($0) == true }
            } else {
                // Add word and its hidden synonyms if selected
                viewModel.selectedWords.append(selectedWord.word)
                if let synonyms = selectedWord.hiddenSynonyms {
                    viewModel.selectedWords.append(contentsOf: synonyms)
                }
            }
        }
        print("Selected Words: \(viewModel.selectedWords)")
    }
}


#Preview {
    Categories(viewModel: CategoryManagerViewModel())
}


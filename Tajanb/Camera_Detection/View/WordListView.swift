//
//  WordListView.swift
//  Tajanb
//
//  Created by Afrah Saleh on 20/04/1446 AH.
//

import SwiftUI

struct WordListView: View {
    let category: Category
    @ObservedObject var viewModel: CameraViewModel
    
    var body: some View {
        VStack {
            List {
                ForEach(category.words, id: \.word) { word in
                    HStack {
                        Toggle(word.word, isOn: Binding(
                            get: { viewModel.selectedWords.contains(word.word) },
                            set: { isSelected in
                                toggleSelection(for: word.word, isSelected: isSelected)
                            }
                        ))
                    }
                }
            }
        }
        .navigationTitle(category.name)
    }

    private func toggleSelection(for word: String, isSelected: Bool) {
        if isSelected {
            if !viewModel.selectedWords.contains(word) {
                viewModel.selectedWords.append(word)
            }
        } else {
            viewModel.selectedWords.removeAll { $0 == word }
        }
    }
}

#Preview {
    WordListView(category: .init(name: "Category", words: []), viewModel: CameraViewModel())
}

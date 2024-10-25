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
    @Environment(\.dismiss) var dismiss // For navigation back
    
    var body: some View {
            VStack {
                VStack(spacing: 0) {
                    Text("تم")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.bottom)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 25)
                        .padding(.leading, 25)
                        .onTapGesture {
                            dismiss() // Save selected words and navigate back
                        }
                    
                    Divider()
                        .background(Color.white)
                }
                
                Text(category.name)
                    .foregroundColor(.white)
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.bottom, 15)
                    .padding(.trailing, 25)
                
                List {
                    ForEach(category.words, id: \.word) { word in
                        HStack {
                            Toggle("", isOn: Binding(
                                get: { viewModel.selectedWords.contains(word.word) },
                                set: { isSelected in
                                    toggleSelection(for: word.word, isSelected: isSelected)
                                }
                            ))
                            .labelsHidden()
                            .toggleStyle(CustomToggleStyle())
                            
                            Spacer()
                            
                            Text(word.word)
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .medium))
                        }
                        .padding()
                        .background(Color("GrayList"))
                        .cornerRadius(10)
                    }
                    .listRowBackground(Color.clear)
                }
                .listStyle(PlainListStyle())
                .background(Color("CustomBackground"))
            }
        .background(Color("CustomBackground"))
        .navigationBarBackButtonHidden(true)
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
    WordListView(category: .init(name: "مشتقات الحليب", words: [
        Word(word: "حليب البقر", hiddenSynonyms: ["String"]),
        Word(word: "حليب الماعز", hiddenSynonyms: ["String"])
    ]), viewModel: CameraViewModel())
}



struct CustomToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? Color("CustomGreen") : Color("CustomeGrayToggle"))// Use custom color
                .frame(width: 50, height: 30)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .padding(2)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            
            Spacer()
            
            configuration.label
        }
    }
}

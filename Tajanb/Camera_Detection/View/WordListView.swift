//
//  WordListView.swift
//  Tajanb
//
//  Created by Afrah Saleh on 20/04/1446 AH.
//


import SwiftUI
import SwiftData

struct WordListView: View {
    let category: Category
    @ObservedObject var viewModel: CameraViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext // Access the modelContext from the environment

    var body: some View {
        VStack {
            
//            VStack(spacing: 6) {
//                
//                Image(systemName: "chevron.backward")
//                    .foregroundColor(.customGreen)
//                    .font(.system(size: 24))
//                    .padding(.top, 5)
//                    .padding(.trailing,340)
//                    .onTapGesture {
//                        dismiss()
//                    }
                
                    Text(category.name)
                        .foregroundColor(.white)
                        .font(.system(size: 24, weight: .bold))
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                        .frame(maxWidth: .infinity, alignment: .leading) // Align to trailing for RTL
                    .padding(.horizontal)
                    

                
                Divider()
                    .background(Color.white)
           // }
            

            
            List {
                ForEach(category.words, id: \.word) { word in
                    HStack {
                        Text(word.word)
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .medium))
                            .frame(maxWidth: .infinity, alignment: .leading) // Ensures Text is aligned to the start
                        
                        Toggle(isOn: Binding(
                            get: { viewModel.selectedWords.contains(word.word) },
                            set: { isSelected in
                                toggleSelection(for: word.word, isSelected: isSelected)
                            }
                        )) {
                            EmptyView() // Use an empty view instead of an empty string
                        }
                        .labelsHidden() // Ensures no label is displayed
                        .toggleStyle(CustomToggleStyle())
                        .padding(.leading, 120) // Add extra space between Text and Toggle if needed
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
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.backward")
                        .foregroundColor(.customGreen)
                }
                .accessibilityLabel("Back")
                .accessibilityHint("Double-tap to go back.")
            }
        }
        .navigationBarBackButtonHidden(true)
        .environment(\.layoutDirection, Locale.current.language.languageCode?.identifier == "ar" ? .rightToLeft : .leftToRight)
    }

    private func toggleSelection(for word: String, isSelected: Bool) {
        if isSelected {
            if !viewModel.selectedWords.contains(word) {
                viewModel.selectedWords.append(word)
                viewModel.saveSelectedWords(using: modelContext)
            }
        } else {
            viewModel.selectedWords.removeAll { $0 == word }
            viewModel.saveSelectedWords(using: modelContext) // Save after removing as well
        }
    }
}
struct CustomToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? Color("CustomGreen") : Color("CustomeGrayToggle"))
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

#Preview {
    WordListView(category: .init(name: "مشتقات الحليب", words: [
        Word(word: "cow milk", hiddenSynonyms: ["String"]),
        Word(word: "yougret", hiddenSynonyms: ["String"])
    ]), viewModel: CameraViewModel())
}

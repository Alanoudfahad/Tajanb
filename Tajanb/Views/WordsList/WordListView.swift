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
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
                    Text(category.name)
                        .foregroundColor(.white)
                        .font(.system(size: 24, weight: .bold))
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                        .frame(maxWidth: .infinity, alignment: .leading) // Align to trailing for RTL
                    .padding(.horizontal)
                    

                
                Divider()
                    .background(Color.white)

            List {
                  ForEach(category.words, id: \.word) { word in
                      HStack {
                          Text(word.word)
                              .foregroundColor(.white)
                              .font(.system(size: 18, weight: .medium))
                              .frame(maxWidth: .infinity, alignment: .leading)
                          
                          Toggle(isOn: Binding(
                              get: { viewModel.selectedWords.contains(word.word) },
                              set: { isSelected in
                                  viewModel.toggleSelection(for: word.word, isSelected: isSelected)
                              }
                          )) {
                              EmptyView()
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
        .onDisappear {
                  viewModel.updateSelectedWords(with: viewModel.selectedWords) // Ensure latest words are saved to UserDefaults
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

}


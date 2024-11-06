


import SwiftUI

struct WordListView: View {
    let category: Category
    @ObservedObject var selectedWordsViewModel: SelectedWordsViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Text(category.name)
                .foregroundColor(.white)
                .font(.system(size: 24, weight: .bold))
                .padding(.top, 20)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            HStack {
                Text("اختيار الكل")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading ,10)
                
                Toggle(isOn: $selectedWordsViewModel.isSelectAllEnabled) {
                    EmptyView()
                }
                .labelsHidden()
                .toggleStyle(CustomToggleStyle())
                .padding(.leading, 100)
            }
            
            .padding(.vertical,16)
            .background(Color("GrayList"))
            .cornerRadius(15)
            .frame(width: 365)
            .onChange(of: selectedWordsViewModel.isSelectAllEnabled) { newValue in
                selectedWordsViewModel.handleSelectAllToggleChange(for: category, isSelected: newValue)
            }
            
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
                            get: { selectedWordsViewModel.selectedWords.contains(word.word) },
                            set: { isSelected in
                                selectedWordsViewModel.toggleSelection(for: category, word: word.word, isSelected: isSelected)
                            }
                        )) {
                            EmptyView()
                        }
                        .labelsHidden()
                        .toggleStyle(CustomToggleStyle())
                        .padding(.leading, 120)
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
        .onAppear {
            selectedWordsViewModel.updateSelectAllStatus(for: category)
        }
        .onDisappear {
            selectedWordsViewModel.saveSelectedWords()
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
                .accessibilityLabel("الرجوع")
                .accessibilityHint("اضغط مرتين للرجوع.")
            }
        }
        .navigationBarBackButtonHidden(true)
        .environment(\.layoutDirection, Locale.current.language.languageCode?.identifier == "ar" ? .rightToLeft : .leftToRight)
    }
}

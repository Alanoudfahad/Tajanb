


import SwiftUI

struct WordListView: View {
    let category: Category
    @ObservedObject var viewModel: CameraViewModel
    @Environment(\.dismiss) var dismiss
    @State private var isSelectAllEnabled: Bool = false // حالة "اختيار الكل"

    var body: some View {
        VStack {
            Text(category.name)
                .foregroundColor(.white)
                .font(.system(size: 24, weight: .bold))
                .padding(.top, 20)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            // "اختيار الكل" بأسلوب مشابه لبقية عناصر القائمة
            HStack {
                Text("اختيار الكل")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading ,10)
                
                Toggle(isOn: $isSelectAllEnabled) {
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
            .onChange(of: isSelectAllEnabled) { newValue in
                handleSelectAllToggleChange(newValue)
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
                            get: { viewModel.selectedWords.contains(word.word) },
                            set: { isSelected in
                                toggleSelection(for: word.word, isSelected: isSelected)
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
            // تعيين "اختيار الكل" إلى true إذا كانت كل الكلمات محددة
            isSelectAllEnabled = viewModel.selectedWords.containsAll(category.words.map { $0.word })
        }
        .onDisappear {
            viewModel.updateSelectedWords(with: viewModel.selectedWords) // حفظ الكلمات المحددة في UserDefaults
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

    // التعامل مع تبديل "اختيار الكل" بناءً على حالة المستخدم
    private func handleSelectAllToggleChange(_ isSelected: Bool) {
        let allWords = category.words.map { $0.word }
        
        if isSelected {
            // إذا تم تفعيل "اختيار الكل"، نضيف كل العناصر
            viewModel.updateSelectedWords(with: allWords)
        } else {
            // إذا أراد المستخدم إيقاف "اختيار الكل" فقط، نترك الاختيار الحالي
            if viewModel.selectedWords.count == allWords.count {
                // إذا كانت جميع العناصر محددة، يتم إلغاء تحديدها كلها
                viewModel.updateSelectedWords(with: [])
            }
        }
    }
    
    // Toggle selection for a single word
    private func toggleSelection(for word: String, isSelected: Bool) {
        if isSelected {
            if !viewModel.selectedWords.contains(word) {
                viewModel.selectedWords.append(word)
            }
        } else {
            viewModel.selectedWords.removeAll { $0 == word }
            isSelectAllEnabled = false // Turn off "Select All" if any item is manually deselected
        }
        
        viewModel.saveSelectedWords() // Save selection to UserDefaults whenever there’s a change
        updateSelectAllStatus() // Update "Select All" based on individual selection
    }
    
    // تحديث حالة "اختيار الكل" بناءً على العناصر الفردية
    private func updateSelectAllStatus() {
        // فعل "اختيار الكل" فقط إذا كانت جميع الكلمات محددة
        let allWords = category.words.map { $0.word }
        if viewModel.selectedWords.isEmpty {
            isSelectAllEnabled = false
        } else if viewModel.selectedWords.containsAll(allWords) {
            isSelectAllEnabled = true
        }
    }
}

// امتداد للتحقق مما إذا كانت كل العناصر موجودة في المجموعة
extension Collection where Element: Equatable {
    func containsAll(_ elements: [Element]) -> Bool {
        return elements.allSatisfy { self.contains($0) }
    }
}

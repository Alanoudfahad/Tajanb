
import SwiftUI
import SwiftData

struct WordListView: View {
    let category: Category
    @ObservedObject var selectedWordsViewModel: SelectedWordsViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    var selectedWord: String? // Add this line

    // Add a state variable to control the animation
    @State private var animateHighlight = false
    @State private var hasScrolledToSelectedWord = false // To ensure scrolling happens only once

    var body: some View {
        VStack {
            // Category Name Header
            Text(category.name)
                .foregroundColor(.white)
                .font(.system(size: 24, weight: .bold))
                .padding(.top, 20)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            // Select All Toggle
            HStack {
                Text("اختيار الكل")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 10)

                Toggle(isOn: $selectedWordsViewModel.isSelectAllEnabled) {
                    EmptyView()
                }
                .labelsHidden()
                .toggleStyle(CustomToggleStyle())
                .padding(.leading, 100)
            }
            .padding(.vertical, 12)
            .background(Color("GrayList"))
            .cornerRadius(15)
            .frame(width: 365)
            .padding(.bottom,10)
            .onChange(of: selectedWordsViewModel.isSelectAllEnabled) { newValue in
                selectedWordsViewModel.handleSelectAllToggleChange(for: category, isSelected: newValue)
            }
         

            Divider()
                .background(Color.white)
                .padding(.bottom,10)
            // Wrap the List in a ScrollViewReader
                      ScrollViewReader { scrollViewProxy in
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
                                  .padding(12)
                                  .background(
                                      // Apply the animation to the selected word
                                      (word.word == selectedWord && animateHighlight) ?
                                      Color("PrimeryButton") : Color("GrayList")
                                  )
                                  .cornerRadius(15)
                                  .id(word.word) // Assign ID to each row
                              }
                              
                              .listRowBackground(Color.clear)
                          }
                          .listStyle(PlainListStyle())
                          .background(Color("CustomBackground"))
                          .onAppear {
                              // Scroll to the selected word when the view appears
                              if let selectedWord = selectedWord, !hasScrolledToSelectedWord {
                                  scrollViewProxy.scrollTo(selectedWord, anchor: .center)
                                  hasScrolledToSelectedWord = true
                              }
                          }
                      }
                  }
                  .onAppear {
                      selectedWordsViewModel.modelContext = modelContext  // Assign modelContext for SwiftData
                      selectedWordsViewModel.updateSelectAllStatus(for: category)  // Sync Select All toggle

                      // Start the animation for the selected word
                      if selectedWord != nil {
                          withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                              animateHighlight = true
                          }
                          // Stop the animation after 6 seconds
                          DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                             withAnimation {
                                 animateHighlight = false
                             }
                          }
                      }
                  }
                  .onDisappear {
                      selectedWordsViewModel.saveSelectedWords()  // Save changes on exit
                      animateHighlight = false // Stop the animation when the view disappears
                  }

        .background(Color("CustomBackground"))
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.backward")
                        .foregroundColor(Color("PrimeryButton"))
                }
                .accessibilityLabel("الرجوع")
                .accessibilityHint("اضغط مرتين للرجوع.")
            }
        }
        .navigationBarBackButtonHidden(true)
        .environment(\.layoutDirection, Locale.current.language.languageCode?.identifier == "ar" ? .rightToLeft : .leftToRight)
    }
}

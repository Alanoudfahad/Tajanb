import SwiftUI
import SwiftData

struct Categories: View {
    @ObservedObject var viewModel: CameraViewModel
    @Environment(\.modelContext) var modelContext

    @Environment(\.dismiss) var dismiss
    @State private var selectedCategory: String?
    @State private var isPressed = false
    @State private var isSuggestionSheetPresented = false
    @State private var searchText: String = ""
    @State private var filteredWords: [SearchableWord] = []
    @State private var allWords: [SearchableWord] = []
    @State private var isNavigatingToWordList = false
    @State private var selectedWord: SearchableWord?
    @State private var isSearchBarVisible = false

    var body: some View {
        VStack {
            // Header
            Text("My Allergies")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 20)
                .padding(.horizontal)
                .accessibilityLabel("My Allergies")

            Text("Avoid your allergic reactions")
                .foregroundColor(.white)
                .padding(.bottom, isSearchBarVisible ? 10 : 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .accessibilityLabel("Avoid your allergic reactions")

            // SearchBar
            if isSearchBarVisible {
                SearchBar(text: $searchText, placeholder: NSLocalizedString("Search Allergies", comment: "Placeholder for searching allergies"))
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                    .transition(.move(edge: .top))
                    .environment(\.layoutDirection, Locale.current.language.languageCode?.identifier == "ar" ? .rightToLeft : .leftToRight) // Handle RTL layout for Arabic
            }

            Divider()
                .background(Color.white)

            // List of categories or search results
            List {
                if !searchText.isEmpty {
                    // Display search results
                    ForEach(filteredWords, id: \.id) { word in
                        Button(action: {
                            // Navigate to the word's category and select the word
                            selectedWord = word
                            isNavigatingToWordList = true
                        }) {
                            Text(word.wordText)
                                .foregroundColor(Color("WhiteText"))
                        }
                    }
                    .listRowBackground(Color.clear)
                } else {
                    // Display categories
                    ForEach(viewModel.firestoreViewModel.availableCategories, id: \.name) { category in
                        ZStack {
                            NavigationLink(destination: WordListView(category: category, selectedWordsViewModel: viewModel.selectedWordsViewModel)) {
                                EmptyView()
                            }
                            .opacity(0)

                            Button(action: {
                                withAnimation {
                                    selectedCategory = category.name
                                }
                            }) {
                                AllergyRow(icon: category.icon, text: category.name)
                                    .background(selectedCategory == category.name ? Color("PrimeryButton") : Color("GrayList"))
                                    .cornerRadius(10)
                            }
                            .accessibilityLabel("Category: \(category.name)")
                            .accessibilityHint("Double-tap to view more details about \(category.name)")
                        }
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .listStyle(PlainListStyle())
            .scrollContentBackground(.hidden)
            .onChange(of: searchText) { _ in
                filterWords()
            }
            .onAppear {
                viewModel.selectedWordsViewModel.loadSelectedWords()
                viewModel.selectedWordsViewModel.modelContext = modelContext
                gatherAllWords()
                print("Categories view appeared. Current categories: \(viewModel.firestoreViewModel.availableCategories.map { $0.name })")
            }

            // Suggestion button
            HStack(alignment: .firstTextBaseline){
                Text("Do you have another type of allergy?")
                    .foregroundColor(Color("BodytextGray"))
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1) // Ensure the text stays on one line
                    .layoutPriority(1) // Give higher priority to the text to prevent truncation


                Button(action: {
                    isSuggestionSheetPresented = true

                    // Set the button as pressed and start a delay to keep it highlighted longer
                    withAnimation {
                        isPressed = true
                    }
                    
                    // Change the color back to the original after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            isPressed = false
                        }
                    }
                }) {
                    Text("Suggest an allergy")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color("PrimeryButton"))
                        .underline()
                }
                .accessibilityLabel("Suggest an Allergy")
                .accessibilityHint("Double-tap to suggest a new allergy type.")
                .onLongPressGesture(minimumDuration: 0.3, pressing: { pressing in
                    withAnimation {
                        isPressed = pressing // Change color when pressing
                    }
                }, perform: {
                })
            }
            .padding()
            .padding(.top,5)            .sheet(isPresented: $isSuggestionSheetPresented) {
                UserSuggestionView(viewModel: viewModel)
                    .presentationDetents([.fraction(0.5)])
            }
        }
        .background(
            NavigationLink(destination: destinationView(), isActive: $isNavigatingToWordList) {
                EmptyView()
            }
            .hidden()
        )
        .onChange(of: isNavigatingToWordList) { isNavigating in
            // Clear the search and close the search bar when returning
            if !isNavigating {
                withAnimation {
                    searchText = ""
                    isSearchBarVisible = false
                }
            }
        }
        .background(Color("CustomBackground").edgesIgnoringSafeArea(.all))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    withAnimation {
                        isSearchBarVisible.toggle()
                        if !isSearchBarVisible {
                            // Clear the search text when closing the search bar
                            searchText = ""
                        }
                    }
                }) {
                    Image(systemName: isSearchBarVisible ? "xmark.circle.fill" : "magnifyingglass")
                        .foregroundColor(Color("PrimeryButton"))
                }
                .accessibilityLabel(isSearchBarVisible ? "Close Search" : "Open Search")
                .accessibilityHint("Double-tap to \(isSearchBarVisible ? "close the search field" : "open the search field").")
            }

            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.backward")
                        .foregroundColor(Color("PrimeryButton"))
                }
                .accessibilityLabel("Back")
                .accessibilityHint("Double-tap to go back.")
            }
        }
        .navigationBarBackButtonHidden(true)
        .environment(\.layoutDirection, Locale.current.language.languageCode?.identifier == "ar" ? .rightToLeft : .leftToRight)
    }

    func destinationView() -> some View {
        if let word = selectedWord {
            return AnyView(WordListView(
                category: word.category,
                selectedWordsViewModel: viewModel.selectedWordsViewModel,
                selectedWord: word.wordText // Pass the selected word here
            ))
        } else {
            return AnyView(EmptyView())
        }
    }

    // Gather all words from all categories for searching
    func gatherAllWords() {
        allWords = viewModel.firestoreViewModel.availableCategories.flatMap { category in
            category.words.map { word in
                SearchableWord(id: word.id, wordText: word.word, category: category)
            }
        }
    }

    // Filter words based on search text
    func filterWords() {
        if searchText.isEmpty {
            filteredWords = []
        } else {
            filteredWords = allWords.filter { $0.wordText.localizedCaseInsensitiveContains(searchText) }
        }
    }
}

//
//  Categories.swift
//  Tajanb
//
//  Created by Afrah Saleh on 17/04/1446 AH.
//
import SwiftUI


struct Categories: View {
    @ObservedObject var viewModel: CameraViewModel

    var body: some View {
        VStack {
            Text("حساسية الطعام")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)
                .padding(.top, 20)

            Text("تجنب ردود الفعل التحسسية لديك")
                .font(.body)
                .foregroundColor(.gray)
                .padding(.bottom, 20)

            List {
                ForEach(viewModel.availableCategories, id: \.name) { category in
                    NavigationLink(destination: WordListView(category: category, viewModel: viewModel)) {
                        HStack {
                            Spacer() // This will push content to the right


                            Text(category.name)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                            
                            Image(systemName: iconForCategory(category.name)) // Custom icon per category
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color(UIColor.darkGray))
                        .cornerRadius(10)
                    }
                    .listRowBackground(Color.black) // Set row background color
                }
            }
            .listStyle(PlainListStyle())
            .padding(.horizontal, 10)

            Spacer()

            Button(action: {
                // Action for suggesting allergies
            }) {
                Text("اقترح حساسية")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.8))
                    .cornerRadius(10)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.black.ignoresSafeArea())
    }

    // Custom icons for each category based on the name
    func iconForCategory(_ category: String) -> String {
        switch category {
        case "مشتقات الحليب":
            return "carton.fill"
        case "البيض":
            return "egg.fill"
        case "الزهورات":
            return "sunflower"
        case "الخضار":
            return "leaf"
        case "الفواكه":
            return "applelogo"
        default:
            return "leaf"
        }
    }
}
//import SwiftUI
//struct Categories: View {
//    @ObservedObject var viewModel: CameraViewModel
//    
//    var body: some View {
//        VStack {
//            List(viewModel.availableCategories, id: \.name) { category in
//                NavigationLink(destination: WordListView(category: category, viewModel: viewModel)) {
//                    HStack {
//                        Text(category.name)
//                            .font(.headline)
//                    }
//                    .padding()
//                }
//            }
//        }
//        .navigationTitle("حساسياتي")
//    }
//}
//struct Categories: View {
//   // @ObservedObject var viewModel: CategoryManagerViewModel
//    @ObservedObject var viewModel: CameraViewModel
//
//    var body: some View {
//        VStack {
//            List(viewModel.availableCategories, id: \.name) { category in
//                Section(header: Text(category.name).font(.headline)) {
//                    ForEach(category.words, id: \.word) { word in
//                        Button(action: {
//                            toggleSelection(for: word.word)
//                        }) {
//                            HStack {
//                                Text(word.word)
//                                Spacer()
//                                if viewModel.selectedWords.contains(word.word) {
//                                    Image(systemName: "checkmark")
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//            
//        }
//    }
//
//    private func toggleSelection(for word: String) {
//        if let selectedWord = viewModel.availableCategories
//            .flatMap({ $0.words })
//            .first(where: { $0.word == word }) {
//            
//            if viewModel.selectedWords.contains(selectedWord.word) {
//                // Remove word and its synonyms if unselected
//                viewModel.selectedWords.removeAll { $0 == selectedWord.word || selectedWord.hiddenSynonyms?.contains($0) == true }
//            } else {
//                // Add word and its hidden synonyms if selected
//                viewModel.selectedWords.append(selectedWord.word)
//                if let synonyms = selectedWord.hiddenSynonyms {
//                    viewModel.selectedWords.append(contentsOf: synonyms)
//                }
//            }
//        }
//        print("Selected Words: \(viewModel.selectedWords)")
//    }
//}


#Preview {
    Categories(viewModel: CameraViewModel())
}


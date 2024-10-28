import SwiftUI
import SwiftData

struct OnboardingView3: View {
    @ObservedObject var cameraViewModel = CameraViewModel()
    @State private var selectedCategories: Set<String> = []
    @State private var navigate = false
    @Binding var hasSeenOnboarding: Bool
    @Binding var justCompletedOnboarding: Bool
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack {
            Spacer()

            Text("Choose type do you have?")
                .font(.system(size: 25, weight: .bold))
                .foregroundColor(Color("CustomGreen"))
                .padding(.bottom, 8)
            
            Text("Select at least 1")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .padding(.bottom, 20)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 6)], spacing: 16) {
                ForEach(cameraViewModel.availableCategories, id: \.name) { category in
                    Button(action: {
                        if selectedCategories.contains(category.name) {
                            selectedCategories.remove(category.name)
                        } else {
                            selectedCategories.insert(category.name)
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text(iconForCategory(category.name))
                                .font(.system(size: 20))
                            Text(category.name)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(selectedCategories.contains(category.name) ? Color("CustomGreen") : Color.gray.opacity(0.2))
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 10)
            
            Spacer()

            Button(action: {
                saveSelectedWords()
                hasSeenOnboarding = true
                navigate = true
                justCompletedOnboarding = true
            }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(selectedCategories.isEmpty ? Color.gray : Color("CustomGreen"))
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
            }
            .disabled(selectedCategories.isEmpty)

            NavigationLink(
                destination: CameraView(viewModel: cameraViewModel, photoViewModel: PhotoViewModel(viewmodel: cameraViewModel)),
                isActive: $navigate
            ) {
                EmptyView()
            }
            Spacer()
        }
        .background(Color("CustomBackground").edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }

    private func iconForCategory(_ category: String) -> String {
        let categoryIcons: [String: String] = [
            "مشتقات الحليب": "🥛", "Dairy Products": "🥛",
            "البيض": "🥚", "Egg": "🥚",
            "البذور": "🌻", "Seeds": "🌻",
            "الخضار": "🥗", "Vegetables": "🥗",
            "الفواكة": "🍓", "Fruits": "🍓",
            "البهارات": "🧂", "Spices": "🧂",
            "القمح (الجلوتين)": "🌾", "Wheat (Gluten)": "🌾",
            "المكسرات": "🥜", "Nuts": "🥜",
            "الكائنات البحرية (القشريات والرخويات)": "🦀", "Seafood": "🦀",
            "الأسماك": "🐟", "Fish": "🐟",
            "البقوليات": "🌽", "Legumes": "🌽"
        ]
        return categoryIcons[category] ?? "❓"
    }

    private func saveSelectedWords() {
        var wordsToSave: [String] = []

        for category in cameraViewModel.availableCategories where selectedCategories.contains(category.name) {
            for word in category.words {
                wordsToSave.append(word.word)
                if let synonyms = word.hiddenSynonyms {
                    wordsToSave.append(contentsOf: synonyms)
                }
            }
        }

        cameraViewModel.updateSelectedWords(with: wordsToSave, using: modelContext)
        print("Words saved: \(wordsToSave)")
    }
}

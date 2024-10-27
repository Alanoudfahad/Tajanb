//
//  OnboardingView3.swift
//  Tajanb
//
//  Created by Afrah Saleh on 23/04/1446 AH.
//

import SwiftUI

struct OnboardingView3: View {
    @ObservedObject var cameraViewModel = CameraViewModel()
    @State private var selectedCategories: Set<String> = []
    @State private var navigate = false
    @Binding var hasSeenOnboarding: Bool
    @Binding var justCompletedOnboarding: Bool // Track onboarding completion
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                // Progress Indicator
                HStack(spacing: 8) {
                    Capsule()
                        .fill(Color("CustomGreen"))
                        .frame(width: 30, height: 4)
                    Capsule()
                        .fill(Color("CustomGreen"))
                        .frame(width: 30, height: 4)
                    Capsule()
                        .fill(Color("CustomGreen"))
                        .frame(width: 30, height: 4)
                }
                .padding(.bottom, 40)
                
                // Title Text
                Text("Choose type do you have?")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundColor(Color("CustomGreen"))
                    .padding(.bottom, 8)
                
                Text("Select at least 1")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
                
                // Flexible Category Buttons in LazyVGrid
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
                // Button to trigger saving and navigation
                Button(action: {
                    // Save selected words to UserDefaults
                    saveSelectedWords()

                    // Immediately set the onboarding flag
                    hasSeenOnboarding = true

                    // Trigger navigation to the next screen
                    navigate = true
                    justCompletedOnboarding = true // Set to true to skip splash screen once

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
                .disabled(selectedCategories.isEmpty) // Disable button if no selection

                // NavigationLink to CameraView
                NavigationLink(
                    destination: CameraView(viewModel: cameraViewModel, photoViewModel: PhotoViewModel(viewmodel: cameraViewModel)),
                    isActive: $navigate
                ) {
                    EmptyView()
                }
                Spacer()
            }
            .background(Color("CustomBackground").edgesIgnoringSafeArea(.all))
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }

    // Helper function to get emoji icon for each category
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

        // Collect words and synonyms from selected categories
        for category in cameraViewModel.availableCategories where selectedCategories.contains(category.name) {
            for word in category.words {
                wordsToSave.append(word.word)
                if let synonyms = word.hiddenSynonyms {
                    wordsToSave.append(contentsOf: synonyms)
                }
            }
        }

        // Save the words to UserDefaults and update the ViewModel
        cameraViewModel.updateSelectedWords(with: wordsToSave)
        
        // Debugging statement
        print("Words saved: \(wordsToSave)")
    }
}


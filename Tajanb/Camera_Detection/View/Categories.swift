//
//  Categories.swift
//  Tajanb
//
//  Created by Afrah Saleh on 17/04/1446 AH.
//

import SwiftUI
struct Categories: View {
    @ObservedObject var viewModel: CameraViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedCategory: String?

    var body: some View {
        VStack {
            VStack(spacing: 0) {
                Text("My Allergies")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                
                Divider()
                    .background(Color.white)
            }
            
            Text("My Allergies")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading) // Changed to leading
                .padding(.top,20)
                .padding(.horizontal)
            
            Text("Avoid your allergic reactions")
                .foregroundColor(.white)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity, alignment: .leading) // Changed to leading
                .padding(.horizontal)
            
            List(viewModel.availableCategories, id: \.name) { category in
                ZStack {
                    NavigationLink(destination: WordListView(category: category, viewModel: viewModel)) {
                        EmptyView()
                    }
                    .opacity(0)
                    
                    Button(action: {
                        withAnimation {
                            selectedCategory = category.name
                        }
                    }) {
                        AllergyRow(icon: iconForCategory(category.name), text: category.name)
                            .background(selectedCategory == category.name ? Color("CustomGreen") : Color("GrayList"))
                            .cornerRadius(10)
                    }
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(PlainListStyle())
            .scrollContentBackground(.hidden)

            Button(action: {
                // Action for the button
            }) {
                Text("اقترح حساسية")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("GrayList"))
                    .cornerRadius(10)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
            .padding(.top, 40)
            
        }
        
        .background(Color("CustomBackground"))
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.backward")
                        .foregroundColor(.white)
                }
            }
        }
        .environment(\.layoutDirection, Locale.current.language.languageCode?.identifier == "ar" ? .rightToLeft : .leftToRight)
    }
    
    func iconForCategory(_ category: String) -> String {
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
}

struct AllergyRow: View {
    var icon: String
    var text: String

    var body: some View {
        HStack {
            Text(icon)
                .font(.system(size: 24)) // Adjust the size of the emoji if needed
                .padding(.trailing, 8)
            Text(text)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color("GrayList"))
        .cornerRadius(10)
    }
}

#Preview {
    Categories(viewModel: CameraViewModel())
        .environment(\.layoutDirection, .rightToLeft) // For Arabic
}


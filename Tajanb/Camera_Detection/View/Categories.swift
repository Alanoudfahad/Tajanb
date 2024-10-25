//
//  Categories.swift
//  Tajanb
//
//  Created by Afrah Saleh on 17/04/1446 AH.
//

import SwiftUI


struct Categories: View {
    @ObservedObject var viewModel: CameraViewModel
    @Environment(\.dismiss) var dismiss // For back navigation
    @State private var selectedCategory: String? // Track the selected category
    
    var body: some View {
        VStack {
            // Custom Navigation Title with line underneath
            VStack(spacing: 0) {
                Text("حساسيني")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.bottom)
                    .padding(.vertical, 8)
                
                Divider()
                    .background(Color.white)
            }
            
            // Main Title
            Text("حساسية الطعام")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 25)
                .padding(.trailing, 16)
            
            // Subtitle
            Text("تجنب ردود الفعل التحسسية لديك")
                .foregroundColor(.white)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 16)
            
            // List of Categories
            List(viewModel.availableCategories, id: \.name) { category in
                ZStack {
                    NavigationLink(destination: WordListView(category: category, viewModel: viewModel)) {
                        EmptyView()
                    }.opacity(0) // Make NavigationLink invisible
                    
                    // AllergyRow as button with animation
                    Button(action: {
                        withAnimation {
                            selectedCategory = category.name
                        }
                    }) {
                        AllergyRow(icon: iconForCategory(category.name), text: category.name)
                            .background(selectedCategory == category.name ? Color.green : Color.secondary)
                            .cornerRadius(10)
                    }
                }
                .listRowBackground(Color.clear) // Transparent row background
            }
            .listStyle(PlainListStyle())
            .scrollContentBackground(.hidden)

            // Button
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
    }
    
    func iconForCategory(_ category: String) -> String {
        switch category {
        case "مشتقات الحليب": return "🥛"
        case "البيض": return "🥚"
        case "البذور": return "🌻"
        case "الخضار": return "🥗"
        case "الفواكة": return "🍓"
        case "البهارات": return "🧂"
        case "القمح (الجلوتين)": return "🌾"
        case "المكسرات": return "🥜"
        case "الكائنات البحرية (القشريات والرخويات)": return "🦀"
        case "الأسماك": return "🐟"
        case "البقوليات": return "🌽"
        default: return "❓"
        }
    }
}

struct AllergyRow: View {
    var icon: String
    var text: String

    var body: some View {
        HStack {
            Text(text)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            Text(icon)
                .padding(.leading, 8)
        }
        .padding()
        .background(Color("GrayList"))
        .cornerRadius(10)
    }
}

#Preview {
    Categories(viewModel: CameraViewModel())
}


//
//  Categories.swift
//  Tajanb
//
//  Created by Afrah Saleh on 17/04/1446 AH.
//
import SwiftUI
import SwiftData


struct Categories: View {
    @ObservedObject var viewModel: CameraViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    @State private var selectedCategory: String?
    @Environment(\.modelContext) private var modelContext
    @State private var isPressed = false // Track button press state

    var body: some View {
        VStack {
            VStack(spacing: 0) {
                Text("My Allergies")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .accessibilityLabel("My Allergies Title")
                
                Divider()
                    .background(Color.white)
            }
            
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
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .accessibilityLabel("Avoid your allergic reactions")
            
            List(viewModel.availableCategories, id: \.name) { category in
                ZStack {
                    NavigationLink(destination: WordListView(category: category, viewModel: viewModel)) {
                        // EmptyView()
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
                    .accessibilityLabel("Category: \(category.name)")
                    .accessibilityHint("Double-tap to view more details about \(category.name)")
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(PlainListStyle())
            .scrollContentBackground(.hidden)

            Button(action: {
                       sendEmail()
                // Set the button as pressed and start a delay to keep it green longer
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
                       Text("اقترح حساسية")
                           .fontWeight(.bold)
                           .foregroundColor(.white)
                           .frame(maxWidth: .infinity)
                           .padding()
                           .background(isPressed ? Color("CustomGreen") : Color("GrayList")) // Change color based on press state
                           .cornerRadius(10)
                   }
                   .padding(.horizontal, 16)
                   .padding(.bottom, 20)
                   .padding(.top, 40)
                   .accessibilityLabel("Suggest an Allergy")
                   .accessibilityHint("Double-tap to suggest a new allergy type.")
                   .onLongPressGesture(minimumDuration: 0.3, pressing: { pressing in
                       withAnimation {
                           isPressed = pressing // Change color when pressing
                       }
                   }, perform: {
                       // Action when the button is released
                       sendEmail()
                   })
                   
               }
               .background(Color.black.edgesIgnoringSafeArea(.all))
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                    viewModel.loadSelectedWords(using: modelContext)
                    viewModel.updateSelectedWords(with: viewModel.selectedWords, using: modelContext) // Ensure latest words are loaded
                }) {
                    Image(systemName: "chevron.backward")
                        .foregroundColor(.white)
                }
                .accessibilityLabel("Back")
                .accessibilityHint("Double-tap to go back.")
            }
        }
        .navigationBarBackButtonHidden(true)
        .environment(\.layoutDirection, Locale.current.language.languageCode?.identifier == "ar" ? .rightToLeft : .leftToRight)
    }
    
    func sendEmail() {
        let email = "tajanbapp@gmail.com"
        let subject = "اقتراح حساسية جديدة"
        let body = "مرحبًا، أرغب في اقتراح حساسية جديدة."
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)") {
            openURL(url)
        }
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
                .font(.system(size: 24))
                .padding(.trailing, 8)
            Text(text)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color("GrayList"))
        .cornerRadius(10)
        .accessibilityElement()
        .accessibilityLabel("\(text) category")
        .accessibilityHint("Double-tap to view details.")
    }
}

//#Preview {
//    Categories(viewModel: CameraViewModel())
//        .environment(\.layoutDirection, .rightToLeft) // For Arabic
//}


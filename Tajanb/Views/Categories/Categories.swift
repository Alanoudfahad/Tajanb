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
    @Environment(\.openURL) var openURL
    @State private var selectedCategory: String?
    @State private var isPressed = false // Track button press state
    @State private var isSuggestionSheetPresented = false
    var body: some View {
        VStack {
            
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
            
            Divider()
                .background(Color.white)
            List(viewModel.firestoreViewModel.availableCategories, id: \.name) { category in
                           ZStack {
                               NavigationLink(destination: WordListView(category: category, selectedWordsViewModel: viewModel.selectedWordsViewModel)) {

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
            .listStyle(PlainListStyle())
            .scrollContentBackground(.hidden)
          
            
            HStack(alignment: .firstTextBaseline){
                Text("هل تعاني من نوع أخر من الحساسية؟")
                    .foregroundColor(Color("BodytextGray"))
                    .font(.system(size: 14, weight: .medium))
              //      .multilineTextAlignment(.trailing)

            Button(action: {
                isSuggestionSheetPresented = true

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
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color("PrimeryButton"))
                
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
            .padding(.top,5)
            
            .sheet(isPresented: $isSuggestionSheetPresented) {
                UserSuggestionView(viewModel: viewModel)
                    .presentationDetents([.fraction(0.5)]) // Set the sheet to half-page height

             }
            
               }
        .onAppear {
            viewModel.selectedWordsViewModel.loadSelectedWords() // Load from UserDefaults
              }

        .background(Color("CustomBackground").edgesIgnoringSafeArea(.all))
        .toolbar {
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


}






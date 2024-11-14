import SwiftUI
import SwiftData
struct PhotoMainView: View {
        @StateObject private var categoryManager = CameraViewModel()
        @StateObject private var photoViewModel: PhotoViewModel
        @State private var selectedImage: UIImage?
        @Environment(\.presentationMode) var presentationMode
        @State private var showingImagePicker = false
        @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext


        init() {
            let categoryManager = CameraViewModel()
            _categoryManager = StateObject(wrappedValue: categoryManager)
            _photoViewModel = StateObject(wrappedValue: PhotoViewModel(viewmodel: categoryManager))
        }

        var body: some View {
            VStack {
                    VStack {
                        PhotoPicker(selectedImage: $selectedImage, photoViewModel: photoViewModel)
                            .accessibilityLabel("Photo Picker")
                            .accessibilityHint("Double-tap to select an image for allergen detection")

                        if let _ = selectedImage {
                            // Create a set of detected words in lowercase for easier comparison
                            let uniqueDetectedWords = Set(photoViewModel.detectedText.map { $0.word.lowercased() })
                            // Use case-insensitive comparison to check for matches with selected words
                            let hasNoAllergens = uniqueDetectedWords.isEmpty || !uniqueDetectedWords.contains { word in
                                categoryManager.selectedWordsViewModel.selectedWords.contains(where: { $0.lowercased() == word })
                            }
                            ZStack{
                                // Scrollable view for words only
                                ScrollView(.vertical) {
                                    FlowLayouts(items: Array(uniqueDetectedWords), horizontalSpacing: 10, verticalSpacing: 10) { word in
                                        if let detectedItem = photoViewModel.detectedText.first(where: { $0.word.lowercased() == word }) {
                                            if categoryManager.selectedWordsViewModel.selectedWords.contains(where: { $0.lowercased() == word }) {
                                                Text(detectedItem.word)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .padding(8)
                                                    .background(Color("AllergyWarningColor"))
                                                    .foregroundColor(.white)
                                                    .clipShape(Capsule())
                                                    .accessibilityLabel(Text("\(detectedItem.word) allergen"))
                                                    .accessibilityHint(Text("Detected allergen from the selected image"))
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 20)
                                }
                                .frame(height: 200) // Constrain the height of the scrollable area for words
                                
                                // Check for the presence of the word "المكونات" and display error message if not found
                                if let freeAllergenMessage = photoViewModel.freeAllergenMessage {
                                    let isError = freeAllergenMessage.contains("عذرًا") || freeAllergenMessage.contains("Sorry")
                                    let isLanguagePrompt = freeAllergenMessage.contains("Please") || freeAllergenMessage.contains("يرجى")

                                    Text(freeAllergenMessage)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(isError ? .black : .white) // Black text for error message for better contrast
                                        .padding(10)
                                        .background(
                                            isError ? Color("YellowText") :
                                            (isLanguagePrompt ? Color("YellowText") : Color("AllergyFreeColor"))
                                        ) // Yellow for error, green for allergen-free
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(
                                            isLanguagePrompt ? .black : (isError ? Color(.black) : Color(.white))
                                        )
                                        .cornerRadius(20)
                                        .padding(.vertical)
                                        .accessibilityLabel(Text(isError ? "Error message" : "Allergen-free message"))
                                        .accessibilityHint(Text(isError ? "Ingredients not found" : "The selected image contains no allergens"))
                                }
                            } .padding()
                        }
           
                    }
                    .onAppear {
                        categoryManager.selectedWordsViewModel.modelContext = modelContext
                        categoryManager.firestoreViewModel.fetchCategories{
                            print("Categories fetched and updated in CameraView.")
                        }
                        categoryManager.firestoreViewModel.fetchWordMappings {
                            print("Word mappings fetched and updated in CameraView.")
                        }
                        // Load selected words using SwiftData model context
                        categoryManager.selectedWordsViewModel.loadSelectedWords()
                    }
//                .onAppear {
//                    categoryManager.selectedWordsViewModel.modelContext = modelContext
//                    categoryManager.firestoreViewModel.fetchCategories{
//      
//                    }
//                    // Load selected words using SwiftData model context
//                    categoryManager.selectedWordsViewModel.loadSelectedWords()
//                }
                Spacer()
                if let image = selectedImage {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("تم")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color("PrimeryButton"))
                            .cornerRadius(10)
                    }
                    .padding()
                    .padding(.bottom, 10)
                    .accessibilityLabel(Text("Done"))
                    .accessibilityHint(Text("Double-tap to go back to the previous screen."))
                }  else {
                    // Button to trigger the image picker
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        Text("اختر صورة")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color("PrimeryButton"))
                            .cornerRadius(10)
                            .padding(.bottom, 10)

                    }
                    .padding()
                }
              
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
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

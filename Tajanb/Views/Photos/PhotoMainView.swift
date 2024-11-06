import SwiftUI

struct PhotoMainView: View {
        @StateObject private var categoryManager = CameraViewModel()
        @StateObject private var photoViewModel: PhotoViewModel
        @State private var selectedImage: UIImage?
        @Environment(\.presentationMode) var presentationMode
        @State private var showingImagePicker = false
        @Environment(\.dismiss) var dismiss

        init() {
            let categoryManager = CameraViewModel()
            _categoryManager = StateObject(wrappedValue: categoryManager)
            _photoViewModel = StateObject(wrappedValue: PhotoViewModel(viewmodel: categoryManager))
        }

        var body: some View {
            VStack {
                ScrollView {
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
                            
                            HStack {
                                
                                ForEach(Array(uniqueDetectedWords), id: \.self) { word in
                                    // Find the detected item using a case-insensitive comparison
                                    if let detectedItem = photoViewModel.detectedText.first(where: { $0.word.lowercased() == word }) {
                                        // Display only if the word matches the user's selected allergens, ignoring case
                                        if categoryManager.selectedWordsViewModel.selectedWords.contains(where: { $0.lowercased() == word }) {
                                            Text(detectedItem.word)
                                                .font(.system(size: 16, weight: .medium))
                                                .padding(10)
                                                .background(Color.red)
                                                .foregroundColor(.white)
                                        
                                                .clipShape(Capsule())
                                                .accessibilityLabel(Text("\(detectedItem.word) allergen"))
                                                .accessibilityHint(Text("Detected allergen from the selected image"))
                                        }
                                    }
                                }
                                .padding(.vertical)
                            }
                        }
                        
                        // Check for the presence of the word "المكونات" and display error message if not found
                        if let freeAllergenMessage = photoViewModel.freeAllergenMessage {
                            let isError = freeAllergenMessage.contains("خطأ") || freeAllergenMessage.contains("Error")
                            
                            Text(freeAllergenMessage)
                                .font(.system(size: 16, weight: .medium))
                                .padding(10)
                                .background(isError ? Color.yellow : Color(red: 163/255, green: 234/255, blue: 11/255)) // Yellow for error, green for allergen-free
                                .foregroundColor(isError ? .black : .white) // Black text for error message for better contrast
                                .clipShape(Capsule())
                                .padding(.vertical)
                                .accessibilityLabel(Text(isError ? "Error message" : "Allergen-free message"))
                                .accessibilityHint(Text(isError ? "Ingredients not found" : "The selected image contains no allergens"))
                        }
                    }
                    .padding()
                }
                .onAppear {
                    categoryManager.firestoreViewModel.fetchCategories{
                        
                    }
                    // Load selected words using SwiftData model context
                    categoryManager.selectedWordsViewModel.loadSelectedWords()
                }
                if let image = selectedImage {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("تم")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(red: 163/255, green: 234/255, blue: 11/255))
                            .cornerRadius(10)
                    }
                    .padding()
                    .accessibilityLabel(Text("Done"))
                    .accessibilityHint(Text("Double-tap to go back to the previous screen."))
                    .background(Color(red: 30/255, green: 30/255, blue: 30/255))
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
                            .background(Color(red: 163/255, green: 234/255, blue: 11/255))
                            .cornerRadius(10)
                    }
                    .padding()
                }
              
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        .background(Color(red: 30/255, green: 30/255, blue: 30/255).edgesIgnoringSafeArea(.all))
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.backward")
                        .foregroundColor(.customGreen)
                }
                .accessibilityLabel("Back")
                .accessibilityHint("Double-tap to go back.")
            }
        }
        .navigationBarBackButtonHidden(true)
        .environment(\.layoutDirection, Locale.current.language.languageCode?.identifier == "ar" ? .rightToLeft : .leftToRight)
    }
}

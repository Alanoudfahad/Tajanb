import SwiftUI
import SwiftData
struct PhotoMainView: View {
    @StateObject private var categoryManager = CameraViewModel()
    @StateObject private var photoViewModel: PhotoViewModel
    @State private var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) private var modelContext // Access SwiftData model context

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
                            categoryManager.selectedWords.contains(where: { $0.lowercased() == word })
                        }

                        if hasNoAllergens {
                            Text("خالي من مسببات الحساسية")
                                .font(.system(size: 16, weight: .medium))
                                .padding(10)
                                .background(Color(red: 163/255, green: 234/255, blue: 11/255))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                                .padding(.vertical)
                                .accessibilityLabel(Text("خالي من مسببات الحساسية"))
                                .accessibilityHint(Text("The selected image contains no allergens"))
                        } else {
                            HStack {
                                ForEach(Array(uniqueDetectedWords), id: \.self) { word in
                                    // Find the detected item using a case-insensitive comparison
                                    if let detectedItem = photoViewModel.detectedText.first(where: { $0.word.lowercased() == word }) {
                                        // Display only if the word matches the user's selected allergens, ignoring case
                                        if categoryManager.selectedWords.contains(where: { $0.lowercased() == word }) {
                                            Text(detectedItem.word)
                                                .font(.system(size: 16, weight: .medium))
                                                .padding(10)
                                                .background(Color(red: 226/255, green: 66/255, blue: 66/255))
                                                .foregroundColor(.white)
                                                .clipShape(Capsule())
                                                .accessibilityLabel(Text("\(detectedItem.word) allergen"))
                                                .accessibilityHint(Text("Detected allergen from the selected image"))
                                        }
                                    }
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
                .padding()
            }
            .onAppear {
                      // Load selected words using SwiftData model context
                      categoryManager.loadSelectedWords(using: modelContext)
                  }
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
        }
        .background(Color(red: 30/255, green: 30/255, blue: 30/255).edgesIgnoringSafeArea(.all))
    }
}

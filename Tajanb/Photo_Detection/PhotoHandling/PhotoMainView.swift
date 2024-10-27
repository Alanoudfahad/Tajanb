import SwiftUI

struct PhotoMainView: View {
    @StateObject private var categoryManager = CameraViewModel()
    @StateObject private var photoViewModel: PhotoViewModel
    @State private var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode

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
                        let uniqueDetectedWords = Set(photoViewModel.detectedText.map { $0.word.lowercased() })
                        let hasNoAllergens = uniqueDetectedWords.isEmpty || !uniqueDetectedWords.contains { word in
                            categoryManager.selectedWords.contains(word)
                        }

                        if hasNoAllergens {
                            Text("خالي من مسببات الحساسية")
                                .font(.system(size: 16, weight: .medium))
                                .padding(10)
                                .background(Color(red: 163/255, green: 234/255, blue: 11/255))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                                .padding(.vertical)
                                .accessibilityLabel("Allergen-free")
                                .accessibilityHint("The selected image contains no allergens")
                        } else {
                            HStack {
                                ForEach(Array(uniqueDetectedWords), id: \.self) { word in
                                    if let detectedItem = photoViewModel.detectedText.first(where: { $0.word.lowercased() == word }) {
                                        if categoryManager.selectedWords.contains(word) {
                                            Text("\(detectedItem.word)")
                                                .font(.system(size: 16, weight: .medium))
                                                .padding(10)
                                                .background(Color(red: 226/255, green: 66/255, blue: 66/255))
                                                .foregroundColor(.white)
                                                .clipShape(Capsule())
                                                .accessibilityLabel("\(detectedItem.word) allergen")
                                                .accessibilityHint("Detected allergen from the selected image")
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

            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 163/255, green: 234/255, blue: 11/255))
                    .cornerRadius(10)
            }
            .padding()
            .accessibilityLabel("Done")
            .accessibilityHint("Double-tap to go back to the previous screen.")
            .background(Color(red: 30/255, green: 30/255, blue: 30/255))
        }
        .background(Color(red: 30/255, green: 30/255, blue: 30/255).edgesIgnoringSafeArea(.all))
    }
}


import SwiftUI

struct PhotoMainView: View {
    @StateObject private var categoryManager = CameraViewModel()
    @StateObject private var photoViewModel: PhotoViewModel
    @State private var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode // To control the navigation back

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

                    // Display capsules only after an image is selected
                    if let _ = selectedImage {
                        if photoViewModel.detectedText.isEmpty {
                            // Show green capsule if no words are detected
                            Text("خالي من مسببات الحساسية")
                                .font(.system(size: 16, weight: .medium))
                                .padding(10)
                                .background(Color(red: 163/255, green: 234/255, blue: 11/255)) // Color #A3EA0B
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                                .padding(.vertical)
                                .accessibilityLabel("Allergen-free")
                                .accessibilityHint("The selected image contains no allergens")
                        } else {
                            // Using a Set to avoid duplicates
                            let uniqueDetectedWords = Set(photoViewModel.detectedText.map { $0.word.lowercased() })

                            // Displaying words next to each other using HStack
                            HStack {
                                ForEach(Array(uniqueDetectedWords), id: \.self) { word in
                                    if let detectedItem = photoViewModel.detectedText.first(where: { $0.word.lowercased() == word }) {
                                        if categoryManager.selectedWords.contains(word) {
                                            Text("\(detectedItem.word)")
                                                .font(.system(size: 16, weight: .medium))
                                                .padding(10)
                                                .background(Color(red: 226/255, green: 66/255, blue: 66/255)) // Color #E24242
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

            // Fixed Done Button at the bottom
            Button(action: {
                // Navigate back to the CameraView when Done is pressed
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 163/255, green: 234/255, blue: 11/255)) // Color #A3EA0B
                    .cornerRadius(10)
            }
            .padding()
            .accessibilityLabel("Done")
            .accessibilityHint("Double-tap to go back to the previous screen.")
            .background(Color(red: 30/255, green: 30/255, blue: 30/255))
        }
        .background(Color(red: 30/255, green: 30/255, blue: 30/255).edgesIgnoringSafeArea(.all)) // shade of grey for background
    }
}

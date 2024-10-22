import SwiftUI
import Photos

struct PhotoPicker: View {
    @State private var selectedImage: UIImage?
    @ObservedObject var photoViewModel: PhotoViewModel
    @State private var showingImagePicker = false // State variable to control the image picker

    var body: some View {
        VStack {
            // Display the selected image if it exists
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .padding()
                    .accessibilityLabel("صورة مختارة") // Accessibility label in Arabic
            } else {
                // Placeholder view when no image is selected
                Text("لم يتم اختيار صورة")
                    .foregroundColor(.gray)
                    .padding()
                    .accessibilityLabel("لم يتم اختيار أي صورة") // Accessibility label in Arabic
            }

            Button(action: {
                showingImagePicker = true // Show the image picker
            }) {
                Text("اختر صورة") // Button text in Arabic
            }
            .accessibilityLabel("اختر صورة من المكتبة ") // Accessibility label in Arabic
            .accessibilityHint("يفتح مكتبة الصور لاختيار صورة") // Hint in Arabic
            .padding()
        }
        .onAppear {
            showingImagePicker = true // Automatically show the image picker when the view appears
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .onChange(of: selectedImage) { newImage in
            if let newImage = newImage {
                photoViewModel.resetPredictions() // Clear old predictions
                photoViewModel.startTextRecognition(from: newImage) // Call text recognition on the selected image
            }
        }
    }
}

// ImagePicker to allow users to select an image from their photo library
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
                print("تم اختيار الصورة: \(uiImage)") // Debug print in Arabic
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary // Set source type to photo library
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

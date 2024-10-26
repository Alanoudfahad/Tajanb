import SwiftUI
import Photos
import PhotosUI

struct PhotoPicker: View {
    @Binding var selectedImage: UIImage?
    @ObservedObject var photoViewModel: PhotoViewModel
    @State private var showingImagePicker = false

    var body: some View {
        VStack {
            // Header
            Text("نتيجة المكونات الموضحة في الصورة")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top)

            // Display the selected image inside a border
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .padding()
            } else {
                // Placeholder text when no image is selected
                Text("لم يتم اختيار صورة")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .onAppear {
            showingImagePicker = true
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .onChange(of: selectedImage) { newImage in
            if let newImage = newImage {
                photoViewModel.resetPredictions() // Clear previous results
                photoViewModel.startTextRecognition(from: newImage) // Start text recognition for new image
            }
        }
    }
}

// ImagePicker struct remains unchanged
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
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

import SwiftUI
import Photos
import PhotosUI

struct PhotoPicker: View {
    @Binding var selectedImage: UIImage?
    @ObservedObject var photoViewModel: PhotoViewModel
    @State private var showingImagePicker = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            Spacer()
            if let image = selectedImage {
                // Only show this text and button after an image is selected
                Text("نتيجة المكونات الموضحة في الصورة")
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.top)

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .padding()

            } else {
                               Spacer()

                               Text("لم يتم اختيار صورة")
                                   .foregroundColor(.gray)
                                   .font(.headline)
                                   .padding()

                               Spacer()

            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure the VStack takes the whole screen size

        .onAppear {
            photoViewModel.requestPhotoLibraryAccess() // Request access when view appears
            showingImagePicker = true // Show the image picker
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

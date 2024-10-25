import SwiftUI
import Photos
import PhotosUI

struct PhotoPicker: View {
    @State private var selectedImage: UIImage?
    @ObservedObject var photoViewModel: PhotoViewModel
    @State private var showingImagePicker = false
    @Environment(\.presentationMode) var presentationMode // To control the navigation back

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
                    .accessibilityLabel("لم يتم اختيار أي صورة")
            }

            Spacer()

            // Done Button
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
            .padding(.bottom, 30) // Align button at the bottom
        }
        .background(Color(red: 30/255, green: 30/255, blue: 30/255).edgesIgnoringSafeArea(.all)) // shade of grey for background
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

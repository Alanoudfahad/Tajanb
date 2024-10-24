import SwiftUI

//@Environment(\.presentationMode) var presentationMode // To control the navigation back
//presentationMode.wrappedValue.dismiss()

struct PhotoMainView: View {
    @StateObject private var categoryManager = CameraViewModel()
    @StateObject private var photoViewModel: PhotoViewModel

    init() {
        let categoryManager = CameraViewModel()
        _categoryManager = StateObject(wrappedValue: categoryManager)
        _photoViewModel = StateObject(wrappedValue: PhotoViewModel(viewmodel: categoryManager))
    }

    var body: some View {
        ScrollView {
            VStack {
                PhotoPicker(photoViewModel: photoViewModel)

                if !photoViewModel.detectedText.isEmpty {
                    Text("Predictions for your allergies:")
                        .font(.headline)
                        .padding(.top)

                    // Using a Set to avoid duplicates
                    let uniqueDetectedWords = Set(photoViewModel.detectedText.map { $0.word.lowercased() })

                    ForEach(Array(uniqueDetectedWords), id: \.self) { word in
                        if let detectedItem = photoViewModel.detectedText.first(where: { $0.word.lowercased() == word }) {
                            if categoryManager.selectedWords.contains(word) {
                                Text("\(detectedItem.category): \(detectedItem.word)")
                                    .font(.system(size: 16, weight: .medium))
                                    .padding(10)
                                    .background(Color(red: 226/255, green: 66/255, blue: 66/255)) // Color #E24242
                                    .foregroundColor(.white)
                                    .clipShape(Capsule()) // Red rounded capsule style
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(red: 30/255, green: 30/255, blue: 30/255).edgesIgnoringSafeArea(.all)) // shade of grey for background
    }
}

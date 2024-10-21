import SwiftUI

struct PhotoMainView: View {
    @StateObject private var categoryManager = CategoryManagerViewModel()
    @StateObject private var textRecognitionViewModel: TextRecognitionViewModel

    init() {
        _textRecognitionViewModel = StateObject(wrappedValue: TextRecognitionViewModel(categoryManager: categoryManager))
    }

    var body: some View {
        NavigationView {
            VStack {
                PhotoPicker(textRecognitionViewModel: textRecognitionViewModel)
                // Additional UI components related to recognized text, if needed.
            }
            .navigationTitle("Photo Recognition")
        }
    }
}
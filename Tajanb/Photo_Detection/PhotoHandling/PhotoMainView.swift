//
//  PhotoMainView.swift
//  Tajanb
//
//  Created by Alanoud Alshuaibi on 19/04/1446 AH.
//


import SwiftUI

struct PhotoMainView: View {
    @StateObject private var categoryManager = CameraViewModel()
    @StateObject private var photoViewModel: PhotoViewModel

    init() {
        let categoryManager = CameraViewModel()
        _categoryManager = StateObject(wrappedValue: categoryManager)
        _photoViewModel = StateObject(wrappedValue: PhotoViewModel(viewmodel: categoryManager))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    PhotoPicker(photoViewModel: photoViewModel)

                    if !photoViewModel.detectedText.isEmpty {
                        Text("Predictions for your allergies:")
                            .font(.headline)
                            .padding(.top)

                        ForEach(photoViewModel.detectedText, id: \.word) { detected in
                            if categoryManager.selectedWords.contains(detected.word.lowercased()) {
                                Text("\(detected.category): \(detected.word)")
                                    .padding(.bottom, 5)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Photo Recognition")
        }
    }
}

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

    // Initialize the photoViewModel with the categoryManager
    init() {
        let categoryManager = CameraViewModel() // Create an instance of CategoryManagerViewModel
        _categoryManager = StateObject(wrappedValue: categoryManager) // Initialize StateObject for categoryManager
        _photoViewModel = StateObject(wrappedValue: PhotoViewModel(viewmodel: categoryManager)) // Initialize StateObject for photoViewModel
    }

    var body: some View {
        NavigationView {
            ScrollView { // Wrap content in ScrollView for scrolling
                VStack {
                    PhotoPicker(photoViewModel: photoViewModel) // Inject PhotoViewModel

                    // Toggle for allergy categories
                    Text("Select Your Allergies")
                        .font(.headline)
                        .padding()

                    ForEach(categoryManager.availableCategories, id: \.name) { category in
                        Toggle(isOn: Binding(
                            get: { categoryManager.selectedWords.contains(category.name) },
                            set: { isSelected in
                                if isSelected {
                                    categoryManager.selectedWords.append(category.name)
                                } else {
                                    categoryManager.selectedWords.removeAll(where: { $0 == category.name })
                                }
                            }
                        )) {
                            Text(category.name)
                        }
                        .padding()
                    }

                    // Display detected text predictions
                    if !photoViewModel.detectedText.isEmpty {
                        Text("Predictions for your allergies:")
                            .font(.headline)
                            .padding(.top)

                        ForEach(photoViewModel.detectedText, id: \.word) { detected in
                            Text("\(detected.category): \(detected.word)")
                                .padding(.bottom, 5)
                        }
                    }
                }
                .padding() // Add padding to the VStack
            }
            .navigationTitle("Photo Recognition")
        }
    }
}

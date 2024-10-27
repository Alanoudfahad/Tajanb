//
//  CameraView.swift
//  Tajanb
//
//  Created by Afrah Saleh on 17/04/1446 AH.
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    @ObservedObject var viewModel: CameraViewModel
    @ObservedObject var photoViewModel: PhotoViewModel
    let boxWidthPercentage: CGFloat = 0.7
    let boxHeightPercentage: CGFloat = 0.2
    @State private var selectedNavigation: String? = nil // Track selected navigation
    @State private var isCategoriesActive = false // Track if categories button is active
    @State private var isPhotoActive = false // Track if photo button is active

    var body: some View {
        NavigationStack {
            ZStack {
                // Camera preview
                CameraPreview(session: viewModel.getSession())
                    .edgesIgnoringSafeArea(.all)
                    .accessibilityLabel("Live camera preview")
                    .accessibilityHint("Displays what the camera is currently viewing")

                
                VStack {
                    Spacer()
                    
                    // Display the camera scanning box
                    ZStack {
                        CornerBorderView(boxWidthPercentage: boxWidthPercentage, boxHeightPercentage: boxHeightPercentage)
                            .accessibilityHidden(true)
                        
                        // Prompt if no ingredients are detected and freeAllergenMessage is nil
                        if viewModel.detectedText.isEmpty && viewModel.freeAllergenMessage == nil {
                            Text("Point to an ingredient to scan")
                                .foregroundColor(.white)
                                .font(.system(size: 17, weight: .medium))
                                .padding(.horizontal, 8)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(8)
                                .accessibilityLabel("Point to an ingredient to scan")
                        }
                    }
                    
                    // Display allergen-free message below the scanning box if non-nil
                    if let freeAllergenMessage = viewModel.freeAllergenMessage {
                        Text(freeAllergenMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color("FreeColor"))
                            .cornerRadius(20)
                            .padding(.top, 10)
                            .accessibilityLabel(freeAllergenMessage)
                    }

                    // Display detected words at the bottom
                    if !viewModel.detectedText.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(viewModel.detectedText, id: \.word) { item in
                                    Text(item.word)
                                        .font(.system(size: 14, weight: .medium))
                                        .padding(10)
                                        .background(Color.red.opacity(0.8))
                                        .foregroundColor(.white)
                                        .cornerRadius(20)
                                        .accessibilityLabel(item.word)
                                        .accessibilityHint("Detected allergen")
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                        }
                    }

                    Spacer()
                }
                
                // Bottom buttons
                VStack {
                    Spacer()
                    HStack {
                        // Navigation to the Categories view
                        NavigationLink(value: "categories") {
                            VStack {
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 24))
                                    .tint(Color("CustomGreen"))
                                    .padding()
                                    .background(
                                        Circle()
                                            .fill(isCategoriesActive ? Color("CustomGreen") : Color.black.opacity(0.7))
                                    )
                                Text("My Allergies")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        .simultaneousGesture(TapGesture()
                            .onEnded {
                                isCategoriesActive = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    selectedNavigation = "categories"
                                    isCategoriesActive = false
                                }
                            }
                        )
                        .accessibilityLabel("My Allergies")
                        .accessibilityHint("Double-tap to view your allergy categories")

                        Spacer()
                        
                        // Navigation to the photo view
                        NavigationLink(value: "photo") {
                            VStack {
                                Image(systemName: "photo")
                                    .font(.system(size: 24))
                                    .padding()
                                    .tint(Color("CustomGreen"))
                                    .background(
                                        Circle()
                                            .fill(isPhotoActive ? Color("CustomGreen") : Color.black.opacity(0.7))
                                    )
                                Text("تحميل صورة")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        .simultaneousGesture(TapGesture()
                            .onEnded {
                                isPhotoActive = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    selectedNavigation = "photo"
                                    isPhotoActive = false
                                }
                            }
                        )
                        .accessibilityLabel("Upload Photo")
                        .accessibilityHint("Double-tap to upload a photo for scanning")
                    }
                    .padding()
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)
                }
                .navigationDestination(for: String.self) { destination in
                    switch destination {
                    case "categories":
                        Categories(viewModel: viewModel)
                    case "photo":
                        PhotoMainView().navigationBarBackButtonHidden(true)
                    default:
                        EmptyView()
                    }
                }
            }
            .onAppear {
                viewModel.startSession()

                // Load initial data if needed
               if let savedWords = UserDefaults.standard.array(forKey: "selectedWords") as? [String] {
                   viewModel.updateSelectedWords(with: savedWords)
               }
            }
            .onDisappear {
                viewModel.stopSession()
            }
    

        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)

    }
}
#Preview {
    CameraView(viewModel: CameraViewModel(), photoViewModel: PhotoViewModel(viewmodel: CameraViewModel()))

}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }
}

//
//  CameraView.swift
//  Tajanb
//
//  Created by Afrah Saleh on 17/04/1446 AH.
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    @ObservedObject var textRecognitionViewModel: TextRecognitionViewModel
    @ObservedObject var categoryManagerViewModel: CategoryManagerViewModel

    // Define the size and position of the box (as a percentage of the screen)
    let boxWidthPercentage: CGFloat = 0.7
    let boxHeightPercentage: CGFloat = 0.2

    var body: some View {
        NavigationView {
            ZStack {
                // Camera preview
                CameraPreview(session: textRecognitionViewModel.getSession())
                    .edgesIgnoringSafeArea(.all)
                
                // Scanning label at the top
                VStack {
                    Text("Scanning...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                        .padding(.top, 50)
                    
                    Spacer()
                }

                // Overlay box with dynamic content
                VStack {
                    Spacer()
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color.gray, lineWidth: 3)
                            .frame(width: UIScreen.main.bounds.width * boxWidthPercentage, height: UIScreen.main.bounds.height * boxHeightPercentage)
                        
                        // Conditionally display point label or detected text
                        if textRecognitionViewModel.detectedText.isEmpty {
                            Text("Point at an ingredient")
                                .foregroundColor(.white)
                                .font(.system(size: 17, weight: .medium))
                                .padding(.horizontal, 8)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(8)
                        } else {
                            VStack {
                                ForEach(textRecognitionViewModel.detectedText, id: \.word) { item in
                                    HStack {
                                        Text("\(item.category): \(item.word)") // Display category and word
                                            .font(.largeTitle)
                                            .padding()
                                            .background(Color.black.opacity(0.7))
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                
                // Bottom buttons
                VStack {
                    Spacer()
                    
                    HStack {
                        Button(action: {
                            // Action for upload photos
                        }) {
                            VStack {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 24))
                                Text("Upload photos")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .padding(16)
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(30)
                        }
                        
                        Spacer()
                        
                        // Navigation to the Categories view
                        NavigationLink(destination: Categories(viewModel: categoryManagerViewModel)) {
                            VStack {
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 24))
                                Text("My allergies")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .padding(16)
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(30)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)
                }
            }
            .onAppear {
                textRecognitionViewModel.startSession()
            }
            .onDisappear {
                textRecognitionViewModel.stopSession()
            }
        }
    }
}

#Preview {
    CameraView(
        textRecognitionViewModel: TextRecognitionViewModel(categoryManager: CategoryManagerViewModel()),
        categoryManagerViewModel: CategoryManagerViewModel()
    )
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

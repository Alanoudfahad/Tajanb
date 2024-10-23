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

    // Define the size and position of the box (as a percentage of the screen)
    let boxWidthPercentage: CGFloat = 0.7
    let boxHeightPercentage: CGFloat = 0.2

    var body: some View {
        NavigationView {
            ZStack {
                // Camera preview
                CameraPreview(session: viewModel.getSession())
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
                            .strokeBorder(Color.white, lineWidth: 3)
                            .frame(width: UIScreen.main.bounds.width * boxWidthPercentage, height: UIScreen.main.bounds.height * boxHeightPercentage)
                        
                        // Conditionally display point label or detected text
                        if viewModel.detectedText.isEmpty {
                            Text("Point at an ingredient")
                                .foregroundColor(.white)
                                .font(.system(size: 17, weight: .medium))
                                .padding(.horizontal, 8)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(8)
                        }
                    }
                    
                    // If detected text is not empty, display detected words at the bottom
                    if !viewModel.detectedText.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(viewModel.detectedText, id: \.word) { item in
                                    Text(item.word)
                                        .font(.system(size: 16, weight: .medium))
                                        .padding(10)
                                        .background(Color.red.opacity(0.8))
                                        .foregroundColor(.white)
                                        .cornerRadius(20)
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
                        // Navigation to the photo view
                       NavigationLink(destination: PhotoPicker(photoViewModel: photoViewModel)) {
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
                        NavigationLink(destination: Categories(viewModel: viewModel)) {
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
                viewModel.startSession()
        
            }
            .onDisappear {
                viewModel.stopSession()
            }
        }
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

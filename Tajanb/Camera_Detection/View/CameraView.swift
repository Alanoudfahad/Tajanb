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
    @State private var selectedNavigation: String? = nil // Track selected navigation

    var body: some View {
        NavigationStack {
            ZStack {
                // Camera preview
                CameraPreview(session: viewModel.getSession())
                    .edgesIgnoringSafeArea(.all)
                
                // Scanning label at the top
                VStack {
                    Text("مسح....")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(8)
                        .padding(.top, 50)
                    
                    Spacer()
                }
                VStack {
                    Spacer()
                    
                    ZStack {
                    CornerBorderView(boxWidthPercentage: boxWidthPercentage, boxHeightPercentage: boxHeightPercentage)
                        // Conditionally display point label or detected text
                        if viewModel.detectedText.isEmpty {
                            Text("أشر إلى أحد المكونات")
                                .foregroundColor(.white)
                                .font(.system(size: 17, weight: .medium))
                                .padding(.horizontal, 8)
                   
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

                  // Navigation to the Categories view
                  NavigationLink(destination: Categories(viewModel: viewModel)) {
                      VStack {
                          Image(systemName: "list.bullet")
                              .font(.system(size: 24))
                              .tint(.white)
                              .padding()
                              .background(Circle().fill(selectedNavigation == "categories" ? Color("CustomGreen") : Color.black.opacity(0.7)))
                          Text("حساسياتي")
                              .font(.system(size: 14, weight: .medium))
                              .foregroundColor(.white)
                      }
                  }
                        Spacer()
                    // Navigation to the photo view
                        NavigationLink(destination: PhotoMainView()
                            .navigationBarBackButtonHidden(true)) {
                            VStack {
                                Image(systemName: "photo")
                                    .font(.system(size: 24))
                                    .padding()
                                    .tint(.white)
                                    .background(Circle().fill(selectedNavigation == "photo" ? Color("CustomGreen") : Color.black.opacity(0.7)))

                                Text("تحميل صورة")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                            }
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

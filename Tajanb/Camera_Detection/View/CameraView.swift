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
    let boxWidthPercentage: CGFloat = 0.6
    let boxHeightPercentage: CGFloat = 0.3

    var body: some View {
        NavigationView {
            ZStack {
                CameraPreview(session: textRecognitionViewModel.getSession())
                    .edgesIgnoringSafeArea(.all)

                // Overlay the detection box
                VStack {

                    
                    Spacer()

                    Rectangle()
                        .strokeBorder(Color.red, lineWidth: 3)
                        .frame(width: UIScreen.main.bounds.width * boxWidthPercentage, height: UIScreen.main.bounds.height * boxHeightPercentage)
                        .background(Color.clear)
                    
                    Spacer()
                }

                VStack {
                    // Add Navigation to Category List
                    NavigationLink(destination: Categories(viewModel: categoryManagerViewModel)) {
                        Text("View Categories")
                            .font(.callout)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    if textRecognitionViewModel.detectedText.isEmpty {
                        Text("Ensure 'مكونات' and the ingredients are visible inside the box.")
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        ForEach(textRecognitionViewModel.detectedText, id: \.word) { item in
                            HStack {
                                Text("\(item.category): \(item.word)")  // Display category and word
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
                    Spacer()
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



//
//  CameraView.swift
//  Tajanb
//
//  Created by Afrah Saleh on 17/04/1446 AH.
//

import SwiftUI
import AVFoundation
import SwiftData

struct CameraView: View {
    @ObservedObject var viewModel: CameraViewModel
    @ObservedObject var photoViewModel: PhotoViewModel
    let boxWidthPercentage: CGFloat = 0.7
    let boxHeightPercentage: CGFloat = 0.3
    @State private var selectedNavigation: String? = nil
    @State private var isCategoriesActive = false
    @State private var isPhotoActive = false
    @State private var allowCameraWithVoiceOver = false // User preference for allowing camera with VoiceOver
    @Environment(\.modelContext) private var modelContext
    @State private var isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
    @State private var showRetakeButton = false // Track if the user can retake the photo
    @State private var isCameraRunning = true // Track if the camera is running
    @State private var photoCaptured: UIImage? = nil // Hold the captured photo

    var body: some View {
        
        NavigationStack {
            ZStack {
                if viewModel.cameraPermissionGranted {
                    if isCameraRunning {
                        CameraPreview(session: viewModel.getSession())
                            .edgesIgnoringSafeArea(.all)
                            .accessibilityHidden(!allowCameraWithVoiceOver)
                            .accessibilityLabel("Live camera preview")
                            .accessibilityHint("Displays what the camera is currently viewing")
                    } else if let capturedPhoto = photoCaptured {
                        Image(uiImage: capturedPhoto)
                            .resizable()
                            .scaledToFill()
                            .edgesIgnoringSafeArea(.all)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    Text("Camera permission is required to scan ingredients.")
                        .padding()
                        .multilineTextAlignment(.center)
                }
            
                VStack {
                    Spacer()

                    ZStack {
                        CornerBorderView(boxWidthPercentage: boxWidthPercentage, boxHeightPercentage: boxHeightPercentage)
                            .accessibilityHidden(true)
                        
                        if isCameraRunning && !isVoiceOverRunning {
                            if viewModel.detectedText.isEmpty && viewModel.freeAllergenMessage == nil {
                                Text("وجه الكاميرا نحو المكونات للمسح")
                                    .foregroundColor(.white)
                                    .font(.system(size: 17, weight: .medium))
                                    .padding(.horizontal, 8)
                                    .background(Color.black.opacity(0.5))
                                    .cornerRadius(8)
                                    .accessibilityLabel("Point to an ingredient to scan")
                            }
                        }
                    }

                    if !isCameraRunning, let freeAllergenMessage = viewModel.freeAllergenMessage {
                        let isError = freeAllergenMessage.contains("خطأ") || freeAllergenMessage.contains("Error")
                        Text(freeAllergenMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black)
                            .padding()
                            .background(isError ? Color.yellow : Color("FreeColor"))
                            .cornerRadius(20)
                            .padding(.top, 10)
                            .accessibilityLabel(freeAllergenMessage)
                    }

                    if !isCameraRunning, !viewModel.detectedText.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                let uniqueDetectedWords = Set(viewModel.detectedText.map { $0.word.lowercased() })
                                let summary = uniqueDetectedWords.joined(separator: ", ")

                                HStack(spacing: 10) {
                                    ForEach(Array(uniqueDetectedWords), id: \.self) { word in
                                        if let detectedItem = viewModel.detectedText.first(where: { $0.word.lowercased() == word }) {
                                            if viewModel.selectedWords.contains(where: { $0.lowercased() == word }) {
                                                Text(detectedItem.word)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .padding(10)
                                                    .background(Color.red.opacity(0.8))
                                                    .foregroundColor(.white)
                                                    .cornerRadius(20)
                                            }
                                        }
                                    }
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel(Text("Detected words: \(summary)"))
                                .accessibilityHint("Swipe through detected words")
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                        }
                        .padding()
                    }

                    Spacer()
                }

                VStack {
                    Spacer()
                    HStack {
                        NavigationLink(value: "categories") {
                            VStack {
                                ZStack {
                                    Circle()
                                        .fill(Color.black.opacity(0.7))
                                        .frame(width: 70, height: 70)
                                    Image(systemName: "list.bullet")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color("CustomGreen"))
                                }
                                Text("حساسيني")
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
                                    viewModel.stopSession()
                                }
                            }
                        )
                        .accessibilityLabel(Text("My Allergies"))
                        .accessibilityHint(Text("Double-tap to view your allergy categories"))
                        
                        Spacer()

                        if isCameraRunning {
                            Button(action: {
                                viewModel.capturePhoto { image in
                                    DispatchQueue.main.async {
                                        photoCaptured = image
                                        isCameraRunning = false
                                        showRetakeButton = true
                                        viewModel.stopSession()
                                        
                                        if let capturedPhoto = photoCaptured {
                                            viewModel.resetPredictions()
                                            viewModel.startTextRecognition(from: capturedPhoto)
                                        }
                                    }
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 4)
                                        .frame(width: 80, height: 80)
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 60, height: 60)
                                }
                            }
                            .padding(.bottom,10)
                            .accessibilityLabel(Text("Take Photo"))
                            .accessibilityHint(Text("Double-tap to take a photo"))
                        }

                        Spacer()

                        NavigationLink(value: "photo") {
                            VStack {
                                ZStack {
                                    Circle()
                                        .fill(Color.black.opacity(0.7))
                                        .frame(width: 70, height: 70)
                                    Image(systemName: "photo")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color("CustomGreen"))
                                }
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
                                    viewModel.stopSession()
                                }
                            }
                        )
                        .accessibilityLabel(Text("Upload Photo"))
                        .accessibilityHint(Text("Double-tap to upload a photo for scanning"))
                    }
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
                
                if showRetakeButton {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                viewModel.resetPredictions()
                                viewModel.detectedText = []
                                viewModel.freeAllergenMessage = nil
                                isCameraRunning = true
                                showRetakeButton = false
                                viewModel.startSession()
                                viewModel.updateROI(boxWidthPercentage: boxWidthPercentage, boxHeightPercentage: boxHeightPercentage)
                            }) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.customGreen, lineWidth: 2)
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "xmark")
                                        .foregroundColor(.customGreen)
                                        .font(.system(size: 20))
                                }
                            }
                            .padding([.trailing, .top], 20)
                            .accessibilityLabel(Text("Close and Retake Photo"))
                            .accessibilityHint(Text("Double-tap to retake the photo"))
                        }
                        Spacer()
                    }
                    .padding()
                }
            }
            .onAppear {
                DispatchQueue.main.async {
                    viewModel.prepareSession()
                    viewModel.updateROI(boxWidthPercentage: boxWidthPercentage, boxHeightPercentage: boxHeightPercentage)
                    viewModel.loadSelectedWords(using: modelContext)
                    viewModel.updateSelectedWords(with: viewModel.selectedWords, using: modelContext)

                    if allowCameraWithVoiceOver || !isVoiceOverRunning {
                        viewModel.startSession()
                    }

                    NotificationCenter.default.addObserver(forName: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil, queue: .main) { _ in
                        isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
                        if isVoiceOverRunning {
                            if !allowCameraWithVoiceOver {
                                viewModel.stopSession()
                            }
                        } else {
                            viewModel.startSession()
                        }
                    }
                }
            }
            .onDisappear {
                viewModel.stopSession()
                NotificationCenter.default.removeObserver(self, name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
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

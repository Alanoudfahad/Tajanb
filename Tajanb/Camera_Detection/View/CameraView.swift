
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
                    // Camera preview only shows if the camera is running
                    if isCameraRunning {
                        CameraPreview(session: viewModel.getSession())
                            .edgesIgnoringSafeArea(.all)
                            .accessibilityHidden(!allowCameraWithVoiceOver)
                            .accessibilityLabel("Live camera preview")
                            .accessibilityHint("Displays what the camera is currently viewing")
                    } else if let capturedPhoto = photoCaptured {
                        Image(uiImage: capturedPhoto)
                            .resizable()
                            .scaledToFill() // Fills the screen, cropping if necessary
                            .edgesIgnoringSafeArea(.all) // Ignore the safe area
                            .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure it stretches to fill the screen
                    }
                } else {
                    Text("Camera permission is required to scan ingredients.")
                        .padding()
                        .multilineTextAlignment(.center)
                }
            

                VStack {
                    Spacer()

                    // Display scanning box and prompt only if the camera is running
                    ZStack {
                       
                        
                        // Corner border should always be visible, regardless of whether the camera is running or a photo is captured
                        CornerBorderView(boxWidthPercentage: boxWidthPercentage, boxHeightPercentage: boxHeightPercentage)
                            .accessibilityHidden(true)
                        
                        // Show instructions only when the camera is running
                        if isCameraRunning && !isVoiceOverRunning {
                            if viewModel.detectedText.isEmpty && viewModel.freeAllergenMessage == nil {
                           // if photoViewModel.detectedText.isEmpty && photoViewModel.freeAllergenMessage == nil {
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

                

                    // Display allergen-free or error message if applicable after the photo is captured
                    if !isCameraRunning, let freeAllergenMessage = viewModel.freeAllergenMessage {
                        let isError = freeAllergenMessage.contains("خطأ") || freeAllergenMessage.contains("Error")

                        Text(freeAllergenMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black) // Set text color to black for readability on yellow
                            .padding()
                            .background(isError ? Color.yellow : Color("FreeColor")) // Yellow for error, free color for success
                            .cornerRadius(20)
                            .padding(.top, 10)
                            .accessibilityLabel(freeAllergenMessage)
                    }

                    // Display detected allergens or words only after photo is captured
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

                // Bottom buttons
                VStack {
                    Spacer()
                    // Bottom buttons
                    HStack {
                        // Left button - Allergies (حساسيني)
                        NavigationLink(value: "categories") {
                            VStack {
                                ZStack {
                                    Circle()
                                        .fill(Color.black.opacity(0.7)) // Background color
                                        .frame(width: 70, height: 70) // Adjust size as needed

                                    Image(systemName: "list.bullet")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color("CustomGreen")) // Icon color
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

                        // Center button - Take Photo (Visible when the camera is running)
                        if isCameraRunning {
                            Button(action: {
                                viewModel.capturePhoto { image in
                                    DispatchQueue.main.async {
                                        photoCaptured = image
                                        isCameraRunning = false
                                        showRetakeButton = true
                                        viewModel.stopSession()
                                        
                                        // Start text recognition once the photo is captured
                                        if let capturedPhoto = photoCaptured {
                                            viewModel.resetPredictions()
                                            viewModel.startTextRecognition(from: capturedPhoto) // This triggers text recognition
                                        }
                                    }
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 4) // Outer white ring
                                        .frame(width: 80, height: 80) // Outer circle size

                                    Circle()
                                        .fill(Color.white) // Inner filled circle
                                        .frame(width: 60, height: 60) // Inner circle size
                                }
                            }
                            .padding(.bottom,10)
                            .accessibilityLabel(Text("Take Photo"))
                            .accessibilityHint(Text("Double-tap to take a photo"))
                        }

                        Spacer()

                        // Right button - Upload (تحميل صورة)
                        NavigationLink(value: "photo") {
                            VStack {
                                ZStack {
                                    Circle()
                                        .fill(Color.black.opacity(0.7)) // Background color
                                        .frame(width: 70, height: 70) // Adjust size as needed

                                    Image(systemName: "photo")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color("CustomGreen")) // Icon color
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
                // Retake Button - Displayed at the top-right when `showRetakeButton` is true
                  if showRetakeButton {
                      VStack {
                          HStack {
                              Spacer() // Pushes the button to the right

                              Button(action: {
                                  // Reset the detected text and free allergen message
                                  viewModel.resetPredictions()

                                  // Restart the camera session for retaking the photo
                                  isCameraRunning = true
                                  showRetakeButton = false
                                  viewModel.startSession()
                                  viewModel.updateROI(boxWidthPercentage: boxWidthPercentage, boxHeightPercentage: boxHeightPercentage)

                              }) {
                                  ZStack {
                                      // Outer white circle
                                      Circle()
                                          .stroke(Color.customGreen, lineWidth: 2) // Outer white ring
                                          .frame(width: 40, height: 40)

                                      // "X" icon
                                      Image(systemName: "xmark")
                                          .foregroundColor(.customGreen)
                                          .font(.system(size: 20)) // Adjust "X" size here
                                  }
                              }
                              
                              .padding([.trailing, .top], 20) // Position it at the top-right corner
                              .accessibilityLabel(Text("Close and Retake Photo"))
                              .accessibilityHint(Text("Double-tap to retake the photo"))
                          }

                          Spacer() // Pushes the content to the top
                              
                       }
                      .padding()
                   }
                }
            .onAppear {
                // Trigger session preparation with optimized permission handling
                DispatchQueue.main.async {
                    viewModel.prepareSession()
                    viewModel.updateROI(boxWidthPercentage: boxWidthPercentage, boxHeightPercentage: boxHeightPercentage)
                    viewModel.loadSelectedWords(using: modelContext)
                    viewModel.updateSelectedWords(with: viewModel.selectedWords, using: modelContext)

                    // Immediately start the session if VoiceOver is not running or allowed
                    if allowCameraWithVoiceOver || !isVoiceOverRunning {
                        viewModel.startSession()  // Ensure session starts immediately
                    }

                    // Listen for VoiceOver changes
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
                viewModel.stopSession()  // Ensure session is stopped when the view disappears
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
        previewLayer.videoGravity = .resizeAspectFill // Ensure it fills the screen
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds // Ensure the preview layer fills the full view
            }
        }
    }
}

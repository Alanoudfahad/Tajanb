////
////  CameraView.swift
////  Tajanb
////
////  Created by Afrah Saleh on 17/04/1446 AH.
////

import SwiftUI

struct CameraView: View {
    @ObservedObject var viewModel: CameraViewModel
    @ObservedObject var photoViewModel: PhotoViewModel
    
    @Environment(\.layoutDirection) var layoutDirection
    // UI state and configuration variables
    let boxWidthPercentage: CGFloat = 0.7
    let boxHeightPercentage: CGFloat = 0.3
    @State private var selectedNavigation: String? = nil
    @State private var isCategoriesActive = false
    @State private var isPhotoActive = false
    @State private var allowCameraWithVoiceOver = false
    @State private var isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
    @State private var showRetakeButton = false
    @State private var isCameraRunning = true
    @State private var photoCaptured: UIImage? = nil
    
    @State private var isFlashOn: Bool = false

    // State to manage focus indicator visibility and position
    @State private var focusIndicatorPosition: CGPoint = .zero
    @State private var showFocusIndicator: Bool = false
    
    
    // Computed properties
    private var uniqueDetectedWords: [String] {
        let wordsSet = Set(viewModel.detectedText.map { $0.word.lowercased() })
        return Array(wordsSet).sorted()
    }
    
    private var detectedWordsSummary: String {
        uniqueDetectedWords.joined(separator: ", ")
    }
    
    private var detectedItemsToDisplay: [DetectedTextItem] {
        viewModel.detectedText.filter { item in
            viewModel.selectedWordsViewModel.selectedWords.contains(where: { $0.lowercased() == item.word.lowercased() })
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Camera preview or captured photo display
                if viewModel.cameraPermissionGranted {
                    if isCameraRunning {
                        CameraPreview(session: viewModel.cameraManager.getSession(),
                                      onZoomChange: { delta in
                            viewModel.handleZoom(delta: delta)
                        },
                                      onTapToFocus: { location in
                            // Call handleTap in the view model to set focus
                            viewModel.handleTap(location: location)
                            
                            // Update the focus indicator position
                            focusIndicatorPosition = location
                            showFocusIndicator = true
                            
                            // Hide the focus indicator after a short delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                withAnimation {
                                    showFocusIndicator = false
                                }
                            }
                        })
                        .edgesIgnoringSafeArea(.all)
                        .accessibilityHidden(!allowCameraWithVoiceOver)
                        .accessibilityLabel("Live camera preview")
                        .accessibilityHint("Displays what the camera is currently viewing")
                        
                        // Focus Indicator Overlay
                        if showFocusIndicator {
                            FocusIndicator()
                                .position(x: focusIndicatorPosition.x, y: focusIndicatorPosition.y)
                                .transition(.opacity)
                        }
                    }else
                    if let capturedPhoto = photoCaptured {
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
                // Add this VStack to place the flash button at the top
                VStack {
                    HStack {
                        Spacer()
                        // Show flash button only when the camera is running
                        if isCameraRunning {
                            Button(action: {
                                isFlashOn.toggle()
                                viewModel.toggleFlash(isOn: isFlashOn)
                            }) {
                                Image(systemName: isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                                    .foregroundColor(isFlashOn ? Color("YellowText"): .white)  // Change color based on isFlashOn state
                                    .padding()
                                    .font(.system(size: 25))  // Increase the size of the icon

                            }
                            .accessibilityLabel(isFlashOn ? "Turn flash off" : "Turn flash on")
                            .accessibilityHint("Double-tap to toggle flash")
                        }
                    }
                    Spacer()
                }
            
                VStack {
                    
                    Spacer()
                    
                    // Box overlay and instruction text
                    ZStack {
                        if isCameraRunning && !isVoiceOverRunning {
                            if viewModel.hasDetectedIngredients {
                                Text("خذ الصورة الآن")
                                    .foregroundColor(Color("YellowText"))
                                    .font(.system(size: 20, weight: .bold))
                                    .padding(.horizontal, 10)
                                    .background(Color("SecondaryButton"))
                                    .cornerRadius(10)
                                    .padding(.top, 20)
                                    .accessibilityLabel("Take the picture now")
                            } else {
                                Text("وجه الكاميرا نحو المكونات للمسح")
                                    .foregroundColor(.white)
                                    .font(.system(size: 17, weight: .medium))
                                    .padding(.horizontal, 8)
                                    .background(Color("SecondaryButton"))
                                    .cornerRadius(8)
                                    .accessibilityLabel("Point to an ingredient to scan")
                            }
                        }
                    }
                    
                    // Display allergen message or detected ingredients list
                    if !isCameraRunning, let freeAllergenMessage = viewModel.freeAllergenMessage {
                        let isError = freeAllergenMessage.contains("عذرًا") || freeAllergenMessage.contains("Sorry")
                        Text(freeAllergenMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black)
                            .padding()
                            .background(isError ? Color("YellowText") : Color("AllergyFreeColor"))
                            .cornerRadius(20)
                            .padding(.top, 10)
                            .accessibilityLabel(freeAllergenMessage)
                    }
                    
                    // Display detected items in a flow layout
                    if !isCameraRunning, !detectedItemsToDisplay.isEmpty {
                        FlowLayout(items: detectedItemsToDisplay) { detectedItem in
                            Text(detectedItem.word)
                                .font(.system(size: 14, weight: .medium))
                                .padding(10)
                                .background(Color("AllergyWarningColor"))
                                .foregroundColor(.white)
                                .cornerRadius(20)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                    }
                    Spacer()
                }
                .padding()
                
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                
                VStack {
                    Spacer()
                    
                    // Navigation and action buttons
                    HStack {
                        NavigationLink(value: "categories") {
                            ButtonView(systemImage: "text.page", label: NSLocalizedString("My Allergies", comment: "Label for my allergies"))
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            isCategoriesActive = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                selectedNavigation = "categories"
                                isCategoriesActive = false
                                viewModel.cameraManager.stopSession()
                            }
                        })
                        .accessibilityLabel("My Allergies")
                        .accessibilityHint("Double-tap to view your allergy categories")
                        
                        Spacer()
                        
                        // Capture photo button
                        if isCameraRunning {
                            Button(action: {
                                viewModel.cameraManager.capturePhoto { image in
                                    DispatchQueue.main.async {
                                        photoCaptured = image
                                        isCameraRunning = false
                                        showRetakeButton = true
                                        isFlashOn = false
                                        viewModel.cameraManager.stopSession()
                                        
                                        if let capturedPhoto = photoCaptured {
                                            viewModel.resetPredictions()
                                            viewModel.startTextRecognition(from: capturedPhoto)
                                        }
                                    }
                                }
                            }) {
                                CaptureButtonView()
                            }
                            .padding(.bottom, 10)
                            .accessibilityLabel("Take Photo")
                            .accessibilityHint("Double-tap to take a photo")
                        }
                        
                        Spacer()
                        
                        NavigationLink(value: "photo") {
                            ButtonView(systemImage: "photo", label: NSLocalizedString("Upload Photo", comment: "Label for uploading a photo"))
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            isPhotoActive = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                selectedNavigation = "photo"
                                isPhotoActive = false
                                viewModel.cameraManager.stopSession()
                            }
                        })
                        .accessibilityLabel("Upload Photo")
                        .accessibilityHint("Double-tap to upload a photo for scanning")
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)
                }
                
                // Handle navigation based on selected option
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
                
                // Retake button for redoing the scan
                if showRetakeButton {
                    VStack {
                        HStack {
                            if layoutDirection == .rightToLeft {
                                Spacer()
                                Button(action: {
                                    viewModel.retakePhoto()
                                    isCameraRunning = true
                                    showRetakeButton = false
                                    photoCaptured = nil
                                }) {
                                    RetakeButtonView()
                                }
                                .padding(.leading, 50) // Adjust padding for RTL
                                .padding()
                            } else {
                                Button(action: {
                                    viewModel.retakePhoto()
                                    isCameraRunning = true
                                    showRetakeButton = false
                                    photoCaptured = nil
                                }) {
                                    RetakeButtonView()
                                }
                                .padding(.trailing, 50) // Adjust padding for LTR
                                .padding()
                                Spacer()
                            }
                        }
                        .padding(.top, 20)
                        .accessibilityLabel("Close and Retake Photo")
                        .accessibilityHint("Double-tap to retake the photo")
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .onAppear {
                viewModel.selectedWordsViewModel.loadSelectedWords()
                viewModel.firestoreViewModel.fetchCategories(completion: {
                    // Handle completion if needed
                })
                
                DispatchQueue.main.async {
                    viewModel.prepareSession()
                    
                    NotificationCenter.default.addObserver(forName: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil, queue: .main) { _ in
                        isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
                        if isVoiceOverRunning {
                            if !allowCameraWithVoiceOver {
                                viewModel.cameraManager.stopSession()
                            }
                        } else {
                            viewModel.cameraManager.startSession()
                        }
                    }
                }
            }
            .onDisappear {
                viewModel.cameraManager.stopSession()
                NotificationCenter.default.removeObserver(self, name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
}



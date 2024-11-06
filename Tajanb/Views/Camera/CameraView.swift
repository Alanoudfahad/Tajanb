//
//  CameraView.swift
//  Tajanb
//
//  Created by Afrah Saleh on 17/04/1446 AH.
//

import SwiftUI
import AVFoundation
import UIKit
import Vision

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
    
    var body: some View {
        
        NavigationStack {
            ZStack {
                // Camera preview or captured photo display
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
                    
                    // Box overlay and instruction text
                    ZStack {
                        CornerBorderView(boxWidthPercentage: boxWidthPercentage, boxHeightPercentage: boxHeightPercentage)
                            .accessibilityHidden(true)
                        // For debugging purposes
                        if isCameraRunning && !isVoiceOverRunning {
                            if viewModel.hasDetectedIngredients {
                                Text("خذ الصورة الآن")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 20, weight: .bold))
                                    .padding(.horizontal, 10)
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(10)
                                    .padding(.top, 20)
                                    .accessibilityLabel("Take the picture now")
                            } else {
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
                    
                    // Display allergen message or detected ingredients list
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
                    
                    // Display detected words in a horizontal scroll view
                    if !isCameraRunning, !viewModel.detectedText.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                let uniqueDetectedWords = Set(viewModel.detectedText.map { $0.word.lowercased() })
                                let summary = uniqueDetectedWords.joined(separator: ", ")
                                
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
                                viewModel.stopSession()
                            }
                        })
                        .accessibilityLabel("My Allergies")
                        .accessibilityHint("Double-tap to view your allergy categories")
                        
                        Spacer()
                        
                        // Capture photo button
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
                                CaptureButtonView()
                            }
                            .padding(.bottom, 10)
                            .accessibilityLabel("Take Photo")
                            .accessibilityHint("Double-tap to take a photo")
                        }
                        
                        Spacer()
                        
                        NavigationLink(value: "photo") {
                            ButtonView(systemImage: "photo", label: NSLocalizedString("upload photo", comment: "Label for uploading a photo"))
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            isPhotoActive = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                selectedNavigation = "photo"
                                isPhotoActive = false
                                viewModel.stopSession()
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
                                    viewModel.updateROI(boxWidthPercentage: boxWidthPercentage, boxHeightPercentage: boxHeightPercentage)
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
                                    viewModel.updateROI(boxWidthPercentage: boxWidthPercentage, boxHeightPercentage: boxHeightPercentage)
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
            .onAppear{
                viewModel.loadSelectedWords()
                viewModel.fetchCategories()

                      DispatchQueue.main.async {
                          viewModel.prepareSession()
                          viewModel.updateROI(boxWidthPercentage: boxWidthPercentage, boxHeightPercentage: boxHeightPercentage)

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



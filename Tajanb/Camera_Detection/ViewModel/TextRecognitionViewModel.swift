////
////  TextRecognitionViewModel.swift
////  Tajanb
////
////  Created by Afrah Saleh on 17/04/1446 AH.
////
//
//import Foundation
//import AVFoundation
//import Vision
//import CoreHaptics
//import UIKit
////This will handle the text recognition logic (capturing, processing text, OCR, etc.).
//class TextRecognitionViewModel: NSObject, ObservableObject {
//
//    @Published var detectedText: [(category: String, word: String, hiddenSynonyms: [String])] = []
//    private var session: AVCaptureSession!
//    private var textRequest = VNRecognizeTextRequest(completionHandler: nil)
//    private var frameCount = 0
//    private let frameSkipCount = 3 // Process every 3rd frame
//    private var hapticManager = HapticManager() // Haptic feedback manager.
//
//    var categoryManager: CategoryManagerViewModel
//
//    init(categoryManager: CategoryManagerViewModel) {
//        self.categoryManager = categoryManager
//        super.init()
//        configureCaptureSession()
//        configureTextRecognition()
//        
//    }
//
//    private func configureCaptureSession() {
//        session = AVCaptureSession()
//        session.sessionPreset = .high
//        
//        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
//              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
//
//        session.addInput(videoInput)
//        
//        let videoOutput = AVCaptureVideoDataOutput()
//        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "cameraQueue"))
//        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
//        session.addOutput(videoOutput)
//        
//        do {
//            try videoDevice.lockForConfiguration()
//            if videoDevice.isFocusModeSupported(.continuousAutoFocus) {
//                videoDevice.focusMode = .continuousAutoFocus
//            }
//            videoDevice.unlockForConfiguration()
//        } catch {
//            print("Error configuring focus: \(error)")
//        }
//    }
//
//    private func configureTextRecognition() {
//        textRequest = VNRecognizeTextRequest { [weak self] (request, error) in
//            guard let self = self else { return }
//
//            if let error = error {
//                print("Error recognizing text: \(error)")
//                return
//            }
//
//            guard let observations = request.results as? [VNRecognizedTextObservation] else {
//                print("No text observations")
//                return
//            }
//
//            let detectedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
//            print("Detected text: \(detectedStrings)")  // Add this for debugging
//            DispatchQueue.main.async {
//                self.processDetectedText(detectedStrings)
//            }
//        }
//          
//
//          textRequest.recognitionLevel = .accurate
//          textRequest.recognitionLanguages = ["ar", "ar-SA", "ar-AE"]
//          textRequest.usesLanguageCorrection = true
//          textRequest.minimumTextHeight = 0.005
//      }
//    
//     func processDetectedText(_ detectedStrings: [String]) {
//        let combinedText = detectedStrings.joined(separator: " ")
//        let cleanedText = categoryManager.preprocessText(combinedText)
//
//        if categoryManager.fuzzyContains(cleanedText, keyword: "المكونات") {
//            if let range = cleanedText.range(of: "المكونات")?.upperBound {
//                let ingredientsText = String(cleanedText[range...]).trimmingCharacters(in: .whitespaces)
//                let ingredients = categoryManager.splitIngredients(from: ingredientsText)
//
//                let filteredIngredients = ingredients.filter { categoryManager.isSelectedWord($0) }
//                updateDetectedIngredients(filteredIngredients)
//            } else {
//                detectedText = []
//            }
//        } else {
//            detectedText = []
//        }
//    }
//
//    private func updateDetectedIngredients(_ ingredients: [String]) {
//        let targetWords = ingredients.compactMap { ingredient -> (String, String, [String])? in
//            if let (category, word, hiddenSynonyms) = categoryManager.isTargetWord(ingredient.lowercased()) {
//                let detectedSynonyms = hiddenSynonyms.filter { categoryManager.selectedWords.contains($0.lowercased()) }
//                return (category, word, detectedSynonyms)
//            }
//            return nil
//        }
//
//        if !detectedText.elementsEqual(targetWords, by: { $0 == $1 }) {
//            detectedText = targetWords
//            if !targetWords.isEmpty {
//                hapticManager.performHapticFeedback()
//            }
//        }
//    }
//
//    func startSession() {
//        DispatchQueue.global(qos: .userInitiated).async {
//            self.session.startRunning()
//        }
//    }
//    
//    func stopSession() {
//        session.stopRunning()
//    }
//    
//    func getSession() -> AVCaptureSession {
//        return session
//    }
//    
//    
//}
//
//extension TextRecognitionViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
//    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
//
//        // Define the region of interest (ROI) for the box area in normalized coordinates
//        let roiBox = CGRect(
//            x: 0.2,  // Starting at 20% of the width (left)
//            y: 0.35, // Starting at 35% of the height (from the bottom)
//            width: 0.6,  // Box is 60% of the screen width
//            height: 0.3  // Box is 30% of the screen height
//        )
//
//        // Apply region of interest (adjust for Vision's coordinate system)
//        textRequest.regionOfInterest = roiBox
//
//        // Set correct image orientation (depends on device and capture configuration)
//        let imageOrientation: CGImagePropertyOrientation = .right
//
//        // Use the cropped region to process the text
//        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: imageOrientation, options: [:])
//        do {
//            try requestHandler.perform([textRequest])
//        } catch {
//            print("Failed to perform text recognition request: \(error)")
//        }
//    }
//}

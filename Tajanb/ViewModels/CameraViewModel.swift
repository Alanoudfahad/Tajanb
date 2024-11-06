//
//  CameraViewModel.swift
//  Text_Detection
//
//  Created by Afrah Saleh on 11/03/1446 AH.
//

import Foundation
import AVFoundation
import Vision
import UIKit
import SwiftUICore
import FirebaseFirestore
import Combine

class CameraViewModel: NSObject, ObservableObject {
    var wordMappings: [String: (arabic: String, english: String)] = [:]

    @Published var availableCategories = [Category]()
    @Published var detectedText: [(category: String, word: String, hiddenSynonyms: [String])] = []
    @Published var selectedWords = [String]()
    @Published var freeAllergenMessage: String?
    @Published var cameraPermissionGranted: Bool = false
    @Published var hasDetectedIngredients: Bool = false
    @Published var liveDetectedText: String = ""
    var matchedWordsSet: Set<String> = []
    var foundAllergens = false
    private var session: AVCaptureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var capturedPhotoCompletion: ((UIImage?) -> Void)?
    private let videoOutput = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "cameraQueue")  // Queue for video processing
    var textRequest = VNRecognizeTextRequest(completionHandler: nil)
    var hapticManager = HapticManager()
    private let screenBounds = UIScreen.main.bounds  // Screen bounds for bounding box calculation
    var regionOfInterest: CGRect = .zero
     let userDefaultsKey = "selectedWords" // Key for UserDefaults

    override init() {
            super.init()
            loadSelectedWords() // Load words from UserDefaults
            configureTextRecognitions()  // Configure Vision request for text recognition
            configureCaptureSession()
    }
    

 
    // MARK: - Fetch categories and their associated words from Firestore
    
    func fetchWordMappings() {
        let db = Firestore.firestore()
        
        // Fetch Arabic words
        db.collection("categories_arabic").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return } // Safely unwrap `self`
            guard let documents = snapshot?.documents, error == nil else { return }
            
            for document in documents {
                let data = document.data()
                if let words = data["words"] as? [[String: Any]] {
                    for wordData in words {
                        if let id = wordData["id"] as? String,
                           let word = wordData["word"] as? String {
                            self.wordMappings[id] = (arabic: word, english: self.wordMappings[id]?.english ?? "")
                        }
                    }
                }
            }
        }

        // Fetch English words
        db.collection("categories_english").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            guard let documents = snapshot?.documents, error == nil else { return }
            
            for document in documents {
                let data = document.data()
                if let words = data["words"] as? [[String: Any]] {
                    for wordData in words {
                        if let id = wordData["id"] as? String,
                           let word = wordData["word"] as? String {
                            self.wordMappings[id] = (arabic: self.wordMappings[id]?.arabic ?? "", english: word)
                        }
                    }
                }
            }
        }
    }
    // Fetch categories from Firestore
    func fetchCategories() {
        let db = Firestore.firestore()
        
        // Determine the device language (e.g., "en" for English, "ar" for Arabic)
        let deviceLanguageCode = Locale.preferredLanguages.first?.prefix(2) ?? "en"
        
        // Use the language code to select the appropriate Firestore collection
        let collectionName = deviceLanguageCode == "ar" ? "categories_arabic" : "categories_english"
        
        db.collection(collectionName).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching categories: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No categories found")
                return
            }
            
            // Decode Firestore documents into `Category` objects
            self.availableCategories = documents.compactMap { document in
                try? document.data(as: Category.self)
            }
        }
    }
    
    
    
    
    // MARK: - upload .json categories and their associated words into Firestore
    func uploadJSONToFirestore() {
        // Load the JSON files from your bundle
        guard let englishFileURL = Bundle.main.url(forResource: "categories_en", withExtension: "json"),
              let arabicFileURL = Bundle.main.url(forResource: "categories_ar", withExtension: "json"),
              let englishData = try? Data(contentsOf: englishFileURL),
              let arabicData = try? Data(contentsOf: arabicFileURL) else {
            print("Failed to load JSON files")
            return
        }

        do {
            // Decode JSON data
            let englishCategories = try JSONDecoder().decode([Category].self, from: englishData)
            let arabicCategories = try JSONDecoder().decode([Category].self, from: arabicData)
            
            let db = Firestore.firestore()
            
            // Upload each category to Firestore
            for category in englishCategories {
                let documentRef = db.collection("categories_english").document(category.name)
                documentRef.setData(category.toDictionary())
            }
            
            for category in arabicCategories {
                let documentRef = db.collection("categories_arabic").document(category.name)
                documentRef.setData(category.toDictionary())
            }
            
            print("Data uploaded successfully")
        } catch {
            print("Error decoding JSON: \(error)")
        }
    }

    // Firestore save function
       func saveSuggestion(_ suggestionText: String, completion: @escaping (Result<Void, Error>) -> Void) {
           let db = Firestore.firestore()
           db.collection("User_Suggestions").addDocument(data: [
               "suggestion": suggestionText,
               "timestamp": Timestamp(date: Date())
           ]) { error in
               if let error = error {
                   completion(.failure(error))
               } else {
                   completion(.success(()))
               }
           }
       }
    
    
    
    // MARK: - Camera functions
    // Configure camera capture session and add video/photo output
    private func configureCaptureSession() {
        session.beginConfiguration()
        session.sessionPreset = .hd1280x720  // Set session quality
        
        // Remove any existing input
        if let currentInput = session.inputs.first {
            session.removeInput(currentInput)
        }
        
        // Add camera input to session
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
        
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }
        
        // Add video output for real-time frame capture
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        // Add photo output to session
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        
        session.commitConfiguration()
        
        // Configure device for continuous focus and exposure
        do {
            try videoDevice.lockForConfiguration()
            if videoDevice.isFocusModeSupported(.continuousAutoFocus) {
                videoDevice.focusMode = .continuousAutoFocus
            }
            if videoDevice.isExposureModeSupported(.continuousAutoExposure) {
                videoDevice.exposureMode = .continuousAutoExposure
            }
            videoDevice.unlockForConfiguration()
        } catch {
            print("Error configuring camera: \(error)")
        }
        
        // Set the video output delegate
        videoOutput.setSampleBufferDelegate(self, queue: queue)
    }
    
    // Capture a photo and call the completion handler
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
        capturedPhotoCompletion = completion
    }
    
    // Start the capture session in a background thread
    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    // Stop the capture session
    func stopSession() {
        session.stopRunning()
    }
    
    // Get the current capture session
    func getSession() -> AVCaptureSession {
        return session
    }
    
    // Request camera permission and handle result asynchronously
    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async {
                self.cameraPermissionGranted = true
                completion(true)
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.cameraPermissionGranted = granted
                    completion(granted)
                }
            }
        default:
            DispatchQueue.main.async {
                self.cameraPermissionGranted = false
                completion(false)
            }
        }
    }
    
    // Prepare the session based on camera permission
    func prepareSession() {
        if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
            cameraPermissionGranted = true
            configureAndStartSession()
        } else {
            requestCameraPermission { [weak self] granted in
                if granted {
                    self?.configureAndStartSession()
                } else {
                    print("Camera permission not granted.")
                }
            }
        }
    }
    
    // Configure and start capture session
    private func configureAndStartSession() {
        configureCaptureSession()
        startSession()
    }
    
    // Process each frame from the camera feed for text recognition
    func processFrame(sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try requestHandler.perform([textRequest])
        } catch {
            print("Error processing frame: \(error)")
        }
    }
    // Update the region of interest based on specified dimensions
    func updateROI(boxWidthPercentage: CGFloat, boxHeightPercentage: CGFloat) {
        let boxWidth = screenBounds.width * boxWidthPercentage
        let boxHeight = screenBounds.height * boxHeightPercentage
        let boxOriginX = (screenBounds.width - boxWidth) / 2
        let boxOriginY = (screenBounds.height - boxHeight) / 2
        regionOfInterest = CGRect(x: boxOriginX, y: boxOriginY, width: boxWidth, height: boxHeight)
        print("Region of Interest: \(regionOfInterest)")  // Debugging output
    }
    
    // Transform bounding box from normalized coordinates to screen coordinates
    func transformBoundingBox(_ boundingBox: CGRect) -> CGRect {
        let x = boundingBox.origin.x * screenBounds.width
        let y = (1.0 - boundingBox.origin.y - boundingBox.height) * screenBounds.height  // Invert y-axis
        let width = boundingBox.width * screenBounds.width
        let height = boundingBox.height * screenBounds.height
        let transformedRect = CGRect(x: x, y: y, width: width, height: height)
        print("Transformed Bounding Box: \(transformedRect)")  // Debugging output
        return transformedRect
    }
    // MARK: - Helper Functions for camera view:
     func retakePhoto() {
        resetState()
        resetPredictions()
        startSession()
    }
    
    
}

// Extensions for handling photo capture and video output
extension CameraViewModel: AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // Handle completion of photo capture
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil, let imageData = photo.fileDataRepresentation() else {
            print("Error capturing photo: \(error?.localizedDescription ?? "Unknown error")")
            capturedPhotoCompletion?(nil)
            return
        }
        
        let image = UIImage(data: imageData)
        capturedPhotoCompletion?(image)
        
        // Process text for allergens after photo capture
        let detectedTextArray = liveDetectedText.split(separator: " ").map { String($0) }
        processAllergensFromCapturedText(detectedTextArray)
    }
    
    // Continuously process video frames for text detection
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        processFrame(sampleBuffer: sampleBuffer)
    }
    

}


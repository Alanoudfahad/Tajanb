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

class CameraViewModel: NSObject, ObservableObject {
    
    // Published properties to notify UI of changes
    @Published var detectedText: [(category: String, word: String, hiddenSynonyms: [String])] = []
    @Published var availableCategories = [Category]()
    @Published var freeAllergenMessage: String?
    @Published var selectedWords = [String]()
    @Published var cameraPermissionGranted: Bool = false
    @Published var hasDetectedIngredients: Bool = false
    @Published var liveDetectedText: String = ""
    
    // Variables for tracking matched words and allergens
    var matchedWordsSet: Set<String> = []
    var foundAllergens = false
    
    // Private variables for camera session and outputs
    private var session: AVCaptureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var capturedPhotoCompletion: ((UIImage?) -> Void)?
    private let videoOutput = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "cameraQueue")  // Queue for video processing
    var textRequest = VNRecognizeTextRequest(completionHandler: nil)
    var hapticManager = HapticManager()
    private let screenBounds = UIScreen.main.bounds  // Screen bounds for bounding box calculation
    var regionOfInterest: CGRect = .zero
    
    override init() {
        super.init()
        loadCategories()  // Load category data on initialization
        configureTextRecognitions()  // Configure Vision request for text recognition
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
    
    // Load categories from JSON file based on language
    private func loadCategories() {
        let languageCode = Locale.current.language.languageCode?.identifier
        let fileName = languageCode == "ar" ? "categories_ar" : "categories_en"
        
        guard let path = Bundle.main.path(forResource: fileName, ofType: "json") else {
            print("Error finding \(fileName).json")
            return
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let decoder = JSONDecoder()
            availableCategories = try decoder.decode([Category].self, from: data)
            print("Loaded Categories: \(availableCategories)")  // Debugging output
        } catch {
            print("Error loading categories from JSON: \(error)")
        }
    }
    
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

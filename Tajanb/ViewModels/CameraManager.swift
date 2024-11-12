//
//  CameraManager.swift
//  Tajanb
//
//  Created by Afrah Saleh on 04/05/1446 AH.
//

import Foundation
import AVFoundation
import UIKit
import CoreImage
// Protocol defining delegate methods to handle camera output (photo or video frame)
protocol CameraManagerDelegate: AnyObject {
    func cameraManager(_ manager: CameraManager, didOutput sampleBuffer: CMSampleBuffer)
   func cameraManager(_ manager: CameraManager, didCapturePhoto image: UIImage?)
}

// Manages camera session, capturing photos and frames for real-time processing
class CameraManager: NSObject {
    weak var delegate: CameraManagerDelegate?
    
    private var session: AVCaptureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "cameraQueue")
    private var capturedPhotoCompletion: ((UIImage?) -> Void)?
    private var isFlashOn: Bool = false
    private var currentCameraPosition: AVCaptureDevice.Position = .back
    private var videoDeviceInput: AVCaptureDeviceInput?

    var videoDevice: AVCaptureDevice? {
        return (session.inputs.first as? AVCaptureDeviceInput)?.device
    }
    
    override init() {
        super.init()
        configureCaptureSession()
    }
    
    // MARK: - Camera functions
    
    // Configures the capture session with necessary inputs and outputs
    func configureCaptureSession() {
        session.beginConfiguration()
        if session.canSetSessionPreset(.hd4K3840x2160) {
            session.sessionPreset = .hd4K3840x2160
        } else if session.canSetSessionPreset(.hd1920x1080) {
            session.sessionPreset = .hd1920x1080
        } else if session.canSetSessionPreset(.hd1280x720) {
            session.sessionPreset = .hd1280x720
        } else {
            session.sessionPreset = .high
        }
        
        // Remove any existing input to avoid conflicts
        if let currentInput = session.inputs.first {
            session.removeInput(currentInput)
        }
        
        // Set up camera device and add as input to session
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
        
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }
        
        // Add video output for real-time frame capture
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        // Add photo output for capturing still photos
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        
        
        session.commitConfiguration()  // Commit all configuration changes
        
        // Configure camera for continuous focus and exposure adjustment
        do {
            try videoDevice.lockForConfiguration()
            
            if videoDevice.isFocusModeSupported(.continuousAutoFocus) {
                videoDevice.focusMode = .continuousAutoFocus
            }
            if videoDevice.isExposureModeSupported(.continuousAutoExposure) {
                videoDevice.exposureMode = .continuousAutoExposure
            }
            if videoDevice.isExposureModeSupported(.custom) {
                let exposureDuration = CMTime(value: 1, timescale: 70) // 1/60s exposure time (good for typical lighting conditions)
                let iso = max(videoDevice.activeFormat.minISO, min(videoDevice.activeFormat.maxISO, AVCaptureDevice.currentISO))
                videoDevice.setExposureModeCustom(duration: exposureDuration, iso: iso, completionHandler: nil)
            }
            
            videoDevice.unlockForConfiguration()
        } catch {
            print("Error configuring camera: \(error)")
        }
        
        // Set the video output delegate to handle each video frame
        videoOutput.setSampleBufferDelegate(self, queue: queue)
    }
    
    func toggleFlash(isOn: Bool) {
        guard let device = videoDevice else { return }
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                if isOn {
                    try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
                    self.isFlashOn = true
                } else {
                    device.torchMode = .off
                    self.isFlashOn = false
                }
                device.unlockForConfiguration()
            } catch {
                print("Error setting torch: \(error)")
            }
        }
    }
    
    // Adjust the zoom factor dynamically
    func setZoomFactor(_ factor: CGFloat) {
        guard let device = videoDevice else { return }
        let zoomFactor = max(min(factor, device.activeFormat.videoMaxZoomFactor), 1.0)
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = zoomFactor
                device.unlockForConfiguration()
            } catch {
                print("Failed to set zoom factor: \(error)")
            }
        }
    }
    
    // Capture a still photo and call the completion handler with the captured image
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
        capturedPhotoCompletion = completion  // Store the completion handler
    }
    
    // Start the camera session asynchronously on a background thread
    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    // Stop the camera session
    func stopSession() {
        session.stopRunning()
    }
    
    // Get the current session
    func getSession() -> AVCaptureSession {
        return session
    }
    
    // Request permission to access the camera
    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async {
                completion(true)
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        default:
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }
    
    // Prepare the session by configuring it and starting it if permissions are granted
    func prepareSession() {
        if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
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
    
    // Helper function to configure and start the session if permissions are granted
    private func configureAndStartSession() {
        configureCaptureSession()
        startSession()
    }
    
    // Process captured image for better text recognition
    func processCapturedImageForTextRecognition(_ image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        let context = CIContext()
        
        // Sharpen the image
        guard let sharpenFilter = CIFilter(name: "CISharpenLuminance") else { return nil }
        sharpenFilter.setValue(ciImage, forKey: kCIInputImageKey)
        sharpenFilter.setValue(2.0, forKey: kCIInputIntensityKey)
        let sharpenedImage = sharpenFilter.outputImage!
        
        // Adjust contrast for better readability
        guard let contrastFilter = CIFilter(name: "CIColorControls") else { return nil }
        contrastFilter.setValue(sharpenedImage, forKey: kCIInputImageKey)
        contrastFilter.setValue(1.6, forKey: kCIInputContrastKey)
        let contrastAdjustedImage = contrastFilter.outputImage!
        
        // Apply noise reduction
        guard let noiseReductionFilter = CIFilter(name: "CINoiseReduction") else { return nil }
        noiseReductionFilter.setValue(contrastAdjustedImage, forKey: kCIInputImageKey)
        noiseReductionFilter.setValue(0.8, forKey: "inputNoiseLevel")
        let noiseReducedImage = noiseReductionFilter.outputImage!
        
        // Convert back to UIImage
        if let cgImage = context.createCGImage(noiseReducedImage, from: noiseReducedImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
}




extension CameraManager: AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // Handle completion of photo capture and call the delegate with the captured image
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil, let imageData = photo.fileDataRepresentation() else {
            print("Error capturing photo: \(error?.localizedDescription ?? "Unknown error")")
            capturedPhotoCompletion?(nil)
            delegate?.cameraManager(self, didCapturePhoto: nil)
            return
        }
        
        // Convert captured data to UIImage and call the completion handler
        let image = UIImage(data: imageData)
        capturedPhotoCompletion?(image)
        
        delegate?.cameraManager(self, didCapturePhoto: image)
    }
    
    // Continuously process video frames and pass them to the delegate for real-time analysis
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = isFlashOn ? .on : .off  // Set flash mode
        delegate?.cameraManager(self, didOutput: sampleBuffer)
    }
}

//
//  PhotoViewModel.swift
//  Tajanb
//
//  Created by Alanoud Alshuaibi on 19/04/1446 AH.
//

import Foundation
import Vision
import UIKit
import Photos

class PhotoViewModel: NSObject, ObservableObject {
    @Published var detectedText: [(category: String, word: String, hiddenSynonyms: [String])] = []
    private var textRequest = VNRecognizeTextRequest(completionHandler: nil)
    private var hapticManager = HapticManager()
    var ViewModel: CameraViewModel
    private var matchedWordsSet: Set<String> = [] // To keep track of matched words

    init(viewmodel: CameraViewModel) {
        self.ViewModel = viewmodel
        super.init()
        configureTextRecognition()
    }

    private func configureTextRecognition() {
        textRequest = VNRecognizeTextRequest { [weak self] (request, error) in
            guard let self = self else { return }

            if let error = error {
                print("Error recognizing text: \(error.localizedDescription)")
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                print("No recognized text found")
                return
            }

            let detectedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
            DispatchQueue.main.async {
                self.processDetectedText(detectedStrings)
            }
        }

        textRequest.recognitionLevel = .accurate
        textRequest.recognitionLanguages = ["ar", "ar-SA", "ar-AE"]
        textRequest.usesLanguageCorrection = true
    }

    func startTextRecognition(from image: UIImage) {
        guard let cgImage = image.cgImage else {
            print("Failed to convert UIImage to CGImage")
            return
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([textRequest])
        } catch {
            print("Failed to perform text recognition request: \(error.localizedDescription)")
        }
    }

    private func processDetectedText(_ detectedStrings: [String]) {
        let combinedText = detectedStrings.joined(separator: " ")
        let cleanedText = ViewModel.preprocessText(combinedText)

        print("Detected Combined Text: \(cleanedText)")

        // Split the cleaned text into words and check against selected words
        let words = cleanedText.split(separator: " ").map { $0.trimmingCharacters(in: .punctuationCharacters).lowercased() }
        print("Detected Words List: \(words)")

        for word in words {
            checkAllergy(for: word)
        }
    }

    private func checkAllergy(for word: String) {
        let cleanedWord = word.trimmingCharacters(in: .punctuationCharacters).lowercased() // Clean the word

        if let result = ViewModel.isTargetWord(cleanedWord) {
            // Check if this word has already been detected to avoid duplicates
            if !matchedWordsSet.contains(cleanedWord) {
                // Check if the detected word matches a selected allergen
                if ViewModel.selectedWords.contains(result.1) {
                    DispatchQueue.main.async {
                        self.detectedText.append((category: result.0, word: result.1, hiddenSynonyms: result.2))
                        
                        // Perform haptic feedback only if the detected word matches a selected allergen
                        self.hapticManager.performHapticFeedback()
                        
                        self.matchedWordsSet.insert(cleanedWord)
                    }
                }
            }
        } else {
            // Remove the word from the matched set if no longer matching
            matchedWordsSet.remove(cleanedWord)
        }
    }

    // Method to reset detected text and matched words
    func resetPredictions() {
        detectedText.removeAll() // Clear the existing predictions
        matchedWordsSet.removeAll() // Clear matched words set
    }

    // Request access to photo library
    func requestPhotoLibraryAccess() {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("Photo library access granted.")
                case .denied, .restricted:
                    print("Photo library access denied or restricted.")
                case .notDetermined:
                    print("Photo library access not determined.")
                case .limited:
                    print("Photo library access granted with limitations.")
                @unknown default:
                    print("Unknown photo library access status.")
                }
            }
        }
    }
}

//
//  CameraViewModel.swift
//  Text_Detection
//
//  Created by Afrah Saleh on 11/03/1446 AH.
//

import Foundation
import AVFoundation
import Vision
import CoreHaptics
import SwiftData
import SwiftUICore
import UIKit

class CameraViewModel: NSObject, ObservableObject {

    @Published var detectedText: [(category: String, word: String, hiddenSynonyms: [String])] = []
    @Published var availableCategories = [Category]()
    @Published var freeAllergenMessage: String?
    private var hapticManager = HapticManager()
    @Published var selectedWords = [String]()

    @Published var cameraPermissionGranted: Bool = false
    private var textRequest = VNRecognizeTextRequest(completionHandler: nil)
    private var session: AVCaptureSession!
    private var searchTimer: Timer? // Timer for delayed search
    // Region of Interest (ROI) for text detection
     private var regionOfInterest: CGRect = .zero
     private let screenBounds = UIScreen.main.bounds
    override init() {
        super.init()
        loadCategories()
        configureCaptureSession()
        configureTextRecognition()
    }
    
    func updateROI(boxWidthPercentage: CGFloat, boxHeightPercentage: CGFloat) {
           // Calculate the Region of Interest (ROI) in terms of screen coordinates
           let boxWidth = screenBounds.width * boxWidthPercentage
           let boxHeight = screenBounds.height * boxHeightPercentage
           let boxOriginX = (screenBounds.width - boxWidth) / 2
           let boxOriginY = (screenBounds.height - boxHeight) / 2
           
           regionOfInterest = CGRect(x: boxOriginX, y: boxOriginY, width: boxWidth, height: boxHeight)
           print("ROI updated to: \(regionOfInterest)")
       }
    
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
            print("Loaded Categories: \(availableCategories)")
        } catch {
            print("Error loading categories from JSON: \(error)")
        }
    }

    func saveSelectedWords(using modelContext: ModelContext) {
               let fetchDescriptor = FetchDescriptor<SelectedWord>()
               if let existingWords = try? modelContext.fetch(fetchDescriptor) {
                   for word in existingWords {
                       modelContext.delete(word)
                   }
               }

               for word in selectedWords {
                   let newWord = SelectedWord(word: word)
                   modelContext.insert(newWord)
               }

               try? modelContext.save()
           }

           func loadSelectedWords(using modelContext: ModelContext) {
               let fetchDescriptor = FetchDescriptor<SelectedWord>()
               if let savedWordsData = try? modelContext.fetch(fetchDescriptor) {
                   selectedWords = savedWordsData.map { $0.word }
               } else {
                   selectedWords = []
               }
           }

           func updateSelectedWords(with words: [String], using modelContext: ModelContext) {
               selectedWords = words
               saveSelectedWords(using: modelContext)
               print("Selected words updated: \(selectedWords)")
           }
    
    private func configureCaptureSession() {
        session = AVCaptureSession()
        session.sessionPreset = .hd1280x720  // Use a lower resolution to improve performance and accuracy.

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }

        session.addInput(videoInput)

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "cameraQueue"))
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        session.addOutput(videoOutput)

        do {
            try videoDevice.lockForConfiguration()

            // Enable continuous auto-focus for a stable focus
            if videoDevice.isFocusModeSupported(.continuousAutoFocus) {
                videoDevice.focusMode = .continuousAutoFocus
            }

            // Enable auto-exposure for better lighting conditions
            if videoDevice.isExposureModeSupported(.continuousAutoExposure) {
                videoDevice.exposureMode = .continuousAutoExposure
            }

            // Improve stability by reducing motion blur (limit frame rate)
            if videoDevice.activeVideoMinFrameDuration.seconds > 0 {
                videoDevice.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 30) // 30 fps
            }

            videoDevice.unlockForConfiguration()
        } catch {
            print("Error configuring camera: \(error)")
        }
    }

    private func configureTextRecognition() {
          textRequest = VNRecognizeTextRequest { [weak self] request, error in
              guard let self = self else { return }

              if let error = error {
                  print("Error recognizing text: \(error)")
                  return
              }

              guard let observations = request.results as? [VNRecognizedTextObservation] else {
                  return
              }

              let filteredObservations = observations.filter { observation in
                  // Project the bounding box of detected text from the camera feed into screen coordinates
                  let transformedBoundingBox = self.transformBoundingBox(observation.boundingBox)
                  // Check if the transformed bounding box intersects with the region of interest
                  return self.regionOfInterest.intersects(transformedBoundingBox)
              }

              let detectedStrings = filteredObservations.compactMap { $0.topCandidates(1).first?.string }
              DispatchQueue.main.async {
                  self.processDetectedText(detectedStrings)
              }
          }

          textRequest.recognitionLevel = .accurate
          textRequest.recognitionLanguages = ["ar", "en"]
          textRequest.usesLanguageCorrection = true
          textRequest.minimumTextHeight = 0.01  // Increase this slightly to avoid detecting very small text/noise.
      }
    private func transformBoundingBox(_ boundingBox: CGRect) -> CGRect {
           // Convert the bounding box from normalized coordinates to screen coordinates
           let x = boundingBox.origin.x * screenBounds.width
           let y = (1 - boundingBox.origin.y) * screenBounds.height // Invert y-axis
           let width = boundingBox.width * screenBounds.width
           let height = boundingBox.height * screenBounds.height
           return CGRect(x: x, y: y - height, width: width, height: height)
       }

    func processDetectedText(_ detectedStrings: [String]) {
          let combinedText = detectedStrings.joined(separator: " ")
          let cleanedText = preprocessText(combinedText)
          
          print("Detected Combined Text: \(cleanedText)")
          
          // First, attempt an immediate search without "المكونات"
          if searchImmediateIngredients(in: cleanedText) {
              searchTimer?.invalidate() // Cancel any existing timer if we find matches
              
          } else {
              // If no immediate match, start a delayed search with "المكونات"
              searchTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
                  self?.searchDelayedIngredients(in: cleanedText)
              }
          }
      }
      
      // Immediate search for ingredients without "المكونات"
      private func searchImmediateIngredients(in text: String) -> Bool {
          let ingredientsDetected = extractAndProcessIngredients(from: text, keyword: "")
          if !ingredientsDetected.isEmpty {
              freeAllergenMessage = nil // Clear message if ingredients are found
              return true
          }
          return false
      }
      
      // Delayed search with "المكونات" after 5 seconds
    private func searchDelayedIngredients(in text: String) {
        // Define the keyword based on the current locale
        let keyword = Locale.current.language.languageCode == "ar" ? "المكونات" : "ingredients"
        
        // Check if the keyword exists in the detected text
        if fuzzyContains(text, keyword: keyword) {
            // Attempt to extract ingredients after the keyword
            let ingredientsDetected = extractAndProcessIngredients(from: text, keyword: keyword)
            
            // If no ingredients were detected, show the free allergen message
            if ingredientsDetected.isEmpty {
                freeAllergenMessage = getLocalizedMessage()  // Show the "free allergens" message
                print("No relevant ingredients found after '\(keyword)'. Showing free allergen message.")
            } else {
                freeAllergenMessage = nil  // Clear the message if ingredients are found
                print("Ingredients found: \(ingredientsDetected). No free allergen message.")
            }
        } else {
            // If the keyword is not found, clear the free allergen message
            freeAllergenMessage = nil
            print("Keyword '\(keyword)' not found in the text.")
        }
    }
      
    private func extractAndProcessIngredients(from text: String, keyword: String) -> [String] {
        guard let range = text.range(of: keyword, options: [.caseInsensitive, .diacriticInsensitive])?.upperBound else {
            print("Keyword '\(keyword)' not found.")
            return []
        }
        
        // Extract text after the keyword
        let ingredientsText = String(text[range...]).trimmingCharacters(in: .whitespaces)
        print("Extracted text after '\(keyword)': \(ingredientsText)")
        
        // Split the extracted text into ingredients
        let ingredients = ingredientsText.components(separatedBy: CharacterSet(charactersIn: ",، "))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }  // Trim spaces and newlines
            .filter { !$0.isEmpty }  // Remove empty entries
        
        // Filter ingredients to include only those that match the user's selected allergens
        let filteredIngredients = ingredients.filter { isSelectedWord($0) }
        
        // Log the final detected ingredients
        print("Filtered ingredients: \(filteredIngredients)")
        
        // Update the detected ingredients (for further processing or UI updates)
        updateDetectedIngredients(filteredIngredients)
        
        return filteredIngredients
    }
    func isTargetWord(_ text: String) -> (String, String, [String])? {
        let lowercasedText = text.lowercased()
        for category in availableCategories {
            for word in category.words {
                if word.word.lowercased() == lowercasedText ||
                   word.hiddenSynonyms?.contains(where: { $0.lowercased() == lowercasedText }) == true {
                    let synonyms = word.hiddenSynonyms ?? []
                    return (category.name, word.word, synonyms)
                }
            }
        }
        return nil
    }

    // Assuming 'selectedWords' is a list of user-selected allergens
    private func isSelectedWord(_ word: String) -> Bool {
        // Check if the word is in the list of selected allergens
        let isMatch = selectedWords.contains { selectedWord in
            // Use case-insensitive and diacritic-insensitive comparison
            return word.compare(selectedWord, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
        
        // Log the result for debugging
        print("Ingredient '\(word)' is a selected word: \(isMatch)")
        
        return isMatch
    }

    func preprocessText(_ text: String) -> String {
        var cleanedText = text
            .replacingOccurrences(of: "\n", with: " ")  // Replace newlines with space
            .replacingOccurrences(of: "-", with: " ")   // Replace hyphens with space
            .replacingOccurrences(of: "[^\\p{L}\\p{Z}]", with: " ", options: .regularExpression)  // Remove non-letters and non-spaces
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)  // Replace multiple spaces with a single space
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Fix common OCR mistakes (e.g., "االمكونات" -> "المكونات")
        cleanedText = cleanedText.replacingOccurrences(of: "االمكونات", with: "المكونات")
        
        return cleanedText.applyingTransform(.stripCombiningMarks, reverse: false) ?? cleanedText
    }

    func fuzzyContains(_ text: String, keyword: String) -> Bool {
        // Build a pattern that allows the keyword to be surrounded by non-letter characters or spaces
        let pattern = "\\b\(keyword)\\b"
        
        // Search for the keyword using case insensitivity and diacritic insensitivity
        let result = text.range(of: pattern, options: [.regularExpression, .caseInsensitive, .diacriticInsensitive]) != nil
        print("Fuzzy match for keyword '\(keyword)': \(result)")  // Log the result
        return result
    }

    private func getLocalizedMessage() -> String {
        return Locale.current.language.languageCode == "ar" ? "خالي من مسببات الحساسيه" : "Free allergens"
    }

    private func updateDetectedIngredients(_ ingredients: [String]) {
        let targetWords = ingredients.compactMap { ingredient -> (String, String, [String])? in
            if let (category, word, hiddenSynonyms) = isTargetWord(ingredient) {
                // Only include words that are still selected by the user
                if selectedWords.contains(word) {
                    return (category, word, hiddenSynonyms)
                }
            }
            return nil
        }

        // Avoid performing haptic feedback if no ingredients are detected
        if !detectedText.elementsEqual(targetWords, by: { $0 == $1 }) {
            detectedText = targetWords
            print("Updated Detected Ingredients: \(detectedText)")
            
            // Perform haptic feedback only if detected text is not empty
            if !targetWords.isEmpty {
                hapticManager.performHapticFeedback()
            }
        }
    }

    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

    func stopSession() {
        session.stopRunning()
    }

    func getSession() -> AVCaptureSession {
        return session
    }
}

extension CameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try requestHandler.perform([textRequest])
        } catch {
            print("Failed to perform text recognition request: \(error)")
        }
    }
}
//
//    private func saveSelectedWords() {
//        UserDefaults.standard.set(selectedWords, forKey: "selectedWords")
//    }
//
//    func updateSelectedWords(with words: [String]) {
//        selectedWords = words
//        UserDefaults.standard.set(words, forKey: "selectedWords")
//        print("Selected words updated: \(selectedWords)")
//    }
//
//    func loadSelectedWords() {
//        if let savedWords = UserDefaults.standard.array(forKey: "selectedWords") as? [String] {
//            selectedWords = savedWords
//        }
//    }

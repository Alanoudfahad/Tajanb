import Foundation
import Vision
import UIKit

class PhotoViewModel: NSObject, ObservableObject {
    @Published var detectedText: [(category: String, word: String, hiddenSynonyms: [String])] = []
    private var textRequest = VNRecognizeTextRequest(completionHandler: nil)
    private var hapticManager = HapticManager()
    var categoryManager: CategoryManagerViewModel
    private var matchedWordsSet: Set<String> = [] // To keep track of matched words

    init(categoryManager: CategoryManagerViewModel) {
        self.categoryManager = categoryManager
        super.init()
        configureTextRecognition()
    }

    private func configureTextRecognition() {
        textRequest = VNRecognizeTextRequest { [weak self] (request, error) in
            guard let self = self else { return }

            if let error = error {
                print("Error recognizing text: \(error)")
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
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
            print("Failed to perform text recognition request: \(error)")
        }
    }

    private func processDetectedText(_ detectedStrings: [String]) {
        let combinedText = detectedStrings.joined(separator: " ")
        let cleanedText = categoryManager.preprocessText(combinedText)

        // Split the cleaned text into words and check against allergies
        let words = cleanedText.split(separator: " ").map(String.init)
        for word in words {
            checkAllergy(for: word)
        }
    }

    private func checkAllergy(for word: String) {
        // Use the CategoryManager to check for target words
        if let result = categoryManager.isTargetWord(word) {
            // Check if this word has already triggered haptic feedback
            if !matchedWordsSet.contains(word) {
                DispatchQueue.main.async {
                    self.detectedText.append((category: result.0, word: result.1, hiddenSynonyms: result.2))
                    // Trigger haptic feedback after adding the prediction
                    self.hapticManager.performHapticFeedback()
                    print("Matched word: \(word) in category: \(result.0)")

                    // Add the word to the set to prevent duplicate feedback
                    self.matchedWordsSet.insert(word)
                }
            }
        } else {
            // If the word is not matched, remove it from the set (if it exists)
            matchedWordsSet.remove(word)
        }
    }

    // New method to reset detected text and matched words
    func resetPredictions() {
        detectedText.removeAll() // Clear the existing predictions
        matchedWordsSet.removeAll() // Clear matched words set
    }
}

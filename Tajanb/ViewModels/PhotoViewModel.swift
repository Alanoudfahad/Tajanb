import Foundation
import Vision
import UIKit
import Photos
class PhotoViewModel: NSObject, ObservableObject {
    @Published var detectedText: [(category: String, word: String, hiddenSynonyms: [String])] = []
    @Published var freeAllergenMessage: String?
    private var textRequest = VNRecognizeTextRequest(completionHandler: nil)
    private var hapticManager = HapticManager()
    var ViewModel: CameraViewModel
    private var matchedWordsSet: Set<String> = []

    private let ingredientKeywords = [
        "المكونات", "مكونات", "مواد", "عناصر", "المحتويات", "محتويات", "تركيبة",
        "تركيب", "خليط", "تركيبات", "مواد خام", "مكونات الغذاء",
        "مكونات المنتج", "Ingredients", "Contents", "Composition",
        "Components", "Formula", "Constituents", "Mixture", "Blend",
        "Ingredients List", "Product Ingredients", "Food Ingredients",
        "Raw Materials"
    ]

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
        textRequest.recognitionLanguages = ["ar", "en"]
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

        // Check for language mismatch
        checkLanguageAndPrompt(detectedText: cleanedText)
        if freeAllergenMessage != nil {
            return
        }

        let words = cleanedText.split(separator: " ").map { $0.trimmingCharacters(in: .punctuationCharacters).lowercased() }
        print("Detected Words List: \(words)")

        var foundAllergens = false
        let maxPhraseLength = 4
        let N = words.count

        for i in 0..<N {
            for L in 1...maxPhraseLength where i + L <= N {
                let phrase = words[i..<i+L].joined(separator: " ")
                if checkAllergy(for: phrase) {
                    foundAllergens = true
                }
            }
        }

        if !foundAllergens {
            if ingredientKeywords.contains(where: { fuzzyContains(cleanedText, keyword: $0) }) {
                freeAllergenMessage = getLocalizedMessage()
            } else {
                freeAllergenMessage = Locale.current.language.languageCode == "ar" ?
                    "عذرًا، لم يتم العثور على مكونات. حاول مرة أخرى." :
                    "Sorry, no ingredients found. Please try again."
            }
        } else {
            freeAllergenMessage = nil
        }
    }


    private func checkLanguageAndPrompt(detectedText: String) {
        let arabicCode = "ar"
        let englishCode = "en"
        let currentLanguageCode = Locale.current.language.languageCode?.identifier ?? ""

        // Check if the detected text contains Arabic characters
        let containsArabic = detectedText.range(of: "\\p{Arabic}", options: .regularExpression) != nil

        // Check if the detected text contains English ingredient keywords
        let containsEnglishIngredients = ingredientKeywords.contains { keyword in
            keyword.range(of: "^[a-zA-Z\\s]+$", options: .regularExpression) != nil && fuzzyContains(detectedText, keyword: keyword)
        }

        // Check if the detected text contains Arabic ingredient keywords
        let containsArabicIngredients = ingredientKeywords.contains { keyword in
            keyword.range(of: "^[\\p{Arabic}\\s]+$", options: .regularExpression) != nil && fuzzyContains(detectedText, keyword: keyword)
        }

        // Only check for language mismatch when the app language is Arabic or English
        if currentLanguageCode == arabicCode {
            // If the app language is Arabic but the detected text has English ingredients, prompt user
            if containsEnglishIngredients && !containsArabicIngredients {
                freeAllergenMessage = "يرجى تغيير لغة التطبيق إلى الإنجليزية للحصول على نتائج أفضل."
            } else {
                freeAllergenMessage = nil
            }
        } else if currentLanguageCode == englishCode {
            // If the app language is English but the detected text has Arabic ingredients, prompt user
            if containsArabicIngredients && !containsEnglishIngredients {
                freeAllergenMessage = "Please change the app language to Arabic for better results."
            } else {
                freeAllergenMessage = nil
            }
        } else {
            // Clear the message if the app language is neither Arabic nor English
            freeAllergenMessage = nil
        }
    }
    private func getLocalizedMessage() -> String {
        return Locale.current.language.languageCode == "ar" ?
            "بناءً على الصورة، المنتج خالٍ من المواد المسببة للحساسية." :
            "Based on the picture, product is Allergen free."
    }

    func fuzzyContains(_ text: String, keyword: String) -> Bool {
        let pattern = "\\b\(keyword)\\b"
        return text.range(of: pattern, options: [.regularExpression, .caseInsensitive, .diacriticInsensitive]) != nil
    }


    // Reset detected text and clear matched words
    func resetPredictions() {
        detectedText.removeAll()  // Clear detected allergen list
        matchedWordsSet.removeAll()  // Clear matched words
        freeAllergenMessage = getLocalizedMessage()  // Reset to allergen-free message
    }

    // Request access to the photo library
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

    // Check and prompt if the language of the detected text doesn't match the app's language
//    private func checkLanguageAndPrompt(detectedText: String) {
//        let arabicCode = "ar"
//        let englishCode = "en"
//
//        // Get the current app language code
//        let currentLanguageCode = Locale.current.language.languageCode?.identifier ?? ""
//        let containsArabic = detectedText.range(of: "\\p{Arabic}", options: .regularExpression) != nil
//
//        // Set the message for a language mismatch
//        if containsArabic && currentLanguageCode != arabicCode {
//            freeAllergenMessage = currentLanguageCode == arabicCode
//                ? "يرجى تغيير لغة التطبيق إلى العربية للحصول على نتائج أفضل."
//                : "Please change the app language to Arabic for better results."
//        } else if !containsArabic && currentLanguageCode != englishCode {
//            freeAllergenMessage = currentLanguageCode == arabicCode
//                ? "يرجى تغيير لغة التطبيق إلى الإنجليزية للحصول على نتائج أفضل."
//                : "Please change the app language to English for better results."
//        } else {
//            freeAllergenMessage = nil  // Clear the message if no mismatch
//        }
//    }
    private func checkAllergy(for phrase: String) -> Bool {
          let cleanedPhrase = phrase.trimmingCharacters(in: .punctuationCharacters).lowercased()

          if let result = ViewModel.isTargetWord(cleanedPhrase), !matchedWordsSet.contains(cleanedPhrase) {
              if ViewModel.selectedWordsViewModel.selectedWords.contains(result.1) {
                  DispatchQueue.main.async {
                      self.detectedText.append((category: result.0, word: result.1, hiddenSynonyms: result.2))
                      self.hapticManager.performHapticFeedback()
                      self.matchedWordsSet.insert(cleanedPhrase)
                  }
                  return true
              }
          }
          return false
      }
}

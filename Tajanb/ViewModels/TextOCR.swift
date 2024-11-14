//
//  TextOCR.swift
//  Tajanb
//
//  Created by Afrah Saleh on 11/05/1446 AH.
//

import Foundation

extension CameraViewModel{
    
    func preprocessText(_ text: String) -> String {
        var cleanedText = text
            .replacingOccurrences(of: "\n", with: " ")  // Replace newline characters with spaces
            .replacingOccurrences(of: "-", with: " ")  // Replace hyphens with spaces (common OCR artifact)
            .replacingOccurrences(of: "[^\\p{L}\\p{Z}]", with: " ", options: .regularExpression)  // Remove non-alphabetic characters
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)  // Reduce multiple spaces to a single space
            .trimmingCharacters(in: .whitespacesAndNewlines)  // Trim leading/trailing whitespaces
            .applyingTransform(.stripCombiningMarks, reverse: false) ?? text  // Remove diacritics

            // Normalize Arabic characters with or without dots
            .replacingOccurrences(of: "أ", with: "ا")  // Normalize alif with hamza to alif
            .replacingOccurrences(of: "إ", with: "ا")  // Normalize alif with hamza below to alif
            .replacingOccurrences(of: "آ", with: "ا")  // Normalize alif with madda to alif
            .replacingOccurrences(of: "ء", with: "ا")  // Normalize hamza alone to alif
            .replacingOccurrences(of: "ى", with: "ي")  // Final ya to normal ya
            .replacingOccurrences(of: "ة", with: "ه")  // Replace ta marbuta (final form) with ha
            .replacingOccurrences(of: "و", with: "و")  // No change needed for waw
            .replacingOccurrences(of: "ز", with: "ز")  // No change needed for zay
            .replacingOccurrences(of: "ر", with: "ر")  // No change needed for ra
            .replacingOccurrences(of: "ل", with: "ل")  // No change needed for lam
            .replacingOccurrences(of: "م", with: "م")  // No change needed for meem
            .replacingOccurrences(of: "ن", with: "ن")  // No change needed for noon
            .replacingOccurrences(of: "ه", with: "ه")  // No change needed for heh
            .replacingOccurrences(of: "و", with: "و")  // No change needed for waw

            // Normalize letters with dots (1, 2, 3 dots)
            .replacingOccurrences(of: "ب", with: "ب")  // Beh (1 dot below)
            .replacingOccurrences(of: "ت", with: "ت")  // Teh (2 dots above)
            .replacingOccurrences(of: "ث", with: "ث")  // Theh (3 dots above)
            .replacingOccurrences(of: "ج", with: "ج")  // Jeem (1 dot below)
            .replacingOccurrences(of: "ح", with: "ح")  // Hhaa (no dots)
            .replacingOccurrences(of: "خ", with: "خ")  // Khaa (1 dot above)
            .replacingOccurrences(of: "د", with: "د")  // Dal (no dots)
            .replacingOccurrences(of: "ذ", with: "ذ")  // Dhal (1 dot above)
            .replacingOccurrences(of: "ش", with: "ش")  // Sheen (3 dots above)
            .replacingOccurrences(of: "ص", with: "ص")  // Saad (no dots)
            .replacingOccurrences(of: "ض", with: "ض")  // Daad (1 dot above)
            .replacingOccurrences(of: "ط", with: "ط")  // Taa (no dots)
            .replacingOccurrences(of: "ظ", with: "ظ")  // Thaa (1 dot above)
            .replacingOccurrences(of: "ع", with: "ع")  // Ain (no dots)
            .replacingOccurrences(of: "غ", with: "غ")  // Ghain (1 dot above)
            .replacingOccurrences(of: "ف", with: "ف")  // Feh (1 dot above)
            .replacingOccurrences(of: "ق", with: "ق")  // Qaf (1 dot above)
            .replacingOccurrences(of: "ك", with: "ك")  // Kaf (no dots)
            .replacingOccurrences(of: "ي", with: "ي")  // Yeh (1 dot below)

            // Handle other common punctuation issues
            .replacingOccurrences(of: "٫", with: " ") // Arabic comma
            .replacingOccurrences(of: "۔", with: " ") // Arabic full stop
            .replacingOccurrences(of: "٬", with: ",") // Arabic comma to standard comma
            .replacingOccurrences(of: "؟", with: "?") // Arabic question mark
            .replacingOccurrences(of: "ـ", with: " ") // Remove tatweel (used for stretching text)

            // Normalize numbers and special characters
            .replacingOccurrences(of: "٠", with: "0")
            .replacingOccurrences(of: "١", with: "1")
            .replacingOccurrences(of: "٢", with: "2")
            .replacingOccurrences(of: "٣", with: "3")
        
        return cleanedText.lowercased()  // Convert to lowercase for consistency
    }
    
    // Helper for fuzzy matching keywords in text
    func fuzzyContains(_ text: String, keyword: String) -> Bool {
        let pattern = "\\b\(keyword)\\b"
        return text.range(of: pattern, options: [.regularExpression, .caseInsensitive, .diacriticInsensitive]) != nil
    }



    // Get localized allergen-free message
     func getLocalizedMessage() -> String {
        return Locale.current.language.languageCode  == "ar" ? "بناءً على الصورة، المنتج خالٍ من المواد المسببة للحساسية." : "Based on the picture, product is Allergen free"
    }
    
    
    
    // MARK: - Camera View Helper Functions
    
    // Reset predictions and clear stored matches
    func resetPredictions() {
        detectedText.removeAll()
        matchedWordsSet.removeAll()
        cameraManager.toggleFlash(isOn: false)
    }
    
    // Allow retaking photo and restart camera session
    func retakePhoto() {
        resetState()
        resetPredictions()
        cameraManager.startSession()
        cameraManager.toggleFlash(isOn: false)
    }
    
    // Reset detected text and flags
    func resetState() {
        DispatchQueue.main.async {
            self.detectedText = []
            self.freeAllergenMessage = nil
            self.hasDetectedIngredients = false
            self.foundAllergens = false
            self.matchedWordsSet.removeAll()
            self.liveDetectedText = ""
        }
    }
    
}

//
//  UserSuggestionView.swift
//  Tajanb
//
//  Created by Afrah Saleh on 01/05/1446 AH.
//

import SwiftUI
import Firebase

struct UserSuggestionView: View {
    @ObservedObject var viewModel: CameraViewModel
    @State private var suggestionText: String = ""
    @State private var showAlert = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background color for the entire sheet
            Color("CustomBackground")
                .edgesIgnoringSafeArea(.all) // Ensures the color extends beyond safe area
            
            VStack(spacing: 40) {
                
                Capsule()
                    .fill(Color("SecondaryButton"))
                    .frame(width: 80, height: 4)
                    .padding(.bottom,30)
                
                VStack( alignment: .leading ,spacing: 5 ){
                Text("Your Suggestion")
                    .font(.headline)
                    .padding(.top, 20)
                    .foregroundColor(.white)
                   // .padding(.trailing,220)
                
                TextField("Enter your suggestion here", text: $suggestionText)
                    .padding() // Add padding inside the text field
                    .background(Color.white) // Background color for readability
                    .cornerRadius(8) // Rounded corners
                    .frame(height: 70) // Increase height for a larger text area
            }
                
                
                Button(action: {
                    viewModel.firestoreViewModel.saveSuggestion(suggestionText) { result in
                        switch result {
                        case .success:
                            showAlert = true  // Trigger the alert
                        case .failure(let error):
                            print("Error saving suggestion: \(error.localizedDescription)")
                        }
                    }
                }) {
                    Text("Send")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("PrimeryButton"))
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                }
                .disabled(suggestionText.isEmpty)
                .padding(.top, 10)
            }
            .padding()
            .padding(.bottom, 50)

        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Thank You!"),
                message: Text("We received your suggestion, and its under review."),
                dismissButton: .default(Text("OK")) {
                    dismiss() // Dismiss the sheet when "OK" is pressed
                }
            )
        }
    }
}

#Preview {
    UserSuggestionView(viewModel: CameraViewModel())
}

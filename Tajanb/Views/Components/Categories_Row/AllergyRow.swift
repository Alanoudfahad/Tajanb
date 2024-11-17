//
//  AllergyRow.swift
//  Tajanb
//
//  Created by Afrah Saleh on 01/05/1446 AH.
//
import SwiftUI

struct AllergyRow: View {
    var icon: String
    var text: String

    var body: some View {
        HStack {
            Text(icon)
                .font(.system(size: 20)) // Reduced font size for the icon
                .padding(.trailing, 6)   // Reduced trailing padding
            Text(text)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(15)                     // Reduced overall padding
        .background(Color("GrayList"))
        .cornerRadius(8)                 // Reduced corner radius
        .accessibilityElement()
        .accessibilityLabel("\(text) category")
        .accessibilityHint("Double-tap to view details.")
    }
}

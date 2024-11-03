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
                .font(.system(size: 24))
                .padding(.trailing, 8)
            Text(text)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color("GrayList"))
        .cornerRadius(10)
        .accessibilityElement()
        .accessibilityLabel("\(text) category")
        .accessibilityHint("Double-tap to view details.")
    }
}

//
//  SearchBar.swift
//  Tajanb
//
//  Created by Alanoud Alshuaibi on 12/05/1446 AH.
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            ZStack(alignment: .leading) { // Overlay placeholder and TextField
                if text.isEmpty { // Show placeholder only if TextField is empty
                    Text(placeholder)
                        .foregroundColor(.gray) // Placeholder text color
                        .padding(.leading, 4)
                }
                TextField("", text: $text) // TextField for user input
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .foregroundColor(.white) // Actual text color when the user types
            }
        }
        .padding(12)
        .background(Color("SecondaryButton")) // Background color for the search bar
        .cornerRadius(8)
    }
}

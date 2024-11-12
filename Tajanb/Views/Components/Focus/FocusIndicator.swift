//
//  FocusIndicator.swift
//  Tajanb
//
//  Created by Afrah Saleh on 07/05/1446 AH.
//

import SwiftUI

struct FocusIndicator: View {
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0

    var body: some View {
        Rectangle()
            .stroke(Color.clear, lineWidth: 2)
            .frame(width: 80, height: 80)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 0.3)) {
                    self.scale = 1.2
                    self.opacity = 1.0
                }
                withAnimation(Animation.easeInOut(duration: 0.3).delay(0.3)) {
                    self.scale = 1.2
                    self.opacity = 0.0
                }
            }
    }
}

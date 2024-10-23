//
//  CornerBorderView.swift
//  Tajanb
//
//  Created by Afrah Saleh on 20/04/1446 AH.
//
import SwiftUI

struct CornerBorderView: View {
    let boxWidthPercentage: CGFloat
    let boxHeightPercentage: CGFloat

    var body: some View {
        ZStack {
            // Shadow effect
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.2))
                .frame(width: UIScreen.main.bounds.width * boxWidthPercentage, height: UIScreen.main.bounds.height * boxHeightPercentage)
            
            // Corner borders
            let borderLength: CGFloat = 50
            let cornerWidth: CGFloat = 3
            let cornerRadius: CGFloat = 8
            
            // Top Left
            RoundedRectangle(cornerRadius: cornerRadius)
                .frame(width: borderLength, height: cornerWidth)
                .offset(x: -((UIScreen.main.bounds.width * boxWidthPercentage) / 2) + (borderLength / 2), y: -((UIScreen.main.bounds.height * boxHeightPercentage) / 2))
                .foregroundColor(.white)
            RoundedRectangle(cornerRadius: cornerRadius)
                .frame(width: cornerWidth, height: borderLength)
                .offset(x: -((UIScreen.main.bounds.width * boxWidthPercentage) / 2), y: -((UIScreen.main.bounds.height * boxHeightPercentage) / 2) + (borderLength / 2))
                .foregroundColor(.white)
            
            // Top Right
            RoundedRectangle(cornerRadius: cornerRadius)
                .frame(width: borderLength, height: cornerWidth)
                .offset(x: ((UIScreen.main.bounds.width * boxWidthPercentage) / 2) - (borderLength / 2), y: -((UIScreen.main.bounds.height * boxHeightPercentage) / 2))
                .foregroundColor(.white)
            RoundedRectangle(cornerRadius: cornerRadius)
                .frame(width: cornerWidth, height: borderLength)
                .offset(x: ((UIScreen.main.bounds.width * boxWidthPercentage) / 2), y: -((UIScreen.main.bounds.height * boxHeightPercentage) / 2) + (borderLength / 2))
                .foregroundColor(.white)
            
            // Bottom Left
            RoundedRectangle(cornerRadius: cornerRadius)
                .frame(width: borderLength, height: cornerWidth)
                .offset(x: -((UIScreen.main.bounds.width * boxWidthPercentage) / 2) + (borderLength / 2), y: ((UIScreen.main.bounds.height * boxHeightPercentage) / 2))
                .foregroundColor(.white)
            RoundedRectangle(cornerRadius: cornerRadius)
                .frame(width: cornerWidth, height: borderLength)
                .offset(x: -((UIScreen.main.bounds.width * boxWidthPercentage) / 2), y: ((UIScreen.main.bounds.height * boxHeightPercentage) / 2) - (borderLength / 2))
                .foregroundColor(.white)
            
            // Bottom Right
            RoundedRectangle(cornerRadius: cornerRadius)
                .frame(width: borderLength, height: cornerWidth)
                .offset(x: ((UIScreen.main.bounds.width * boxWidthPercentage) / 2) - (borderLength / 2), y: ((UIScreen.main.bounds.height * boxHeightPercentage) / 2))
                .foregroundColor(.white)
            RoundedRectangle(cornerRadius: cornerRadius)
                .frame(width: cornerWidth, height: borderLength)
                .offset(x: ((UIScreen.main.bounds.width * boxWidthPercentage) / 2), y: ((UIScreen.main.bounds.height * boxHeightPercentage) / 2) - (borderLength / 2))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    CornerBorderView(boxWidthPercentage: 0.7, boxHeightPercentage: 0.2)
}

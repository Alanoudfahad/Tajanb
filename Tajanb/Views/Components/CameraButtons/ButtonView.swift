//
//  ButtonView.swift
//  Tajanb
//
//  Created by Afrah Saleh on 29/04/1446 AH.
//
import SwiftUI
struct ButtonView: View {
    let systemImage: String
    let label: String
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(Color("CamerasButton"))
                    .frame(width: 70, height: 70)
                Image(systemName: systemImage)
                    .font(.system(size: 24))
                    .foregroundColor(Color("PrimeryButton"))
            }
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

struct CaptureButtonView: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color("PrimeryButton"), lineWidth: 3)
                .frame(width: 80, height: 80)
            Circle()
                .fill(Color.white)
                .frame(width: 60, height: 60)
        }
    }
}

struct RetakeButtonView: View {
    var body: some View {
        ZStack {
            Circle()
                .foregroundColor(Color("CamerasButton"))
                .frame(width: 40, height: 40)
            Image(systemName: "xmark")
                .foregroundColor(Color("PrimeryButton"))
                .font(.system(size: 20))
        }
    }
}

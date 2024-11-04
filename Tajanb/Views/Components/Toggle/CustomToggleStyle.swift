//
//  CustomToggleStyle.swift
//  Tajanb
//
//  Created by Afrah Saleh on 01/05/1446 AH.
//
import SwiftUI
struct CustomToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? Color("CustomGreen") : Color("CustomeGrayToggle"))
                .frame(width: 50, height: 30)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .padding(2)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            
            Spacer()
            
            configuration.label
        }
    }
}

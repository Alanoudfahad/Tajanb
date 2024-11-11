//
//  FlowLayout.swift
//  Tajanb
//
//  Created by Afrah Saleh on 07/05/1446 AH.
//

import SwiftUI

struct FlowLayouts<Content: View>: View {
    var items: [String]
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 8
    var content: (String) -> Content

    init(items: [String], horizontalSpacing: CGFloat = 8, verticalSpacing: CGFloat = 8, @ViewBuilder content: @escaping (String) -> Content) {
        self.items = items
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                self.content(item)
                    .padding(.all, 8) // padding around each item
                    .background(Color("AllergyWarningColor"))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .alignmentGuide(.leading, computeValue: { dimension in
                        if abs(width - dimension.width) > geometry.size.width {
                            width = 0
                            height -= dimension.height + verticalSpacing
                        }
                        let result = width
                        if item == self.items.last! {
                            width = 0 // reset for next item
                        } else {
                            width -= dimension.width + horizontalSpacing
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { _ in
                        let result = height
                        if item == self.items.last! {
                            height = 0 // reset for next item
                        }
                        return result
                    })
            }
        }
    }
}


struct FlowLayout<Content: View>: View  {
    var items: [String]
    var content: (String) -> Content
    
    @State private var totalHeight = CGFloat.zero       // Tracks height
    
    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
    }
    
    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                content(item)
                    .padding([.horizontal, .vertical], 4)
                    .alignmentGuide(.leading, computeValue: { d in
                        if (abs(width - d.width) > geometry.size.width) {
                            width = 0       // Move to next line
                            height -= d.height
                        }
                        let result = width
                        if item == items.last! {
                            width = 0       // Last item
                        } else {
                            width -= d.width
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { _ in height })
            }
        }
        .frame(height: geometry.size.height)
    }
    
}

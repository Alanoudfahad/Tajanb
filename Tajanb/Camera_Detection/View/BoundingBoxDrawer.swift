////
////  BoundingBoxDrawer.swift
////  Tajanb
////
////  Created by Afrah Saleh on 17/04/1446 AH.
////
//
//import SwiftUI
//import Vision
//
//struct BoundingBoxDrawer: View {
//    var boundingBoxes: [CGRect] // Array of bounding boxes
//    var highlightColor: Color = .red
//
//    var body: some View {
//        GeometryReader { geometry in
//            ForEach(0..<boundingBoxes.count, id: \.self) { index in
//                let box = boundingBoxes[index]
//                
//                // Convert normalized bounding box to screen coordinates
//                let screenFrame = CGRect(
//                    x: box.minX * geometry.size.width,
//                    y: (1 - box.maxY) * geometry.size.height,
//                    width: box.width * geometry.size.width,
//                    height: box.height * geometry.size.height
//                )
//                
//                // Draw rectangle around the detected word
//                Rectangle()
//                    .stroke(highlightColor, lineWidth: 2)
//                    .background(Color.clear) // Ensure transparency inside the box
//                    .frame(width: screenFrame.width, height: screenFrame.height)
//                    .position(x: screenFrame.midX, y: screenFrame.midY)
//            }
//        }
//    }
//}

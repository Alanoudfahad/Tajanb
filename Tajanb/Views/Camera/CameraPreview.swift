//
//  CameraPreview.swift
//  Tajanb
//
//  Created by Afrah Saleh on 29/04/1446 AH.
//

import SwiftUI
//import AVFoundation
//
//struct CameraPreview: UIViewRepresentable {
//    let session: AVCaptureSession
//    
//    func makeUIView(context: Context) -> UIView {
//        let view = UIView(frame: .zero)
//        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
//        previewLayer.videoGravity = .resizeAspectFill
//        view.layer.addSublayer(previewLayer)
//        
//        DispatchQueue.main.async {
//            previewLayer.frame = view.bounds
//        }
//        
//        return view
//    }
//    
//    func updateUIView(_ uiView: UIView, context: Context) {
//        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
//            DispatchQueue.main.async {
//                previewLayer.frame = uiView.bounds
//            }
//        }
//    }
//}
import SwiftUI
import AVFoundation
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    var onZoomChange: ((CGFloat) -> Void)? = nil
    var onTapToFocus: ((CGPoint) -> Void)? = nil  // Callback for tap gestures
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        
        // Setup preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        
        // Add pinch gesture recognizer for zoom
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        view.addGestureRecognizer(pinchGesture)
        
        // Add tap gesture recognizer for focus
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tapGesture)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update preview layer frame
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject {
        var parent: CameraPreview
        var lastScale: CGFloat = 1.0
        
        init(parent: CameraPreview) {
            self.parent = parent
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let onZoomChange = parent.onZoomChange else { return }
            switch gesture.state {
            case .began, .changed:
                let scale = gesture.scale
                let delta = scale / lastScale
                lastScale = scale
                onZoomChange(delta)
            case .ended, .cancelled:
                lastScale = 1.0
            default:
                break
            }
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let location = gesture.location(in: gesture.view)
            parent.onTapToFocus?(location)
        }
    }
}

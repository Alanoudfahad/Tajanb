//
//  CameraFunctionalitiesViewModel.swift
//  Tajanb
//
//  Created by Afrah Saleh on 08/05/1446 AH.
//

import Foundation
import AVFoundation
import UIKit

class CameraFunctionalitiesViewModel: NSObject {
    private var isFlashOn: Bool = false
    private var currentZoomFactor: CGFloat = 1.0
    private var maxZoomFactor: CGFloat = 6.0  // Adjust based on device capabilities
    private let minZoomFactor: CGFloat = 1.0
    private let CameraManager: CameraManager
    
    // Initialize with FirestoreViewModel and load any previously selected words
    init(CameraManager: CameraManager) {
        self.CameraManager = CameraManager
        if let device = CameraManager.videoDevice {
            maxZoomFactor = min(device.activeFormat.videoMaxZoomFactor, 6.0)
        }
    }
    
    
    
    // MARK: - Zoom Methods
  
         func setZoomFactor(_ factor: CGFloat) {
             guard let device = CameraManager.videoDevice else { return }
             let zoomFactor = max(min(factor, maxZoomFactor), minZoomFactor)
             
             DispatchQueue.global(qos: .userInitiated).async {
                 do {
                     try device.lockForConfiguration()
                     device.videoZoomFactor = zoomFactor
                     device.unlockForConfiguration()
                     
                     DispatchQueue.main.async {
                         self.currentZoomFactor = zoomFactor
                     }
                 } catch {
                     print("Failed to set zoom factor: \(error)")
                 }
             }
         }
    
         func zoomIn(step: CGFloat = 1.0) {
             setZoomFactor(currentZoomFactor + step)
         }

         func zoomOut(step: CGFloat = 1.0) {
             setZoomFactor(currentZoomFactor - step)
         }
         
         /// Resets the zoom factor to the minimum.
         func resetZoom() {
             setZoomFactor(minZoomFactor)
         }

    
    
    // MARK: - Focus Methods

      func setFocusPoint(_ point: CGPoint) {
          guard let device = CameraManager.videoDevice else { return }
          
          DispatchQueue.global(qos: .userInitiated).async {
              do {
                  try device.lockForConfiguration()
                  
                  // Set focus point
                  if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
                      device.focusPointOfInterest = point
                      device.focusMode = .autoFocus
                  }
                  
                  // Set exposure point
                  if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.autoExpose) {
                      device.exposurePointOfInterest = point
                      device.exposureMode = .autoExpose
                  }
                  
                  device.unlockForConfiguration()
              } catch {
                  print("Failed to set focus/exposure point: \(error)")
              }
          }
      }

    
}

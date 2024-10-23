//
//  TajanbApp.swift
//  Tajanb
//
//  Created by Alanoud Alshuaibi on 17/04/1446 AH.
//

import SwiftUI
import SwiftData

@main
struct TajanbApp: App {
    let viewModel = CameraViewModel()
    let photoviewModel = PhotoViewModel(viewmodel: CameraViewModel())
    var body: some Scene {
        WindowGroup {
            CameraView(
                viewModel: viewModel, photoViewModel: photoviewModel)
        }
    }
}


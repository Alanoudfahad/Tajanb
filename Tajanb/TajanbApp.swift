//
//  TajanbApp.swift
//  Tajanb
//
//  Created by Alanoud Alshuaibi on 17/04/1446 AH.
//

import SwiftUI
import SwiftData

//@main
//struct TajanbApp: App {
////    let viewModel = CameraViewModel()
////    let photoviewModel = PhotoViewModel(viewmodel: CameraViewModel())
//    var body: some Scene {
//        WindowGroup {
//            OnboardingView1()
////            CameraView(
////                viewModel: viewModel, photoViewModel: photoviewModel)
//        }
//    }
//}


@main
struct TajanbApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    let viewModel = CameraViewModel()

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                SplashScreenView(cameraViewModel: viewModel)
            } else {
                OnboardingView1(hasSeenOnboarding: $hasSeenOnboarding)
            }
        }
    }
}

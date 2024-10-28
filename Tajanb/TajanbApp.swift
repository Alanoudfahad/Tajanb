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
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var justCompletedOnboarding: Bool = false // Track if onboarding just completed
    let viewModel = CameraViewModel()

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                // Show SplashScreen on subsequent launches if onboarding has been seen
                if justCompletedOnboarding {
                    // Directly show the CameraView after onboarding completion
                    CameraView(viewModel: viewModel, photoViewModel: PhotoViewModel(viewmodel: viewModel))
                } else {
                    // Show SplashScreen on all subsequent launches
                    SplashScreenView(cameraViewModel: viewModel)
                        .onAppear {
                            // Reset the flag after splash screen displays
                            justCompletedOnboarding = false
                        }
                }
            } else {
                // Show Onboarding on the first launch
                OnboardingView1(hasSeenOnboarding: $hasSeenOnboarding, justCompletedOnboarding: $justCompletedOnboarding)
            }
        }
        .modelContainer(for: SelectedWord.self)

    }
}



//            if !hasSeenOnboarding {
//                OnboardingView1(hasSeenOnboarding: $hasSeenOnboarding)
//            } else if hasSeenOnboarding {
//                SplashScreenView(cameraViewModel: viewModel)
//            }

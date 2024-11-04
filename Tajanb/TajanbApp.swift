//
//  TajanbApp.swift
//  Tajanb
//
//  Created by Alanoud Alshuaibi on 17/04/1446 AH.
//

import SwiftUI
import SwiftData
import FirebaseCore
import Firebase

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}


@main
struct TajanbApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
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
                            viewModel.fetchCategories()
                        }
                }
            } else {
                // Show Onboarding on the first launch
                OnboardingContainerView(hasSeenOnboarding: $hasSeenOnboarding, justCompletedOnboarding: $justCompletedOnboarding)
//                    .onAppear{
//                        viewModel.uploadJSONToFirestore()
//                        //viewModel.fetchCategories()
//                    }
            }
        }


    }
    
}


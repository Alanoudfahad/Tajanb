
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
import FirebaseFirestore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
                // Initialize Firebase
               FirebaseApp.configure()
               
               // Get the Firestore instance
               let firestore = Firestore.firestore()
               
               // Set Firestore settings
               let settings = FirestoreSettings()

               // set a custom cache size (in bytes). For example, 100 MB.
               settings.cacheSettings = PersistentCacheSettings(sizeBytes: 100 * 1024 * 1024 as NSNumber) // 100MB cache size
               
               // Apply the settings to Firestore
               firestore.settings = settings
               
               return true
    }
}

@main
struct TajanbApp: App {
    // Register app delegate for Firebase setup
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
                           justCompletedOnboarding = false

                       }

                }
            } else {
                // Show Onboarding on the first launch
                OnboardingContainerView(hasSeenOnboarding: $hasSeenOnboarding, justCompletedOnboarding: $justCompletedOnboarding, cameraViewModel: viewModel)
                    .onAppear {
                        // Upload JSON to Firestore if needed
                        // viewModel.firestoreViewModel.uploadJSONToFirestore()
                        
                        // Fetch categories through firestoreViewModel
                        viewModel.firestoreViewModel.fetchCategories {
                            // Optionally handle completion here
                        }
                        // Fetch word mappings through firestoreViewModel
                        viewModel.firestoreViewModel.fetchWordMappings {
                            // Optionally handle completion here
                        }
                    }
            }
        } .modelContainer(for: [SelectedWord.self])
    }
}

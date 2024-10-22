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
    // Initialize the view models
    let textRecognitionViewModel = TextRecognitionViewModel(categoryManager: CategoryManagerViewModel())
    let categoryManagerViewModel = CategoryManagerViewModel()

    var body: some Scene {
        WindowGroup {
            CameraView(
                textRecognitionViewModel: textRecognitionViewModel,
                categoryManagerViewModel: categoryManagerViewModel, photoViewModel: PhotoViewModel(categoryManager: categoryManagerViewModel)
            )
        }
    }
}
//    var sharedModelContainer: ModelContainer = {
//        let schema = Schema([
//            Item.self,
//        ])
//        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
//
//        do {
//            return try ModelContainer(for: schema, configurations: [modelConfiguration])
//        } catch {
//            fatalError("Could not create ModelContainer: \(error)")
//        }
//    }()
//
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//        .modelContainer(sharedModelContainer)
//    }
//}

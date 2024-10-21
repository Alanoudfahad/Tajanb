import SwiftUI
import SwiftData

@main
struct TajanbApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([TargetWord.self]) // Reference your model class
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
           // PhotoMainView() // Call MainView here
            ContentView()
        }                .modelContainer(sharedModelContainer) // Inject the model container into the view

    }
}

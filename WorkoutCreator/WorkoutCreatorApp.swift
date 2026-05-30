import SwiftUI

@main
struct WorkoutCreatorApp: App {
    @State private var authStore = AuthStore()
    @State private var workoutStore = WorkoutStore()
    @State private var syncService = WorkoutSyncService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authStore)
                .environment(workoutStore)
                .environment(syncService)
                .focusedValue(\.workoutStore, workoutStore)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            AppCommands()
        }
    }
}

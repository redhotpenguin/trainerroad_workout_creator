import SwiftUI
import AppKit

struct AppCommands: Commands {
    @FocusedValue(\.workoutStore) var workoutStore: WorkoutStore?

    var body: some Commands {
        CommandGroup(after: .saveItem) {
            Button("Export as .mrc…") {
                exportMRC()
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])
            .disabled(workoutStore?.currentWorkout == nil)
        }
    }

    private func exportMRC() {
        guard let store = workoutStore,
              let workout = store.currentWorkout,
              let details = store.currentDetails
        else { return }

        let mrc = MRCWriter.write(
            name: workout.name,
            intensityFactor: workout.intensityFactor / 100,
            tss: workout.tss,
            memberID: workout.memberID,
            details: details
        )

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.init(filenameExtension: "mrc")!]
        panel.nameFieldStringValue = "\(workout.name).mrc"
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? mrc.write(to: url, atomically: true, encoding: .utf8)
    }
}

private struct WorkoutStoreKey: FocusedValueKey {
    typealias Value = WorkoutStore
}

extension FocusedValues {
    var workoutStore: WorkoutStore? {
        get { self[WorkoutStoreKey.self] }
        set { self[WorkoutStoreKey.self] = newValue }
    }
}

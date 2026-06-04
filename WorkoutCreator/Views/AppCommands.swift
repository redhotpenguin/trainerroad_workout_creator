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

            Button("Dump All Workouts (Debug)") {
                dumpAllWorkouts()
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])
        }
    }

    private func dumpAllWorkouts() {
        guard let store = workoutStore else { return }
        print("\n========== WORKOUT DUMP (\(store.workoutList.count)) ==========")
        for workout in store.workoutList {
            dump(workout: workout)
        }
        print("============================================\n")
    }

    private func dump(workout: WorkoutFile) {
        print("\n--- \(workout.name) (id=\(workout.id ?? -1)) ---")
        print("  Duration: \(workout.duration)s (\(Int(workout.duration)/60)m \(Int(workout.duration)%60)s)")
        print("  TSS: \(workout.tss)  IF: \(workout.intensityFactor)")
        print("  IsActive=\(workout.isActive)  IsDirty=\(workout.isDirty)")

        guard let contents = workout.fileContents else {
            print("  <no fileContents>")
            return
        }

        print("  fileContents byte length: \(contents.utf8.count)")

        do {
            let result = try MRCParser.parse(contents)
            let details = result.details

            print("  Intervals: \(details.intervals.count)")
            for (i, iv) in details.intervals.enumerated() {
                print("    [\(i)] \(iv.startSeconds)…\(iv.endSeconds)  power=\(iv.power)  name=\"\(iv.name)\"")
            }

            print("  WorkoutPoints (last 6 of \(details.workoutPoints.count)):")
            for p in details.workoutPoints.suffix(6) {
                print("    minutes=\(p.minutes)  ftp%=\(p.ftpPercent)")
            }
        } catch {
            print("  <PARSE FAILED: \(error)>")
        }

        print("  MRC head (first 400 chars):")
        let head = String(contents.prefix(400))
        print("    " + head.replacingOccurrences(of: "\n", with: "\n    "))

        print("  MRC tail (last 400 chars):")
        let tail = String(contents.suffix(400))
        print("    " + tail.replacingOccurrences(of: "\n", with: "\n    "))
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

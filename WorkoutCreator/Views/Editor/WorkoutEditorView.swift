import SwiftUI
import Charts

struct WorkoutEditorView: View {
    @Environment(WorkoutStore.self) private var store
    @Environment(AuthStore.self) private var authStore
    @State private var editingName = false
    @AppStorage("userFTP") private var ftp: Int = 250

    var body: some View {
        Group {
            if let workout = store.currentWorkout {
                editorContent(workout: workout)
            } else {
                ContentUnavailableView(
                    "No Workout Selected",
                    systemImage: "figure.outdoor.cycle",
                    description: Text("Select a workout from the list or create a new one.")
                )
            }
        }
    }

    @ViewBuilder
    private func editorContent(workout: WorkoutFile) -> some View {
        @Bindable var store = store
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(spacing: 12) {
                    TextField("Workout Name", text: Binding(
                        get: { store.currentWorkout?.name ?? "" },
                        set: { store.currentWorkout?.name = $0 }
                    ))
                    .font(.title2.bold())
                    .textFieldStyle(.plain)

                    Spacer()

                    HStack(spacing: 4) {
                        Text("FTP")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("", value: $ftp, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 56)
                            .multilineTextAlignment(.trailing)
                        Text("W")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Chart
                WorkoutChartView()
                    .frame(height: 220)

                // Intervals
                IntervalEditorView()

                // Cues — always visible so users can add new ones to any workout.
                CueEditorView()
            }
            .padding()
        }
        .toolbar {
            ToolbarItem {
                Button("Save") { store.save() }
                    .keyboardShortcut("s", modifiers: .command)
            }
            ToolbarItem {
                Button {
                    store.currentWorkout?.isFavorite.toggle()
                    store.save()
                } label: {
                    Image(systemName: workout.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(workout.isFavorite ? .yellow : .secondary)
                }
                .help("Toggle Favorite")
            }
            ToolbarItem {
                Button(role: .destructive) {
                    store.delete(workout)
                } label: {
                    Image(systemName: "trash")
                }
                .help("Delete Workout")
            }
        }
    }
}

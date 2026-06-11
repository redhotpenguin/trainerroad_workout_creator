import SwiftUI
import Charts

struct WorkoutEditorView: View {
    @Environment(WorkoutStore.self) private var store
    @Environment(AuthStore.self) private var authStore
    @State private var editingName = false
    @State private var showingZones = false
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
                    .frame(maxWidth: 280, alignment: .leading)

                    Button { showingZones.toggle() } label: {
                        Text("Power Zone Definitions")
                            .font(.callout)
                            .foregroundStyle(.blue)
                            .underline(true, pattern: .dot)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showingZones, arrowEdge: .bottom) {
                        PowerZonesPopover(ftp: ftp)
                    }

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

// Power zone bands aligned with WorkoutChartView's kPowerZones and
// WorkoutStore.powerZoneName boundaries. Listed as inclusive % ranges.
// Coggan / TrainingPeaks 7-level power training zones.
private let powerZoneRows: [(zone: String, name: String, low: Int, high: Int)] = [
    ("Z1", "Active Recovery",    0,   55),
    ("Z2", "Endurance",          56,  75),
    ("Z3", "Tempo",              76,  90),
    ("Z4", "Lactate Threshold",  91,  105),
    ("Z5", "VO2 Max",            106, 120),
    ("Z6", "Anaerobic Capacity", 121, 150),
    ("Z7", "Neuromuscular",      151, 250),
]

struct PowerZonesPopover: View {
    let ftp: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Power Zones (FTP \(ftp) W)")
                .font(.headline)
            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 4) {
                GridRow {
                    Text("Zone").bold()
                    Text("Name").bold()
                    Text("% FTP").bold()
                    Text("Watts").bold()
                }
                .foregroundStyle(.secondary)
                ForEach(powerZoneRows, id: \.zone) { row in
                    GridRow {
                        Text(row.zone)
                        Text(row.name)
                        Text("\(row.low)–\(row.high)%")
                            .monospacedDigit()
                        Text("\(row.low * ftp / 100)–\(row.high * ftp / 100) W")
                            .monospacedDigit()
                    }
                }
            }
            .font(.callout)
        }
        .padding(12)
    }
}

private func powerZonesTooltip(ftp: Int) -> String {
    powerZoneRows.map { row in
        let lowW  = row.low  * ftp / 100
        let highW = row.high * ftp / 100
        return String(format: "%@ %-18@ %3d–%3d%%   %4d–%4d W",
                      row.zone, row.name as NSString,
                      row.low, row.high, lowW, highW)
    }.joined(separator: "\n")
}

import SwiftUI

struct IntervalEditorView: View {
    @Environment(WorkoutStore.self) private var store

    private var intervals: Binding<[WorkoutInterval]> {
        Binding(
            get: { store.currentDetails?.intervals ?? [] },
            set: { store.currentDetails?.intervals = $0 }
        )
    }

    // 8-segment race warm-up: 3m@50, 2m@75, 1m@105, 1m@40, 1m@110, 1m@40, 1m@120, 5m@40.
    private static let warmUpSegments: [(durationSec: Int, power: Double)] = [
        (180, 50), (120, 75), (60, 105), (60, 40),
        (60, 110), (60, 40), (60, 120), (300, 40)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZoneLegendRow()
                .padding(.bottom, 2)

            HStack(spacing: 8) {
                Text("Intervals")
                    .font(.headline)

                CannedIntervalButton(
                    label: "VO2Max Warmup",
                    help: "Insert 8-segment VO2Max warm-up",
                    segments: Self.warmUpSegments
                ) { appendSegments($0) }

                CannedIntervalButton(
                    label: "4/4",
                    help: "Insert 4 min @ 120% + 4 min @ 40%",
                    segments: [(240, 120), (240, 40)],
                    fillColor: zoneColor(forPower: 120)
                ) { appendSegments($0) }

                CannedIntervalButton(
                    label: "3/3",
                    help: "Insert 3 min @ 120% + 3 min @ 40%",
                    segments: [(180, 120), (180, 40)],
                    fillColor: zoneColor(forPower: 120)
                ) { appendSegments($0) }

                CannedIntervalButton(
                    label: "2/3",
                    help: "Insert 2 min @ 120% + 3 min @ 40%",
                    segments: [(120, 120), (180, 40)],
                    fillColor: zoneColor(forPower: 120)
                ) { appendSegments($0) }

                CannedIntervalButton(
                    label: "6/4",
                    help: "Insert 6 min @ 105% + 4 min @ 40%",
                    segments: [(360, 105), (240, 40)],
                    fillColor: zoneColor(forPower: 105)
                ) { appendSegments($0) }

                CannedIntervalButton(
                    label: "10/4",
                    help: "Insert 10 min @ 90% + 4 min @ 40%",
                    segments: [(600, 90), (240, 40)],
                    fillColor: zoneColor(forPower: 90)
                ) { appendSegments($0) }

                CannedIntervalButton(
                    label: "15/4",
                    help: "Insert 15 min @ 90% + 4 min @ 40%",
                    segments: [(900, 90), (240, 40)],
                    fillColor: zoneColor(forPower: 90)
                ) { appendSegments($0) }

                CannedIntervalButton(
                    label: "Cooldown",
                    help: "Insert 5 min cooldown @ 40%",
                    segments: [(300, 40)],
                    fillColor: zoneColor(forPower: 40)
                ) { appendSegments($0) }

                Spacer()
                Button {
                    let lastEnd = store.currentDetails?.intervals.last?.endSeconds ?? 3600
                    store.currentDetails?.intervals.append(
                        // Empty name → save() auto-assigns "<Zone> <N>" from the power.
                        WorkoutInterval(startSeconds: lastEnd, endSeconds: lastEnd + 600, name: "", power: 75)
                    )
                    store.save()
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
            }

            VStack(alignment: .leading, spacing: 0) {
                ForEach(intervals.indices, id: \.self) { i in
                    IntervalRow(
                        interval: intervals[i],
                        onLengthChange: { newLengthSec in
                            let oldEnd   = intervals.wrappedValue[i].endSeconds
                            let start    = intervals.wrappedValue[i].startSeconds
                            // Snap to 5s grid, floor at 5s.
                            let snapped  = max(5, (newLengthSec / 5) * 5)
                            let newEnd   = start + snapped
                            let shift    = newEnd - oldEnd
                            intervals.wrappedValue[i].endSeconds = newEnd
                            // Shift every later interval by the delta, preserving
                            // its duration. This keeps the timeline contiguous
                            // whether the change shortens or lengthens this one.
                            for j in intervals.wrappedValue.indices
                                where intervals.wrappedValue[j].startSeconds >= oldEnd {
                                intervals.wrappedValue[j].startSeconds += shift
                                intervals.wrappedValue[j].endSeconds += shift
                            }
                            store.save()
                        },
                        onClone: {
                            let source = intervals.wrappedValue[i]
                            let length = source.endSeconds - source.startSeconds
                            let newStart = intervals.wrappedValue.last?.endSeconds ?? source.endSeconds
                            intervals.wrappedValue.append(WorkoutInterval(
                                startSeconds: newStart,
                                endSeconds: newStart + length,
                                name: source.name,
                                power: source.power
                            ))
                            store.save()
                        },
                        onDelete: {
                            let deleted = intervals.wrappedValue[i]
                            let deletedStart = deleted.startSeconds
                            let shift = deleted.endSeconds - deleted.startSeconds
                            intervals.wrappedValue.remove(at: i)
                            // Shift everything that was to the right of the deleted
                            // interval back by its duration, so adjacency is preserved
                            // instead of leaving a gap (or extending the neighbor).
                            for j in intervals.wrappedValue.indices
                                where intervals.wrappedValue[j].startSeconds >= deletedStart {
                                intervals.wrappedValue[j].startSeconds -= shift
                                intervals.wrappedValue[j].endSeconds -= shift
                            }
                            store.save()
                        },
                        onCommit: { store.save() }
                    )
                    if i < intervals.wrappedValue.count - 1 {
                        Divider().padding(.horizontal, 8)
                    }
                }
            }
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(nsColor: .separatorColor), lineWidth: 0.5))
        }
    }

    private func appendSegments(_ segments: [(durationSec: Int, power: Double)]) {
        var cursor = store.currentDetails?.intervals.last?.endSeconds ?? 0
        for seg in segments {
            store.currentDetails?.intervals.append(
                WorkoutInterval(
                    startSeconds: cursor,
                    endSeconds: cursor + seg.durationSec,
                    name: "",
                    power: seg.power
                )
            )
            cursor += seg.durationSec
        }
        store.save()
    }
}

private struct CannedIntervalButton: View {
    let label: String
    let help: String
    let segments: [(durationSec: Int, power: Double)]
    var fillColor: Color? = nil
    let onTap: ([(durationSec: Int, power: Double)]) -> Void

    var body: some View {
        Button { onTap(segments) } label: {
            Text(label)
                .font(.caption.monospacedDigit())
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill((fillColor ?? Color.clear).opacity(0.2))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.5), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
        .help(help)
    }
}

// Mirrors WorkoutChartView's kPowerZones color choices so pill backgrounds
// and the chart's zone bands match.
private struct ZoneSpec {
    let code: String
    let name: String
    let lowPct: Double
    let highPct: Double
    let color: Color
}

// Coggan / TrainingPeaks 7-level power training zones.
private let zoneSpecs: [ZoneSpec] = [
    ZoneSpec(code: "Z1", name: "Active Recovery",    lowPct: 0,   highPct: 55,  color: .gray),
    ZoneSpec(code: "Z2", name: "Endurance",          lowPct: 56,  highPct: 75,  color: .blue),
    ZoneSpec(code: "Z3", name: "Tempo",              lowPct: 76,  highPct: 90,  color: .green),
    ZoneSpec(code: "Z4", name: "Lactate Threshold",  lowPct: 91,  highPct: 105, color: .teal),
    ZoneSpec(code: "Z5", name: "VO2 Max",            lowPct: 106, highPct: 120, color: .orange),
    ZoneSpec(code: "Z6", name: "Anaerobic Capacity", lowPct: 121, highPct: 150, color: .red),
    ZoneSpec(code: "Z7", name: "Neuromuscular",      lowPct: 151, highPct: 250, color: .purple),
]

private func zoneColor(forPower power: Double) -> Color {
    zoneSpecs.last(where: { power >= $0.lowPct }).map(\.color) ?? .gray
}

private struct ZoneLegendRow: View {
    var body: some View {
        HStack(spacing: 10) {
            ForEach(zoneSpecs, id: \.code) { z in
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(z.color.opacity(0.5))
                        .frame(width: 12, height: 12)
                    Text("\(z.code) \(z.name)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .help("\(z.code) \(z.name) — \(Int(z.lowPct))–\(Int(z.highPct))% FTP")
            }
        }
    }
}

private struct IntervalRow: View {
    @Binding var interval: WorkoutInterval
    let onLengthChange: (Int) -> Void
    let onClone: () -> Void
    let onDelete: () -> Void
    let onCommit: () -> Void

    private var startSec:  Int { interval.startSeconds }
    private var lengthSec: Int { max(5, interval.endSeconds - interval.startSeconds) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                TextField("Name", text: $interval.name)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(onCommit)

                Spacer()

                Button(action: onClone) {
                    Image(systemName: "plus.square.on.square")
                }
                .buttonStyle(.borderless)
                .help("Clone interval")

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.borderless)
            }

            HStack(spacing: 12) {
                // Start (read-only context)
                Text("@ \(formatMMSS(startSec))")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()

                // Length
                LabeledContent("Length") {
                    HStack(spacing: 2) {
                        TextField("", text: Binding(
                            get: { formatMMSS(lengthSec) },
                            set: { if let sec = parseMMSS($0) { onLengthChange(sec) } }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 56)
                        .multilineTextAlignment(.trailing)
                        .monospacedDigit()
                        .onSubmit(onCommit)
                        Stepper("", value: Binding(
                            get: { lengthSec },
                            set: { onLengthChange($0) }
                        ), in: 5...28800, step: 5)
                        .labelsHidden()
                    }
                }

                // Power
                LabeledContent("Power") {
                    HStack(spacing: 2) {
                        TextField("", value: Binding(
                            get: { Int(interval.power) },
                            set: { interval.power = Double(max(1, min(200, $0))) }
                        ), format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 44)
                        .multilineTextAlignment(.trailing)
                        .onSubmit(onCommit)
                        Text("% FTP").foregroundStyle(.secondary)
                        Stepper("", value: Binding(
                            get: { Int(interval.power) },
                            set: { interval.power = Double(max(1, min(200, $0))); onCommit() }
                        ), in: 1...200, step: 5)
                        .labelsHidden()
                    }
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}

private func formatMMSS(_ totalSec: Int) -> String {
    let s = max(0, totalSec)
    return "\(s / 60):\(String(format: "%02d", s % 60))"
}

private func parseMMSS(_ raw: String) -> Int? {
    let s = raw.trimmingCharacters(in: .whitespaces)
    guard !s.isEmpty else { return nil }
    if s.contains(":") {
        let parts = s.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2,
              let m = Int(parts[0]),
              let sec = Int(parts[1]),
              m >= 0, sec >= 0, sec < 60 else { return nil }
        return m * 60 + sec
    }
    return Int(s)
}

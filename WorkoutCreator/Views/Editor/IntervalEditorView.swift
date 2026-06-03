import SwiftUI

struct IntervalEditorView: View {
    @Environment(WorkoutStore.self) private var store

    private var intervals: Binding<[WorkoutInterval]> {
        Binding(
            get: { store.currentDetails?.intervals ?? [] },
            set: { store.currentDetails?.intervals = $0 }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Intervals")
                    .font(.headline)
                Spacer()
                Button {
                    let lastEnd = store.currentDetails?.intervals.last?.endSeconds ?? 3600
                    store.currentDetails?.intervals.append(
                        WorkoutInterval(startSeconds: lastEnd, endSeconds: lastEnd + 600, name: "New Interval", power: 75)
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
                        onLengthChange: { newLengthMin in
                            let startMin = intervals.wrappedValue[i].startSeconds / 60
                            let clamped  = max(1, newLengthMin)
                            let newEnd   = (startMin + clamped) * 60
                            intervals.wrappedValue[i].endSeconds = newEnd
                            // Push next interval's start; if that would invert it
                            // (start >= end), bump its end so it keeps ≥1 min duration.
                            if i < intervals.wrappedValue.count - 1 {
                                intervals.wrappedValue[i + 1].startSeconds = newEnd
                                if intervals.wrappedValue[i + 1].endSeconds <= newEnd {
                                    intervals.wrappedValue[i + 1].endSeconds = newEnd + 60
                                }
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
                            intervals.wrappedValue.remove(at: i)
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
}

private struct IntervalRow: View {
    @Binding var interval: WorkoutInterval
    let onLengthChange: (Int) -> Void
    let onClone: () -> Void
    let onDelete: () -> Void
    let onCommit: () -> Void

    private var startMin:  Int { interval.startSeconds / 60 }
    private var lengthMin: Int { max(1, (interval.endSeconds - interval.startSeconds) / 60) }

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
                Text("@ \(startMin) min")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()

                // Length
                LabeledContent("Length") {
                    HStack(spacing: 2) {
                        TextField("", value: Binding(
                            get: { lengthMin },
                            set: { onLengthChange($0) }
                        ), format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 44)
                        .multilineTextAlignment(.trailing)
                        .onSubmit(onCommit)
                        Text("min").foregroundStyle(.secondary)
                        Stepper("", value: Binding(
                            get: { lengthMin },
                            set: { onLengthChange($0) }
                        ), in: 1...480)
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

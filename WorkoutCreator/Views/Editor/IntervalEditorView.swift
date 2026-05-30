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
                        onStartChange: { newMin in
                            let clamped = max(0, min(newMin, intervals.wrappedValue[i].endSeconds / 60 - 1))
                            intervals.wrappedValue[i].startSeconds = clamped * 60
                            // Push previous interval's end to match
                            if i > 0 {
                                intervals.wrappedValue[i - 1].endSeconds = clamped * 60
                            }
                            store.save()
                        },
                        onEndChange: { newMin in
                            let clamped = max(intervals.wrappedValue[i].startSeconds / 60 + 1, min(newMin, 480))
                            intervals.wrappedValue[i].endSeconds = clamped * 60
                            // Push next interval's start to match
                            if i < intervals.wrappedValue.count - 1 {
                                intervals.wrappedValue[i + 1].startSeconds = clamped * 60
                            }
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
    let onStartChange: (Int) -> Void
    let onEndChange: (Int) -> Void
    let onDelete: () -> Void
    let onCommit: () -> Void

    private var startMin: Int { interval.startSeconds / 60 }
    private var endMin: Int   { interval.endSeconds   / 60 }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                TextField("Name", text: $interval.name)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(onCommit)

                Spacer()

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.borderless)
            }

            HStack(spacing: 12) {
                // Start time
                LabeledContent("Start") {
                    HStack(spacing: 2) {
                        TextField("", value: Binding(
                            get: { startMin },
                            set: { onStartChange($0) }
                        ), format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 44)
                        .multilineTextAlignment(.trailing)
                        .onSubmit(onCommit)
                        Text("min").foregroundStyle(.secondary)
                        Stepper("", value: Binding(
                            get: { startMin },
                            set: { onStartChange($0) }
                        ), in: 0...(endMin - 1))
                        .labelsHidden()
                    }
                }

                // End time
                LabeledContent("End") {
                    HStack(spacing: 2) {
                        TextField("", value: Binding(
                            get: { endMin },
                            set: { onEndChange($0) }
                        ), format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 44)
                        .multilineTextAlignment(.trailing)
                        .onSubmit(onCommit)
                        Text("min").foregroundStyle(.secondary)
                        Stepper("", value: Binding(
                            get: { endMin },
                            set: { onEndChange($0) }
                        ), in: (startMin + 1)...480)
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

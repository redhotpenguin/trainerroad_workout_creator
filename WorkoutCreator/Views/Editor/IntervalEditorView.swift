import SwiftUI

struct IntervalEditorView: View {
    @Environment(WorkoutStore.self) private var store

    private var intervals: Binding<[WorkoutInterval]> {
        Binding(
            get: { store.currentDetails?.intervals ?? [] },
            set: { store.currentDetails?.intervals = $0 }
        )
    }

    private func secondsToString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Intervals")
                    .font(.headline)
                Spacer()
                Button {
                    let duration = Int((store.currentDetails?.workoutPoints.last?.minutes ?? 60) * 60)
                    store.currentDetails?.intervals.append(
                        WorkoutInterval(startSeconds: 0, endSeconds: duration, name: "New Interval")
                    )
                    store.save()
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
            }

            List {
                ForEach(intervals) { $interval in
                    HStack {
                        TextField("Name", text: $interval.name)
                            .textFieldStyle(.plain)
                        Spacer()
                        Text("\(secondsToString(interval.startSeconds)) – \(secondsToString(interval.endSeconds))")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
                .onDelete { indices in
                    store.currentDetails?.intervals.remove(atOffsets: indices)
                    store.save()
                }
                .onMove { from, to in
                    store.currentDetails?.intervals.move(fromOffsets: from, toOffset: to)
                    store.save()
                }
            }
            .frame(height: CGFloat(max(intervals.wrappedValue.count, 1)) * 36 + 8)
            .listStyle(.plain)
        }
    }
}

import SwiftUI

struct CueEditorView: View {
    @Environment(WorkoutStore.self) private var store

    private var cues: Binding<[CuePoint]> {
        Binding(
            get: { store.currentDetails?.cuePoints ?? [] },
            set: { store.currentDetails?.cuePoints = $0 }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Cue Points")
                    .font(.headline)
                Spacer()
                Button {
                    store.currentDetails?.cuePoints.append(
                        CuePoint(startSeconds: 0, durationSeconds: 10, text: "")
                    )
                    store.save()
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
            }

            List {
                ForEach(cues) { $cue in
                    HStack(spacing: 8) {
                        Text("\(cue.startSeconds / 60):\(String(format: "%02d", cue.startSeconds % 60))")
                            .foregroundStyle(.secondary)
                            .font(.caption.monospacedDigit())
                            .frame(width: 44)
                        TextField("Cue text", text: $cue.text)
                            .textFieldStyle(.plain)
                    }
                }
                .onDelete { indices in
                    store.currentDetails?.cuePoints.remove(atOffsets: indices)
                    store.save()
                }
            }
            .frame(height: CGFloat(max(cues.wrappedValue.count, 1)) * 36 + 8)
            .listStyle(.plain)
        }
    }
}

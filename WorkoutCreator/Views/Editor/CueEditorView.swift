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
                    let lastStart = store.currentDetails?.cuePoints.last?.startSeconds ?? 0
                    store.currentDetails?.cuePoints.append(
                        CuePoint(startSeconds: lastStart + 60, durationSeconds: 5, text: "")
                    )
                    store.save()
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
            }

            VStack(alignment: .leading, spacing: 0) {
                ForEach(cues) { $cue in
                    HStack(spacing: 8) {
                        // Editable start time (seconds). mm:ss preview is shown
                        // to the right so the user can quickly read the moment.
                        TextField("", value: $cue.startSeconds, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 56)
                            .multilineTextAlignment(.trailing)
                            .onSubmit { store.save() }
                        Text("s · \(cue.startSeconds / 60):\(String(format: "%02d", cue.startSeconds % 60))")
                            .foregroundStyle(.secondary)
                            .font(.caption.monospacedDigit())
                            .frame(width: 80, alignment: .leading)
                        TextField("Cue text", text: $cue.text)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit { store.save() }
                        Button(role: .destructive) {
                            if let idx = store.currentDetails?.cuePoints.firstIndex(where: { $0.id == cue.id }) {
                                store.currentDetails?.cuePoints.remove(at: idx)
                                store.save()
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    if cue.id != cues.wrappedValue.last?.id {
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

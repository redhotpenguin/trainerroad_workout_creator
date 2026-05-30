import SwiftUI

struct ImportView: View {
    @Environment(WorkoutStore.self) private var store
    @Binding var isPresented: Bool
    @State private var isImporting = false
    @State private var importedCount: Int?
    @State private var error: String?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("Import from WorkoutCreator")
                .font(.title2.bold())

            Text("A WorkoutCreator database was found from the previous version. Would you like to import your workouts?")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 300)

            if let count = importedCount {
                Text("Imported \(count) workout\(count == 1 ? "" : "s").")
                    .foregroundStyle(.green)
            }

            if let error {
                Text("Error: \(error)")
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            HStack(spacing: 12) {
                Button("Skip") {
                    isPresented = false
                }
                .buttonStyle(.bordered)

                Button(importedCount == nil ? "Import" : "Done") {
                    if importedCount != nil {
                        isPresented = false
                    } else {
                        performImport()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isImporting)
            }
        }
        .padding(40)
        .frame(width: 420, height: 280)
    }

    private func performImport() {
        isImporting = true
        error = nil
        Task {
            do {
                let count = try LegacyImporter.import(
                    into: AppDatabase.shared.dbQueue,
                    memberID: 1
                )
                importedCount = count
                store.load(memberID: 1)
            } catch let e {
                error = e.localizedDescription
            }
            isImporting = false
        }
    }
}

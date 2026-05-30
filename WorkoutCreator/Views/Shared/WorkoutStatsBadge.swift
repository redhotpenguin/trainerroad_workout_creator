import SwiftUI

struct WorkoutStatsBadge: View {
    var tss: Double
    var durationSeconds: Double

    private var durationText: String {
        let hours = Int(durationSeconds) / 3600
        let minutes = (Int(durationSeconds) % 3600) / 60
        return String(format: "%d:%02d", hours, minutes)
    }

    var body: some View {
        HStack(spacing: 8) {
            Label("\(Int(tss.rounded())) TSS", systemImage: "bolt.fill")
            Text("·")
            Text(durationText)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

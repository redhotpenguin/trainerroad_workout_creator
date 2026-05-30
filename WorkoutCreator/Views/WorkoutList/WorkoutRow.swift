import SwiftUI

struct WorkoutRow: View {
    var workout: WorkoutFile

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(workout.name)
                        .lineLimit(1)
                    if workout.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                    }
                    if workout.isDirty {
                        Circle()
                            .fill(.orange)
                            .frame(width: 6, height: 6)
                    }
                }
                WorkoutStatsBadge(tss: workout.tss, durationSeconds: workout.duration)
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

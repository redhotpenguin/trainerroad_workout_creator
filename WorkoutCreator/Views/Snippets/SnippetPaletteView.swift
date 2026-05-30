import SwiftUI
import Charts

struct SnippetPaletteView: View {
    @Environment(WorkoutStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(store.snippetList) { snippet in
                        SnippetTile(snippet: snippet) {
                            appendSnippet(snippet)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .frame(height: 100)
        }
    }

    private func appendSnippet(_ snippet: WorkoutFile) {
        guard var details = store.currentDetails,
              let contents = snippet.fileContents,
              let parsed = try? MRCParser.parse(contents)
        else { return }

        let endMinutes = details.workoutPoints.last?.minutes ?? 0
        let shifted = parsed.details.workoutPoints.map {
            WorkoutPoint(minutes: $0.minutes + endMinutes, ftpPercent: $0.ftpPercent)
        }
        // Remove duplicate at junction if same power level
        if let last = details.workoutPoints.last, let first = shifted.first,
           last.ftpPercent == first.ftpPercent {
            details.workoutPoints.removeLast()
        }
        details.workoutPoints.append(contentsOf: shifted)

        let endSeconds = Int(endMinutes * 60)
        let shiftedIntervals = parsed.details.intervals.map { interval in
            WorkoutInterval(
                startSeconds: interval.startSeconds + endSeconds,
                endSeconds: interval.endSeconds + endSeconds,
                name: interval.name
            )
        }
        details.intervals.append(contentsOf: shiftedIntervals)

        let shiftedCues = parsed.details.cuePoints.map { cue in
            CuePoint(
                startSeconds: cue.startSeconds + endSeconds,
                durationSeconds: cue.durationSeconds,
                text: cue.text
            )
        }
        details.cuePoints.append(contentsOf: shiftedCues)

        store.currentDetails = details
        store.save()
    }
}

private struct SnippetTile: View {
    let snippet: WorkoutFile
    let onTap: () -> Void
    @State private var details: WorkoutDetails?

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(snippet.name)
                    .font(.caption2.bold())
                    .lineLimit(1)
                    .foregroundStyle(.primary)

                if let pts = details?.workoutPoints, !pts.isEmpty {
                    Chart {
                        ForEach(Array(pts.enumerated()), id: \.offset) { _, p in
                            AreaMark(
                                x: .value("t", p.minutes),
                                y: .value("pwr", p.ftpPercent)
                            )
                            .foregroundStyle(.blue.opacity(0.5))
                            .interpolationMethod(.stepEnd)
                        }
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .chartYScale(domain: 0...150)
                    .frame(height: 36)
                } else {
                    Rectangle()
                        .fill(.blue.opacity(0.1))
                        .frame(height: 36)
                }

                Text("\(Int(snippet.duration / 60))m")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(8)
            .frame(width: 100)
        }
        .buttonStyle(.plain)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onAppear {
            if let contents = snippet.fileContents,
               let result = try? MRCParser.parse(contents) {
                details = result.details
            }
        }
    }
}

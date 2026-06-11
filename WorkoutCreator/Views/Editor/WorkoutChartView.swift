import SwiftUI
import Charts

private struct PowerZoneSpec {
    let name: String
    let minPct: Double
    let maxPct: Double
    let color: Color
}

// Coggan / TrainingPeaks 7-level power training zones.
// See https://www.trainingpeaks.com/blog/power-training-levels/
private let kPowerZones: [PowerZoneSpec] = [
    PowerZoneSpec(name: "Z1", minPct: 0,   maxPct: 56,  color: .gray),
    PowerZoneSpec(name: "Z2", minPct: 56,  maxPct: 76,  color: .blue),
    PowerZoneSpec(name: "Z3", minPct: 76,  maxPct: 91,  color: .green),
    PowerZoneSpec(name: "Z4", minPct: 91,  maxPct: 106, color: .teal),
    PowerZoneSpec(name: "Z5", minPct: 106, maxPct: 121, color: .orange),
    PowerZoneSpec(name: "Z6", minPct: 121, maxPct: 151, color: .red),
    PowerZoneSpec(name: "Z7", minPct: 151, maxPct: 250, color: .purple),
]

struct WorkoutChartView: View {
    @Environment(WorkoutStore.self) private var store
    @AppStorage("userFTP") private var ftp: Int = 250

    private var intervals: [WorkoutInterval] {
        store.currentDetails?.intervals ?? []
    }

    // Derive points from intervals so the chart updates immediately on power /
    // length edits (workoutPoints only refreshes when save() runs). Falls back
    // to the stored workoutPoints when:
    //   - there are no intervals (ramps, course-only workouts), or
    //   - intervals don't cover the timeline contiguously (Tabata-style
    //     workouts with rest gaps between sprints — the MRC's COURSE DATA
    //     encodes the gap power, fabricating from intervals would smear the
    //     last sprint's power across the rest).
    private var points: [WorkoutPoint] {
        let ivs = intervals
        guard !ivs.isEmpty else {
            return store.currentDetails?.workoutPoints ?? []
        }
        let sorted = ivs.sorted { $0.startSeconds < $1.startSeconds }
        let isContiguous = zip(sorted, sorted.dropFirst())
            .allSatisfy { $0.endSeconds == $1.startSeconds }
        guard isContiguous else {
            return store.currentDetails?.workoutPoints ?? []
        }
        var result: [WorkoutPoint] = []
        for interval in sorted {
            let startMin = Double(interval.startSeconds) / 60
            let endMin   = Double(interval.endSeconds)   / 60
            result.append(WorkoutPoint(minutes: startMin, ftpPercent: interval.power))
            result.append(WorkoutPoint(minutes: endMin, ftpPercent: interval.power))
        }
        return result
    }

    private var maxMinutes: Double {
        max(points.last?.minutes ?? 60, 1)
    }

    private var metrics: PowerMetrics.Result {
        PowerMetrics.calculate(points)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            statsBar
            PowerZoneLegend()
            chart
        }
    }

    private var statsBar: some View {
        HStack(spacing: 16) {
            statLabel("NP", value: String(format: "%.0f%%", metrics.normalizedPower))
            statLabel("IF", value: String(format: "%.2f", metrics.intensityFactor))
            statLabel("TSS", value: String(format: "%.0f", metrics.tss))
            Spacer()
            statLabel("Duration", value: durationText)
        }
        .font(.caption)
    }

    private var durationText: String {
        let totalSecs = Int(maxMinutes * 60)
        let h = totalSecs / 3600
        let m = (totalSecs % 3600) / 60
        return h > 0 ? "\(h)h\(m)m" : "\(m)m"
    }

    private func statLabel(_ title: String, value: String) -> some View {
        HStack(spacing: 2) {
            Text(title).foregroundStyle(.secondary)
            Text(value).fontWeight(.medium)
        }
    }

    private var chart: some View {
        Chart {
            // Power zone bands
            ForEach(kPowerZones, id: \.name) { zone in
                RectangleMark(
                    xStart: .value("Start", 0),
                    xEnd: .value("End", maxMinutes),
                    yStart: .value("Min", zone.minPct),
                    yEnd: .value("Max", zone.maxPct)
                )
                .foregroundStyle(zone.color.opacity(0.12))
            }

            // Power curve
            ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                AreaMark(
                    x: .value("Minutes", point.minutes),
                    y: .value("FTP%", point.ftpPercent)
                )
                .foregroundStyle(.blue.opacity(0.25))
                .interpolationMethod(.stepStart)

                LineMark(
                    x: .value("Minutes", point.minutes),
                    y: .value("FTP%", point.ftpPercent)
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
                .interpolationMethod(.stepStart)
            }

            // Interval regions + boundary lines
            ForEach(Array(intervals.enumerated()), id: \.element.id) { i, interval in
                let startMin = Double(interval.startSeconds) / 60
                let endMin = Double(interval.endSeconds) / 60
                let colors: [Color] = [.orange, .teal, .green, .purple, .red]
                let color = colors[i % colors.count]

                RectangleMark(
                    xStart: .value("Start", startMin),
                    xEnd: .value("End", endMin),
                    yStart: .value("Min", 0),
                    yEnd: .value("Max", 150)
                )
                .foregroundStyle(color.opacity(0.07))

                if startMin > 0 {
                    RuleMark(x: .value("Start", startMin))
                        .foregroundStyle(.secondary.opacity(0.4))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                }
                if endMin < maxMinutes {
                    RuleMark(x: .value("End", endMin))
                        .foregroundStyle(.secondary.opacity(0.4))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                }
            }

            // Control point dots — only at interval STARTS (even indices in the
            // start/end pair sequence) so each boundary gets one label showing
            // the new interval's percentage, not the outgoing one.
            ForEach(Array(points.enumerated()), id: \.offset) { i, point in
                if i % 2 == 0 {
                    PointMark(
                        x: .value("Minutes", point.minutes),
                        y: .value("FTP%", point.ftpPercent)
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(40)
                    .annotation(position: .top) {
                        VStack(spacing: 0) {
                            Text("\(Int(point.ftpPercent))%")
                            Text("\(Int(Double(ftp) * point.ftpPercent / 100))W")
                        }
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let min = value.as(Double.self) { Text("\(Int(min))m") }
                }
            }
        }
        .chartYAxis {
            // Trailing: FTP percent (with gridlines)
            AxisMarks(position: .trailing, values: .stride(by: 25)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let pct = value.as(Double.self) { Text("\(Int(pct))%") }
                }
            }
            // Leading: power in watts at the same percentage levels (FTP × pct ÷ 100)
            AxisMarks(position: .leading, values: .stride(by: 25)) { value in
                AxisValueLabel {
                    if let pct = value.as(Double.self) {
                        Text("\(Int(Double(ftp) * pct / 100)) W")
                    }
                }
            }
        }
        .chartYScale(domain: 0...150)
        .chartXScale(domain: 0...maxMinutes)
        .frame(height: 200)
    }
}

import SwiftUI
import Charts

private struct PowerZoneSpec {
    let name: String
    let minPct: Double
    let maxPct: Double
    let color: Color
}

private let kPowerZones: [PowerZoneSpec] = [
    PowerZoneSpec(name: "Z1", minPct: 0,   maxPct: 56,  color: .gray),
    PowerZoneSpec(name: "Z2", minPct: 56,  maxPct: 76,  color: .blue),
    PowerZoneSpec(name: "Z3", minPct: 76,  maxPct: 88,  color: .green),
    PowerZoneSpec(name: "SS", minPct: 88,  maxPct: 95,  color: .yellow),
    PowerZoneSpec(name: "Z4", minPct: 95,  maxPct: 106, color: .orange),
    PowerZoneSpec(name: "Z5", minPct: 106, maxPct: 121, color: .red),
    PowerZoneSpec(name: "Z6", minPct: 121, maxPct: 150, color: .purple),
]

struct WorkoutChartView: View {
    @Environment(WorkoutStore.self) private var store

    private var points: [WorkoutPoint] {
        store.currentDetails?.workoutPoints ?? []
    }

    private var intervals: [WorkoutInterval] {
        store.currentDetails?.intervals ?? []
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
                RuleMark(x: .value("Label", startMin + (endMin - startMin) / 2))
                    .opacity(0)
                    .annotation(position: .top, alignment: .center) {
                        Text(interval.name)
                            .font(.system(size: 9))
                            .foregroundStyle(color.opacity(0.8))
                            .lineLimit(1)
                            .fixedSize()
                    }
                if endMin < maxMinutes {
                    RuleMark(x: .value("End", endMin))
                        .foregroundStyle(.secondary.opacity(0.4))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                }
            }

            // Control point dots
            ForEach(Array(points.enumerated()), id: \.offset) { i, point in
                PointMark(
                    x: .value("Minutes", point.minutes),
                    y: .value("FTP%", point.ftpPercent)
                )
                .foregroundStyle(.blue)
                .symbolSize(40)
                .annotation(position: .top) {
                    Text("\(Int(point.ftpPercent))%")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
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
            AxisMarks(values: .stride(by: 25)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let pct = value.as(Double.self) { Text("\(Int(pct))%") }
                }
            }
        }
        .chartYScale(domain: 0...150)
        .chartXScale(domain: 0...maxMinutes)
        .frame(height: 200)
    }
}

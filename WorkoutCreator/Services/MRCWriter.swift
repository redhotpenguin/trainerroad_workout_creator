import Foundation

struct MRCWriter {
    static func write(
        name: String,
        intensityFactor: Double,
        tss: Double,
        memberID: Int,
        details: WorkoutDetails
    ) -> String {
        var lines: [String] = []

        lines.append("[COURSE HEADER]")
        lines.append("VERSION = 0")
        lines.append("UNITS = ENGLISH")
        lines.append(String(format: "DESCRIPTION = %@,%.2f,%.0f. Created by %d.", name, intensityFactor, tss, memberID))
        lines.append("FILE NAME = none")
        lines.append("MINUTES\tFTP")
        lines.append("[END COURSE HEADER]")
        lines.append("")

        lines.append("[COURSE DATA]")
        for point in details.workoutPoints {
            lines.append("\(formatMinutes(point.minutes))\t\(Int(point.ftpPercent))")
        }
        lines.append("[END COURSE DATA]")
        lines.append("")

        lines.append("[COURSE TEXT]")
        for cue in details.cuePoints {
            lines.append("\(cue.startSeconds)\t\(cue.durationSeconds)\t\(cue.text)")
        }
        lines.append("[END COURSE TEXT]")
        lines.append("")

        lines.append("[INTERVAL DATA]")
        for interval in details.intervals {
            lines.append("\(interval.startSeconds)\t\(interval.endSeconds)\t\(interval.name)")
        }
        lines.append("[END INTERVAL DATA]")
        lines.append("")

        lines.append("[MODE DATA]")
        lines.append("[END MODE DATA]")
        lines.append("")

        return lines.joined(separator: "\r\n")
    }

    private static func formatMinutes(_ minutes: Double) -> String {
        if minutes == Double(Int(minutes)) {
            return "\(Int(minutes))"
        }
        return String(format: "%.4f", minutes)
    }
}

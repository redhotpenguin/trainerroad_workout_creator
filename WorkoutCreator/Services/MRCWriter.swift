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

        // TR's player reads ahead past the last point at the end of the workout,
        // so we pad COURSE DATA by 60s past the last interval at the same power
        // level. Without this, native (locally-created) workouts crash TR at the
        // finish line — see the 4x4 w/ 4 rest analysis.
        let lastInterval = details.intervals.last
        let padEndSec = (lastInterval?.endSeconds ?? 0) + 60
        let padMin = Double(padEndSec) / 60.0
        let padPower = lastInterval?.power ?? 0

        lines.append("[COURSE DATA]")
        for point in details.workoutPoints {
            lines.append("\(formatMinutes(point.minutes))\t\(Int(point.ftpPercent))")
        }
        if lastInterval != nil {
            lines.append("\(formatMinutes(padMin))\t\(Int(padPower))")
        }
        lines.append("[END COURSE DATA]")
        lines.append("")

        lines.append("[COURSE TEXT]")
        // TR's format: start\ttext\t<font/color fields>. We round-trip the
        // suffix verbatim so the rendering stays consistent with what TR shipped.
        for cue in details.cuePoints {
            lines.append("\(cue.startSeconds)\t\(cue.text)\t\(cue.formatSuffix)")
        }
        lines.append("[END COURSE TEXT]")
        lines.append("")

        lines.append("[INTERVAL DATA]")
        // Meta-interval matches the legacy TR pattern: spans from 0 past the
        // last interval end. Without it TR has no fallback when its state
        // machine looks up "what interval is active" past the last sub-interval.
        if lastInterval != nil {
            lines.append("0\t\(padEndSec)\tWorkout")
        }
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

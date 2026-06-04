import Foundation

enum MRCParseError: Error {
    case missingSectionBoundary(String)
    case invalidDescriptionFormat
    case invalidDataRow(String)
}

struct MRCParser {
    struct Result {
        var name: String
        var intensityFactor: Double
        var tss: Double
        var memberID: Int
        var details: WorkoutDetails
    }

    static func parse(_ text: String) throws -> Result {
        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }

        let headerLines = try extractSection(lines, start: "[COURSE HEADER]", end: "[END COURSE HEADER]")
        let (name, intensityFactor, tss, memberID) = try parseHeader(headerLines)

        let dataLines = try extractSection(lines, start: "[COURSE DATA]", end: "[END COURSE DATA]")
        let workoutPoints = try parseDataLines(dataLines)

        let intervalLines = (try? extractSection(lines, start: "[INTERVAL DATA]", end: "[END INTERVAL DATA]")) ?? []
        var intervals = try parseIntervalLines(intervalLines)
        // Drop the leading meta-"Workout" interval (legacy MRC pattern that
        // MRCWriter now also emits): when intervals[0] is named "Workout" and
        // overlaps intervals[1]'s start, it's a span/fallback, not a real one.
        if intervals.count >= 2,
           intervals[0].name == "Workout",
           intervals[0].endSeconds > intervals[1].startSeconds {
            intervals.removeFirst()
        }
        // Populate power for each interval from the course data (step-end: power = last point at or before interval start)
        for i in intervals.indices {
            let startMin = Double(intervals[i].startSeconds) / 60
            let point = workoutPoints.last(where: { $0.minutes <= startMin + 0.01 }) ?? workoutPoints.first
            intervals[i].power = point?.ftpPercent ?? 50
        }

        let textLines = (try? extractSection(lines, start: "[COURSE TEXT]", end: "[END COURSE TEXT]")) ?? []
        let cuePoints = parseCueLines(textLines)

        return Result(
            name: name,
            intensityFactor: intensityFactor,
            tss: tss,
            memberID: memberID,
            details: WorkoutDetails(
                workoutPoints: workoutPoints,
                intervals: intervals,
                cuePoints: cuePoints
            )
        )
    }

    private static func extractSection(_ lines: [String], start: String, end: String) throws -> [String] {
        guard let startIdx = lines.firstIndex(where: { $0.uppercased() == start.uppercased() }),
              let endIdx = lines.firstIndex(where: { $0.uppercased() == end.uppercased() }),
              endIdx > startIdx
        else {
            throw MRCParseError.missingSectionBoundary(start)
        }
        return Array(lines[(startIdx + 1)..<endIdx]).filter { !$0.isEmpty }
    }

    private static func parseHeader(_ lines: [String]) throws -> (name: String, if: Double, tss: Double, memberID: Int) {
        guard let descLine = lines.first(where: { $0.uppercased().hasPrefix("DESCRIPTION") }) else {
            throw MRCParseError.invalidDescriptionFormat
        }
        // Format: DESCRIPTION = Name,IF,TSS. Created by MemberID.
        guard let eqRange = descLine.range(of: "=") else {
            throw MRCParseError.invalidDescriptionFormat
        }
        let value = String(descLine[eqRange.upperBound...]).trimmingCharacters(in: .whitespaces)

        // Split on comma
        let parts = value.components(separatedBy: ",")
        guard parts.count >= 3 else {
            throw MRCParseError.invalidDescriptionFormat
        }
        let name = parts[0].trimmingCharacters(in: .whitespaces)
        let ifValue = Double(parts[1].trimmingCharacters(in: .whitespaces)) ?? 0

        // TSS may be followed by ". Created by N."
        let tssRaw = parts[2].components(separatedBy: ".").first?.trimmingCharacters(in: .whitespaces) ?? ""
        let tssValue = Double(tssRaw) ?? 0

        // Extract memberID: "... Created by 3238."
        var memberID = 0
        if let range = value.range(of: "Created by ") {
            let afterPrefix = value[range.upperBound...]
            let idStr = afterPrefix.components(separatedBy: CharacterSet(charactersIn: ".")).first ?? ""
            memberID = Int(idStr.trimmingCharacters(in: .whitespaces)) ?? 0
        }

        return (name, ifValue, tssValue, memberID)
    }

    private static func parseDataLines(_ lines: [String]) throws -> [WorkoutPoint] {
        // Skip the "MINUTES FTP" header line
        let dataLines = lines.filter { line in
            let lower = line.lowercased()
            return !lower.hasPrefix("minutes") && !lower.hasPrefix("version") &&
                   !lower.hasPrefix("units") && !lower.hasPrefix("description") &&
                   !lower.hasPrefix("file name")
        }
        return try dataLines.map { line in
            let parts = line.components(separatedBy: CharacterSet.whitespaces.union(.init(charactersIn: "\t")))
                .filter { !$0.isEmpty }
            guard parts.count >= 2,
                  let minutes = Double(parts[0]),
                  let ftp = Double(parts[1])
            else {
                throw MRCParseError.invalidDataRow(line)
            }
            return WorkoutPoint(minutes: minutes, ftpPercent: ftp)
        }
    }

    private static func parseIntervalLines(_ lines: [String]) throws -> [WorkoutInterval] {
        return try lines.map { line in
            let parts = line.components(separatedBy: "\t")
            guard parts.count >= 3,
                  let start = Int(parts[0].trimmingCharacters(in: .whitespaces)),
                  let end = Int(parts[1].trimmingCharacters(in: .whitespaces))
            else {
                throw MRCParseError.invalidDataRow(line)
            }
            let name = parts[2...].joined(separator: "\t").trimmingCharacters(in: .whitespaces)
            return WorkoutInterval(startSeconds: start, endSeconds: end, name: name)
        }
    }

    // Skips lines we can't decode rather than failing the whole MRC parse —
    // cues are decorative and TR's actual format varies (legacy
    // `start\tduration\ttext` vs newer `start\ttext\t<font fields>`).
    private static func parseCueLines(_ lines: [String]) -> [CuePoint] {
        lines.compactMap { line in
            let parts = line.components(separatedBy: "\t")
                .map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count >= 2, let start = Int(parts[0]) else { return nil }
            // Legacy: parts[1] is duration (an Int), text follows.
            if let duration = Int(parts[1]), parts.count >= 3 {
                let text = parts[2...].joined(separator: "\t").trimmingCharacters(in: .whitespaces)
                return CuePoint(startSeconds: start, durationSeconds: duration, text: text)
            }
            // TR format: parts[1] is the cue text; parts[2...] are opaque font/
            // color fields we round-trip verbatim.
            let text = parts[1]
            let suffix = parts.count > 2
                ? parts[2...].joined(separator: "\t")
                : "8\t0\t0\t72\t16777215\t0"
            return CuePoint(startSeconds: start, durationSeconds: 5, text: text, formatSuffix: suffix)
        }
    }
}

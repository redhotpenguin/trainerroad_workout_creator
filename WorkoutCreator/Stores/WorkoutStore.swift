import Foundation
import Observation

@Observable
final class WorkoutStore {
    var workoutList: [WorkoutFile] = []
    var snippetList: [WorkoutFile] = []
    var currentWorkout: WorkoutFile?
    var currentDetails: WorkoutDetails?
    var selectedWorkoutID: Int?

    private let repo: WorkoutRepository

    init(repo: WorkoutRepository = WorkoutRepository()) {
        self.repo = repo
    }

    func load(memberID: Int) {
        do {
            var list = try repo.fetchAll(memberID: memberID)
            // Heal stale Duration values from the MRC (source of truth) so the
            // sidebar shows the real workout length, not the blank-template 3600.
            for i in list.indices {
                guard let contents = list[i].fileContents,
                      let result = try? MRCParser.parse(contents),
                      let lastEnd = result.details.intervals.last?.endSeconds,
                      lastEnd > 0
                else { continue }
                list[i].duration = Double(lastEnd)
            }
            workoutList = list
            snippetList = try repo.fetchSnippets(memberID: memberID)
        } catch {
            workoutList = []
            snippetList = []
        }
    }

    func select(_ workout: WorkoutFile) {
        currentWorkout = workout
        selectedWorkoutID = workout.id
        if let contents = workout.fileContents,
           let result = try? MRCParser.parse(contents) {
            currentDetails = result.details
        } else {
            currentDetails = WorkoutDetails(workoutPoints: [], intervals: [], cuePoints: [])
        }
    }

    func save() {
        guard var workout = currentWorkout,
              var details = currentDetails,
              let memberID = Optional(workout.memberID)
        else { return }

        // Auto-name intervals that haven't been given a custom name. Names follow
        // the legacy TR pattern: "<Zone> <N>" where N is the sequence within
        // that zone in time order. Anything that doesn't match the empty /
        // "<Zone>"  / "<Zone> <digits>" shape is treated as user-customized and
        // left alone (but still counted so auto siblings stay sequential).
        var byStart = details.intervals.sorted { $0.startSeconds < $1.startSeconds }
        var counts: [String: Int] = [:]
        for i in byStart.indices {
            let zone = Self.powerZoneName(for: byStart[i].power)
            counts[zone, default: 0] += 1
            if Self.isAutoIntervalName(byStart[i].name) {
                byStart[i].name = "\(zone) \(counts[zone]!)"
            }
        }
        details.intervals = byStart

        // Derive the power curve from intervals (sorted by start time).
        // Always emit both start and end points per interval. Two points at the
        // same minute encode a step transition in MRC; collapsing them makes the
        // player interpolate linearly between intervals (producing a ramp).
        let sorted = byStart
        var points: [WorkoutPoint] = []
        for interval in sorted {
            let startMin = Double(interval.startSeconds) / 60
            let endMin   = Double(interval.endSeconds)   / 60
            points.append(WorkoutPoint(minutes: startMin, ftpPercent: interval.power))
            points.append(WorkoutPoint(minutes: endMin, ftpPercent: interval.power))
        }
        // Always overwrite — deleting an interval needs to be reflected, even
        // when `points` shrinks (or becomes empty for an emptied workout).
        details.workoutPoints = points

        let mrc = MRCWriter.write(
            name: workout.name,
            intensityFactor: workout.intensityFactor,
            tss: workout.tss,
            memberID: memberID,
            details: details
        )
        workout.fileContents = mrc

        let metrics = PowerMetrics.calculate(details.workoutPoints)
        workout.intensityFactor = metrics.intensityFactor * 100
        workout.tss = metrics.tss
        // Duration is what TR shows in its UI — derive from the last interval's end.
        if let lastEnd = sorted.last?.endSeconds {
            workout.duration = Double(lastEnd)
        }
        workout.hasText = !details.cuePoints.isEmpty
        workout.isDirty = true
        workout.lastUpdate = ISO8601DateFormatter().string(from: Date())

        do {
            try repo.save(&workout)
            currentWorkout = workout
            currentDetails = details          // update chart data with derived points
            if let id = workout.id {
                if let idx = workoutList.firstIndex(where: { $0.id == id }) {
                    workoutList[idx] = workout
                }
            }
        } catch {}
    }

    func newWorkout(memberID: Int) {
        var workout = WorkoutFile.blank(memberID: memberID)
        let defaultPoints = [
            WorkoutPoint(minutes: 0, ftpPercent: 50),
            WorkoutPoint(minutes: 60, ftpPercent: 50)
        ]
        let details = WorkoutDetails(
            workoutPoints: defaultPoints,
            intervals: [WorkoutInterval(startSeconds: 0, endSeconds: 3600, name: "", power: 50)],
            cuePoints: []
        )
        let mrc = MRCWriter.write(
            name: workout.name,
            intensityFactor: 0.5,
            tss: 25,
            memberID: memberID,
            details: details
        )
        workout.fileContents = mrc
        workout.duration = 3600
        do {
            try repo.save(&workout)
            workoutList.insert(workout, at: 0)
            select(workout)
        } catch {}
    }

    // Coggan / TrainingPeaks 7-level power training zones.
    static let zoneNames = [
        "Active Recovery", "Endurance", "Tempo",
        "Lactate Threshold", "VO2 Max", "Anaerobic Capacity", "Neuromuscular"
    ]

    static func powerZoneName(for power: Double) -> String {
        switch power {
        case ..<56:     return "Active Recovery"
        case 56..<76:   return "Endurance"
        case 76..<91:   return "Tempo"
        case 91..<106:  return "Lactate Threshold"
        case 106..<121: return "VO2 Max"
        case 121..<151: return "Anaerobic Capacity"
        default:        return "Neuromuscular"
        }
    }

    static func isAutoIntervalName(_ name: String) -> Bool {
        if name.isEmpty { return true }
        for zone in zoneNames {
            if name == zone { return true }
            let prefix = "\(zone) "
            if name.hasPrefix(prefix),
               Int(name.dropFirst(prefix.count)) != nil {
                return true
            }
        }
        return false
    }

    func delete(_ workout: WorkoutFile) {
        guard let id = workout.id else { return }
        do {
            try repo.softDelete(id: id)
            workoutList.removeAll { $0.id == id }
            if currentWorkout?.id == id {
                currentWorkout = nil
                currentDetails = nil
            }
        } catch {}
    }
}

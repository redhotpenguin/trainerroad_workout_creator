import Foundation
import Observation

@Observable
final class WorkoutStore {
    var workoutList: [WorkoutFile] = []
    var snippetList: [WorkoutFile] = []
    var currentWorkout: WorkoutFile?
    var currentDetails: WorkoutDetails?

    private let repo: WorkoutRepository

    init(repo: WorkoutRepository = WorkoutRepository()) {
        self.repo = repo
    }

    func load(memberID: Int) {
        do {
            workoutList = try repo.fetchAll(memberID: memberID)
            snippetList = try repo.fetchSnippets(memberID: memberID)
        } catch {
            workoutList = []
            snippetList = []
        }
    }

    func select(_ workout: WorkoutFile) {
        currentWorkout = workout
        if let contents = workout.fileContents,
           let result = try? MRCParser.parse(contents) {
            currentDetails = result.details
        } else {
            currentDetails = WorkoutDetails(workoutPoints: [], intervals: [], cuePoints: [])
        }
    }

    func save() {
        guard var workout = currentWorkout,
              let details = currentDetails,
              let memberID = Optional(workout.memberID)
        else { return }

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
        workout.isDirty = true
        workout.lastUpdate = ISO8601DateFormatter().string(from: Date())

        do {
            try repo.save(&workout)
            currentWorkout = workout
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
            intervals: [WorkoutInterval(startSeconds: 0, endSeconds: 3600, name: "Workout")],
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

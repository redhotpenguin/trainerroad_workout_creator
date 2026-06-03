import Foundation
import Observation

@MainActor
@Observable
final class WorkoutSyncService {
    var isSyncing = false
    var lastSyncDate: Date?
    var progress: Double = 0
    var lastError: String?

    private let repo: WorkoutRepository

    init(repo: WorkoutRepository = WorkoutRepository()) {
        self.repo = repo
    }

    // IDs we've already downloaded and classified (persisted so we skip them next launch)
    private var processedIDs: Set<Int> {
        get {
            let arr = UserDefaults.standard.array(forKey: "syncProcessedIDs") as? [Int] ?? []
            return Set(arr)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: "syncProcessedIDs")
        }
    }

    func sync(client: TrainerRoadClient, userMemberID: Int) async {
        guard !isSyncing else { return }
        isSyncing = true
        lastError = nil
        progress = 0
        defer {
            isSyncing = false
            lastSyncDate = Date()
        }

        do {
            // 1. Fetch server ID list
            let serverIDs = try await client.fetchWorkoutIDs()
            print("[Sync] Server has \(serverIDs.count) workout IDs")

            let serverMap = Dictionary(uniqueKeysWithValues: serverIDs.map { ($0.id, $0.updated) })
            let localRecords = try repo.fetchIDs()
            let localIDSet = Set(localRecords.map { $0.id })
            var seen = processedIDs

            // Only download IDs that are new to us (not local, not previously processed)
            let toDownload = serverIDs
                .map { $0.id }
                .filter { !localIDSet.contains($0) && !seen.contains($0) }

            print("[Sync] Local has \(localRecords.count), need to download \(toDownload.count) unprocessed IDs")
            progress = 0.2

            // 2. Download in batches of 25, save only user's own workouts
            let batchSize = 25
            let batches = stride(from: 0, to: toDownload.count, by: batchSize).map {
                Array(toDownload[$0..<min($0 + batchSize, toDownload.count)])
            }
            var saved = 0
            for (i, batch) in batches.enumerated() {
                do {
                    let workouts = try await client.fetchWorkouts(ids: batch)
                    for var w in workouts {
                        if w.memberID == userMemberID {
                            try repo.save(&w)
                            saved += 1
                        }
                    }
                } catch {
                    print("[Sync] Batch \(i) failed: \(error)")
                }
                // Persist progress after every batch so a quit mid-sync doesn't restart from zero
                batch.forEach { seen.insert($0) }
                processedIDs = seen
                progress = 0.2 + 0.6 * (Double(i + 1) / Double(max(batches.count, 1)))
            }
            print("[Sync] Saved \(saved) user workouts")

            // 3. Push dirty workouts
            let serverIDSet = Set(serverMap.keys)
            let dirty = try repo.fetchDirty()
            print("[Sync] Pushing \(dirty.count) dirty workouts")
            for (i, workout) in dirty.enumerated() {
                let isNew = !serverIDSet.contains(workout.id ?? -1)
                do {
                    let result = try await client.publishWorkout(workout, isNew: isNew)
                    if result.isSuccessful, let oldID = workout.id {
                        try repo.markSynced(
                            id: oldID,
                            newID: result.workoutFileID,
                            lastUpdate: result.lastUpdate ?? "",
                            lastUpdateTicks: 0
                        )
                        print("[Sync] Published workout \(oldID) → \(result.workoutFileID)")
                    } else {
                        print("[Sync] Publish failed for workout \(workout.id ?? -1): isSuccessful=\(result.isSuccessful)")
                    }
                } catch {
                    print("[Sync] Publish error for workout \(workout.id ?? -1): \(error)")
                }
                progress = 0.8 + 0.2 * (Double(i + 1) / Double(max(dirty.count, 1)))
            }

            // 4. Soft-delete local workouts absent from server, but keep dirty (unsynced) ones
            for record in localRecords where !serverIDSet.contains(record.id) && !record.isDirty {
                try repo.softDelete(id: record.id)
            }

            // 5. Push local soft-deletes up to the server. Locally-inactive workouts
            // that still exist on the server are ghosts (often from prior failed publishes
            // before the decode bug was fixed). "Delete" on TR is a PUT with
            // IsActive=false; afterwards we hard-delete the local row.
            let toDeleteOnServer = localRecords.filter { !$0.isActive && serverIDSet.contains($0.id) }
            if !toDeleteOnServer.isEmpty {
                print("[Sync] Deleting \(toDeleteOnServer.count) ghost workouts from server")
            }
            for record in toDeleteOnServer {
                guard let workout = try? repo.fetchAny(id: record.id) else { continue }
                do {
                    try await client.deleteWorkout(workout)
                    try repo.hardDelete(id: record.id)
                    print("[Sync] Deleted server workout \(record.id)")
                } catch {
                    print("[Sync] Delete error for workout \(record.id): \(error)")
                }
            }

            progress = 1.0
        } catch {
            lastError = error.localizedDescription
            print("[Sync] Failed: \(error)")
        }
    }

    func clearProcessedIDs() {
        UserDefaults.standard.removeObject(forKey: "syncProcessedIDs")
    }
}

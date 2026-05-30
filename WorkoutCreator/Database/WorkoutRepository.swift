import Foundation
import GRDB

final class WorkoutRepository {
    private let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue = AppDatabase.shared.dbQueue) {
        self.dbQueue = dbQueue
    }

    func fetchAll(memberID: Int) throws -> [WorkoutFile] {
        try dbQueue.read { db in
            try WorkoutFile
                .filter(Column("MemberID") == memberID)
                .filter(Column("IsActive") == true)
                .filter(Column("WorkoutFileID") != -1)
                .order(Column("IsFavorite").desc, Column("WorkoutFileID").desc)
                .fetchAll(db)
        }
    }

    func fetchSnippets(memberID: Int) throws -> [WorkoutFile] {
        try dbQueue.read { db in
            try WorkoutFile
                .filter(Column("MemberID") == memberID)
                .filter(Column("WorkoutFileID") == -1)
                .order(Column("SortOrder"))
                .fetchAll(db)
        }
    }

    func fetch(id: Int) throws -> WorkoutFile? {
        try dbQueue.read { db in
            try WorkoutFile
                .filter(Column("WorkoutFileID") == id)
                .filter(Column("IsActive") == true)
                .fetchOne(db)
        }
    }

    func save(_ workout: inout WorkoutFile) throws {
        try dbQueue.write { db in
            try workout.save(db)
        }
    }

    func softDelete(id: Int) throws {
        try dbQueue.write { db in
            try db.execute(
                sql: "UPDATE workoutFile SET IsActive = 0 WHERE WorkoutFileID = ?",
                arguments: [id]
            )
        }
    }

    func markDirty(id: Int) throws {
        try dbQueue.write { db in
            try db.execute(
                sql: "UPDATE workoutFile SET IsDirty = 1 WHERE WorkoutFileID = ?",
                arguments: [id]
            )
        }
    }

    func markSynced(id: Int, newID: Int, lastUpdate: String, lastUpdateTicks: Double) throws {
        try dbQueue.write { db in
            try db.execute(
                sql: """
                    UPDATE workoutFile
                    SET WorkoutFileID = ?, LastUpdate = ?, LastUpdateTicks = ?, IsDirty = 0
                    WHERE WorkoutFileID = ?
                    """,
                arguments: [newID, lastUpdate, lastUpdateTicks, id]
            )
        }
    }

    func updateSortOrder(id: Int, sortOrder: Int) throws {
        try dbQueue.write { db in
            try db.execute(
                sql: "UPDATE workoutFile SET SortOrder = ? WHERE WorkoutFileID = ?",
                arguments: [sortOrder, id]
            )
        }
    }

    func fetchDirty() throws -> [WorkoutFile] {
        try dbQueue.read { db in
            try WorkoutFile
                .filter(Column("IsDirty") == true)
                .filter(Column("WorkoutFileID") != -1)
                .fetchAll(db)
        }
    }

    struct WorkoutIDRecord {
        var id: Int
        var lastUpdateTicks: Double
        var isDirty: Bool
    }

    func fetchIDs() throws -> [WorkoutIDRecord] {
        try dbQueue.read { db in
            let rows = try Row.fetchAll(
                db,
                sql: "SELECT WorkoutFileID, LastUpdateTicks, IsDirty FROM workoutFile WHERE WorkoutFileID != -1"
            )
            return rows.map { WorkoutIDRecord(id: $0["WorkoutFileID"], lastUpdateTicks: $0["LastUpdateTicks"], isDirty: $0["IsDirty"]) }
        }
    }
}

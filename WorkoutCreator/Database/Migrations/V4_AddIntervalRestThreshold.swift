import GRDB

struct V4_AddIntervalRestThreshold: DatabaseMigration {
    static let identifier = "v4_interval_rest_threshold"

    static func migrate(_ db: Database) throws {
        let wfColumns = try db.columns(in: "workoutFile").map { $0.name.lowercased() }
        if !wfColumns.contains("intervalrestthreshold") {
            try db.execute(sql: "ALTER TABLE workoutFile ADD COLUMN IntervalRestThreshold INTEGER")
        }
    }
}

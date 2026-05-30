import GRDB

struct V2_AddVideoFields: DatabaseMigration {
    static let identifier = "v2_video_fields"

    static func migrate(_ db: Database) throws {
        // version2 additions: trainer extras, device UUID, workoutData extras
        let tableExists = try db.tableExists("workoutSummary")
        guard tableExists else { return }

        // Safe ALTER TABLE — only add if column doesn't already exist
        let wfColumns = try db.columns(in: "workoutFile").map { $0.name.lowercased() }
        if !wfColumns.contains("videolocation") {
            try db.execute(sql: "ALTER TABLE workoutFile ADD COLUMN VideoLocation TEXT")
        }
        if !wfColumns.contains("hasvideo") {
            try db.execute(sql: "ALTER TABLE workoutFile ADD COLUMN HasVideo INTEGER DEFAULT 0")
        }
        if !wfColumns.contains("videoinstructionlink") {
            try db.execute(sql: "ALTER TABLE workoutFile ADD COLUMN VideoInstructionLink TEXT")
        }
        if !wfColumns.contains("videopreviewlink") {
            try db.execute(sql: "ALTER TABLE workoutFile ADD COLUMN VideoPreviewLink TEXT")
        }
        if !wfColumns.contains("videopublisherid") {
            try db.execute(sql: "ALTER TABLE workoutFile ADD COLUMN VideoPublisherID INTEGER DEFAULT 0")
        }

        // version3 additions: workoutSummary rolldown + Wahoo
        let wsColumns = try db.columns(in: "workoutSummary").map { $0.name.lowercased() }
        if !wsColumns.contains("rolldowntime") {
            try db.execute(sql: "ALTER TABLE workoutSummary ADD COLUMN RolldownTime REAL")
        }
        if !wsColumns.contains("wahooconsolexversion") {
            try db.execute(sql: "ALTER TABLE workoutSummary ADD COLUMN WahooConsoleXVersion TEXT")
        }
    }
}

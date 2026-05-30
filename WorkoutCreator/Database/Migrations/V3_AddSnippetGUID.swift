import GRDB

struct V3_AddSnippetGUID: DatabaseMigration {
    static let identifier = "v3_snippet_guid"

    static func migrate(_ db: Database) throws {
        let wfColumns = try db.columns(in: "workoutFile").map { $0.name.lowercased() }
        if !wfColumns.contains("snippetguid") {
            try db.execute(sql: "ALTER TABLE workoutFile ADD COLUMN SnippetGUID TEXT")
        }

        // Rebuild WorkoutFileID index and add SnippetGUID index
        try db.execute(sql: "DROP INDEX IF EXISTS INX_WorkoutFileID")
        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS INX_WorkoutFileID
            ON workoutFile (WorkoutFileID)
            """)
        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS INX_SnippetGUID
            ON workoutFile (SnippetGUID)
            """)
    }
}

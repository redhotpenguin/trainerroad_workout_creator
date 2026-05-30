import GRDB

struct V5_FixWorkoutFilePrimaryKey: DatabaseMigration {
    static let identifier = "v5_fix_workoutfile_primary_key"

    static func migrate(_ db: Database) throws {
        // Recreate table with WorkoutFileID as INTEGER PRIMARY KEY (SQLite rowid alias),
        // deduplicating rows that share the same WorkoutFileID (keep the one with max rowid).
        try db.execute(sql: """
            CREATE TABLE workoutFile_new (
                WorkoutFileID   INTEGER PRIMARY KEY,
                Name            TEXT,
                FileURL         TEXT,
                FileByteArray   BLOB,
                FileContents    TEXT,
                Description     TEXT,
                ThumbnailURL    TEXT,
                ThumbnailByteArray BLOB,
                Duration        REAL,
                TSS             REAL,
                IntensityFactor REAL,
                Zones           BLOB,
                CreatedDate     TEXT,
                LastUpdate      TEXT,
                IsFavorite      INTEGER,
                SortOrder       INTEGER,
                MemberID        INTEGER,
                IsActive        INTEGER,
                HasText         INTEGER,
                Goals           TEXT,
                LastUpdateTicks REAL DEFAULT 0,
                FTPMultiplier   REAL DEFAULT 0,
                FTPHighThreshold REAL DEFAULT 0,
                FTPLowThreshold  REAL DEFAULT 0,
                LTHRMultiplier  REAL DEFAULT 0,
                LTHRHighThreshold REAL DEFAULT 0,
                LTHRLowThreshold  REAL DEFAULT 0,
                VideoLocation   TEXT,
                HasVideo        INTEGER DEFAULT 0,
                VideoInstructionLink TEXT,
                VideoPreviewLink     TEXT,
                VideoPublisherID     INTEGER DEFAULT 0,
                WorkoutFileGUID TEXT,
                IsDirty         INTEGER,
                SnippetGUID     TEXT,
                IntervalRestThreshold INTEGER
            )
            """)

        // Copy one row per WorkoutFileID (latest rowid wins for duplicates)
        try db.execute(sql: """
            INSERT OR IGNORE INTO workoutFile_new
            SELECT w.*
            FROM workoutFile w
            INNER JOIN (
                SELECT WorkoutFileID, MAX(rowid) AS maxrowid
                FROM workoutFile
                GROUP BY WorkoutFileID
            ) best ON w.WorkoutFileID = best.WorkoutFileID AND w.rowid = best.maxrowid
            """)

        try db.execute(sql: "DROP TABLE workoutFile")
        try db.execute(sql: "ALTER TABLE workoutFile_new RENAME TO workoutFile")

        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS INX_WorkoutFileID ON workoutFile (WorkoutFileID)
            """)
    }
}

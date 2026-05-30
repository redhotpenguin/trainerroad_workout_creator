import Foundation
import GRDB

struct LegacyImporter {
    static let legacyDBPath: String = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/Library/Application Support/com.trainerroad.tools.WorkoutCreator/Local Store/workouts.sqlite"
    }()

    static var hasLegacyDatabase: Bool {
        FileManager.default.fileExists(atPath: legacyDBPath)
    }

    static func `import`(into destQueue: DatabaseQueue, memberID: Int) throws -> Int {
        let srcQueue = try DatabaseQueue(path: legacyDBPath, configuration: {
            var cfg = Configuration()
            cfg.readonly = true
            return cfg
        }())

        let rows = try srcQueue.read { db in
            try Row.fetchAll(db, sql: """
                SELECT WorkoutFileID, Name, FileContents, FileByteArray,
                       FileURL, Description, Goals, Duration, TSS, IntensityFactor,
                       CreatedDate, LastUpdate, LastUpdateTicks, IsFavorite,
                       SortOrder, MemberID, IsActive, HasText, HasVideo,
                       IsDirty, SnippetGUID, FTPMultiplier, FTPLowThreshold,
                       FTPHighThreshold, LTHRMultiplier, LTHRLowThreshold,
                       LTHRHighThreshold, VideoLocation, VideoInstructionLink,
                       VideoPreviewLink, VideoPublisherID, IntervalRestThreshold
                FROM tblworkoutfile
                WHERE IsActive = 1
                """)
        }

        var imported = 0
        for row in rows {
            let existingID: Int? = row["WorkoutFileID"]
            // Skip if already present
            let exists = try destQueue.read { db in
                try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM workoutFile WHERE WorkoutFileID = ?",
                                arguments: [existingID]) ?? 0 > 0
            }
            guard !exists else { continue }

            try destQueue.write { db in
                try db.execute(
                    sql: """
                        INSERT OR IGNORE INTO workoutFile
                        (WorkoutFileID, Name, FileContents, FileByteArray, FileURL,
                         Description, Goals, Duration, TSS, IntensityFactor,
                         CreatedDate, LastUpdate, LastUpdateTicks, IsFavorite,
                         SortOrder, MemberID, IsActive, HasText, HasVideo, IsDirty,
                         SnippetGUID, FTPMultiplier, FTPLowThreshold, FTPHighThreshold,
                         LTHRMultiplier, LTHRLowThreshold, LTHRHighThreshold,
                         VideoLocation, VideoInstructionLink, VideoPreviewLink,
                         VideoPublisherID, IntervalRestThreshold)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
                                ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                        """,
                    arguments: StatementArguments([
                        row["WorkoutFileID"] as Int?,
                        row["Name"] as String?,
                        row["FileContents"] as String?,
                        row["FileByteArray"] as Data?,
                        row["FileURL"] as String?,
                        row["Description"] as String?,
                        row["Goals"] as String?,
                        row["Duration"] as Double?,
                        row["TSS"] as Double?,
                        row["IntensityFactor"] as Double?,
                        row["CreatedDate"] as String?,
                        row["LastUpdate"] as String?,
                        row["LastUpdateTicks"] as Double?,
                        row["IsFavorite"] as Int?,
                        row["SortOrder"] as Int?,
                        memberID,
                        row["IsActive"] as Int?,
                        row["HasText"] as Int?,
                        row["HasVideo"] as Int?,
                        0, // IsDirty = false after import
                        row["SnippetGUID"] as String?,
                        row["FTPMultiplier"] as Double?,
                        row["FTPLowThreshold"] as Double?,
                        row["FTPHighThreshold"] as Double?,
                        row["LTHRMultiplier"] as Double?,
                        row["LTHRLowThreshold"] as Double?,
                        row["LTHRHighThreshold"] as Double?,
                        row["VideoLocation"] as String?,
                        row["VideoInstructionLink"] as String?,
                        row["VideoPreviewLink"] as String?,
                        row["VideoPublisherID"] as Int?,
                        row["IntervalRestThreshold"] as Int?,
                    ])!
                )
            }
            imported += 1
        }
        return imported
    }
}

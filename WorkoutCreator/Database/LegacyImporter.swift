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
                        row["WorkoutFileID"] as Int? as DatabaseValueConvertible?,
                        row["Name"] as String? as DatabaseValueConvertible?,
                        row["FileContents"] as String? as DatabaseValueConvertible?,
                        row["FileByteArray"] as Data? as DatabaseValueConvertible?,
                        row["FileURL"] as String? as DatabaseValueConvertible?,
                        row["Description"] as String? as DatabaseValueConvertible?,
                        row["Goals"] as String? as DatabaseValueConvertible?,
                        row["Duration"] as Double? as DatabaseValueConvertible?,
                        row["TSS"] as Double? as DatabaseValueConvertible?,
                        row["IntensityFactor"] as Double? as DatabaseValueConvertible?,
                        row["CreatedDate"] as String? as DatabaseValueConvertible?,
                        row["LastUpdate"] as String? as DatabaseValueConvertible?,
                        row["LastUpdateTicks"] as Double? as DatabaseValueConvertible?,
                        row["IsFavorite"] as Int? as DatabaseValueConvertible?,
                        row["SortOrder"] as Int? as DatabaseValueConvertible?,
                        memberID as DatabaseValueConvertible?,
                        row["IsActive"] as Int? as DatabaseValueConvertible?,
                        row["HasText"] as Int? as DatabaseValueConvertible?,
                        row["HasVideo"] as Int? as DatabaseValueConvertible?,
                        0 as DatabaseValueConvertible?,
                        row["SnippetGUID"] as String? as DatabaseValueConvertible?,
                        row["FTPMultiplier"] as Double? as DatabaseValueConvertible?,
                        row["FTPLowThreshold"] as Double? as DatabaseValueConvertible?,
                        row["FTPHighThreshold"] as Double? as DatabaseValueConvertible?,
                        row["LTHRMultiplier"] as Double? as DatabaseValueConvertible?,
                        row["LTHRLowThreshold"] as Double? as DatabaseValueConvertible?,
                        row["LTHRHighThreshold"] as Double? as DatabaseValueConvertible?,
                        row["VideoLocation"] as String? as DatabaseValueConvertible?,
                        row["VideoInstructionLink"] as String? as DatabaseValueConvertible?,
                        row["VideoPreviewLink"] as String? as DatabaseValueConvertible?,
                        row["VideoPublisherID"] as Int? as DatabaseValueConvertible?,
                        row["IntervalRestThreshold"] as Int? as DatabaseValueConvertible?,
                    ] as [DatabaseValueConvertible?])!
                )
            }
            imported += 1
        }
        return imported
    }
}

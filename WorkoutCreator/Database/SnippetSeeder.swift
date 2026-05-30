import Foundation
import GRDB

struct SnippetSeeder {
    static func seedIfNeeded(dbQueue: DatabaseQueue, memberID: Int = 1) {
        do {
            let count = try dbQueue.read { db in
                try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM workoutFile WHERE WorkoutFileID = -1") ?? 0
            }
            guard count == 0 else { return }
            seedFromBundle(dbQueue: dbQueue, memberID: memberID)
        } catch {}
    }

    private static func seedFromBundle(dbQueue: DatabaseQueue, memberID: Int) {
        guard let snippetsURL = Bundle.main.url(forResource: "DefaultSnippets", withExtension: nil) else { return }
        let mrcFiles = (try? FileManager.default.contentsOfDirectory(
            at: snippetsURL,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "mrc" }.sorted { $0.lastPathComponent < $1.lastPathComponent }) ?? []

        for (index, url) in mrcFiles.enumerated() {
            guard let text = try? String(contentsOf: url, encoding: .utf8),
                  let parsed = try? MRCParser.parse(text)
            else { continue }

            let duration = (parsed.details.workoutPoints.last?.minutes ?? 0) * 60
            let now = ISO8601DateFormatter().string(from: Date())
            let snippet = WorkoutFile(
                id: -1,
                name: parsed.name,
                fileURL: nil,
                fileByteArray: nil,
                fileContents: text,
                description: nil,
                goals: nil,
                thumbnailURL: nil,
                thumbnailByteArray: nil,
                duration: duration,
                tss: parsed.tss,
                intensityFactor: parsed.intensityFactor,
                zones: nil,
                createdDate: now,
                lastUpdate: now,
                lastUpdateTicks: 0,
                isFavorite: false,
                sortOrder: index,
                memberID: memberID,
                isActive: true,
                hasText: !parsed.details.cuePoints.isEmpty,
                hasVideo: false,
                videoLocation: nil,
                videoInstructionLink: nil,
                videoPreviewLink: nil,
                videoPublisherID: nil,
                ftpMultiplier: parsed.intensityFactor,
                ftpLowThreshold: 0,
                ftpHighThreshold: 1,
                lthrMultiplier: 0,
                lthrLowThreshold: 0,
                lthrHighThreshold: 1,
                isDirty: false,
                snippetGUID: UUID().uuidString,
                intervalRestThreshold: nil
            )

            try? dbQueue.write { db in
                try db.execute(
                    sql: """
                        INSERT INTO workoutFile
                        (WorkoutFileID, Name, FileContents, Duration, TSS, IntensityFactor,
                         LastUpdateTicks, FTPMultiplier, FTPHighThreshold, FTPLowThreshold,
                         LTHRMultiplier, LTHRHighThreshold, LTHRLowThreshold,
                         IsFavorite, SortOrder, MemberID, IsActive, HasText, HasVideo, IsDirty,
                         CreatedDate, LastUpdate, SnippetGUID)
                        VALUES (-1, ?, ?, ?, ?, ?,
                                0, ?, 1, 0,
                                0, 1, 0,
                                0, ?, 1, 1, ?, 0, 0,
                                ?, ?, ?)
                        """,
                    arguments: [
                        snippet.name, snippet.fileContents,
                        snippet.duration, snippet.tss, snippet.intensityFactor,
                        snippet.ftpMultiplier,
                        snippet.sortOrder,
                        snippet.hasText ? 1 : 0,
                        snippet.createdDate, snippet.lastUpdate, snippet.snippetGUID
                    ]
                )
            }
        }
    }
}

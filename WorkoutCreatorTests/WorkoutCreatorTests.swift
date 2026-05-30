import XCTest
import GRDB
@testable import WorkoutCreator

// MARK: - Database Tests

final class WorkoutRepositoryTests: XCTestCase {
    var dbQueue: DatabaseQueue!
    var repo: WorkoutRepository!

    override func setUpWithError() throws {
        dbQueue = try DatabaseQueue()
        var migrator = DatabaseMigrator()
        migrator.registerMigration(V1_InitialSchema.identifier, migrate: V1_InitialSchema.migrate)
        migrator.registerMigration(V2_AddVideoFields.identifier, migrate: V2_AddVideoFields.migrate)
        migrator.registerMigration(V3_AddSnippetGUID.identifier, migrate: V3_AddSnippetGUID.migrate)
        migrator.registerMigration(V4_AddIntervalRestThreshold.identifier, migrate: V4_AddIntervalRestThreshold.migrate)
        try migrator.migrate(dbQueue)
        repo = WorkoutRepository(dbQueue: dbQueue)
    }

    func testInsertAndFetchByID() throws {
        try dbQueue.write { db in
            try db.execute(
                sql: """
                    INSERT INTO workoutFile
                    (WorkoutFileID, Name, Duration, TSS, IntensityFactor, LastUpdateTicks,
                     FTPMultiplier, FTPHighThreshold, FTPLowThreshold,
                     LTHRMultiplier, LTHRHighThreshold, LTHRLowThreshold,
                     IsFavorite, SortOrder, MemberID, IsActive, HasText, HasVideo, IsDirty)
                    VALUES (42, 'Test Workout', 3600, 50, 0.7, 0, 0.7, 1.05, 0.56,
                            0.7, 1.05, 0.56, 0, 0, 1, 1, 0, 0, 0)
                    """
            )
        }
        let fetched = try repo.fetch(id: 42)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.name, "Test Workout")
        XCTAssertEqual(fetched?.duration, 3600)
    }

    func testSnippetFetch() throws {
        try dbQueue.write { db in
            try db.execute(
                sql: """
                    INSERT INTO workoutFile
                    (WorkoutFileID, Name, Duration, TSS, IntensityFactor, LastUpdateTicks,
                     FTPMultiplier, FTPHighThreshold, FTPLowThreshold,
                     LTHRMultiplier, LTHRHighThreshold, LTHRLowThreshold,
                     IsFavorite, SortOrder, MemberID, IsActive, HasText, HasVideo, IsDirty)
                    VALUES (-1, 'Snippet', 300, 5, 0.5, 0, 0.5, 1.0, 0.5,
                            0.5, 1.0, 0.5, 0, 0, 1, 1, 0, 0, 0)
                    """
            )
        }
        let snippets = try repo.fetchSnippets(memberID: 1)
        XCTAssertEqual(snippets.count, 1)
        XCTAssertEqual(snippets[0].name, "Snippet")
        XCTAssertTrue(snippets[0].isSnippet)
    }
}

// MARK: - MRC Parser Tests

final class MRCParserTests: XCTestCase {
    private func snippetURL(_ name: String) -> URL {
        // In test bundle, snippets are in the main bundle's DefaultSnippets folder
        let bundle = Bundle(for: type(of: self))
        // Fall back to sibling path relative to source
        if let url = bundle.url(forResource: name, withExtension: "mrc") {
            return url
        }
        let sourceURL = URL(fileURLWithPath: #file)
        return sourceURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("workouts/snippets/\(name).mrc")
    }

    func testParseOverUnders() throws {
        let text = try String(contentsOf: snippetURL("over-unders"), encoding: .utf8)
        let result = try MRCParser.parse(text)
        XCTAssertEqual(result.name, "Over Unders")
        XCTAssertEqual(result.intensityFactor, 0.85, accuracy: 0.001)
        XCTAssertEqual(result.tss, 23, accuracy: 0.5)
        XCTAssertFalse(result.details.workoutPoints.isEmpty)
        XCTAssertFalse(result.details.intervals.isEmpty)
    }

    func testParseAllSevenSnippets() throws {
        let names = [
            "1-minute-interval",
            "10-minute-interval",
            "20-minute-interval",
            "5-minute-interval",
            "over-unders",
            "stepped-warm-up",
            "sweet-spot-warm-up"
        ]
        for name in names {
            let text = try String(contentsOf: snippetURL(name), encoding: .utf8)
            XCTAssertNoThrow(try MRCParser.parse(text), "Failed to parse \(name)")
        }
    }

    func testParse1MinuteInterval() throws {
        let text = try String(contentsOf: snippetURL("1-minute-interval"), encoding: .utf8)
        let result = try MRCParser.parse(text)
        XCTAssertEqual(result.name, "1 Minute Interval")
        XCTAssertEqual(result.intensityFactor, 1.0, accuracy: 0.001)
        XCTAssertEqual(result.tss, 2, accuracy: 0.5)
        XCTAssertEqual(result.details.workoutPoints.count, 2)
        XCTAssertEqual(result.details.intervals.count, 2)
    }

    func testRoundTrip() throws {
        let text = try String(contentsOf: snippetURL("over-unders"), encoding: .utf8)
        let first = try MRCParser.parse(text)
        let written = MRCWriter.write(
            name: first.name,
            intensityFactor: first.intensityFactor,
            tss: first.tss,
            memberID: first.memberID,
            details: first.details
        )
        let second = try MRCParser.parse(written)
        XCTAssertEqual(first.name, second.name)
        XCTAssertEqual(first.details.workoutPoints.count, second.details.workoutPoints.count)
        XCTAssertEqual(first.details.intervals.count, second.details.intervals.count)
    }
}

// MARK: - Power Metrics Tests

final class PowerMetricsTests: XCTestCase {
    private func snippetURL(_ name: String) -> URL {
        let sourceURL = URL(fileURLWithPath: #file)
        return sourceURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("workouts/snippets/\(name).mrc")
    }

    func testOverUndersMetrics() throws {
        let text = try String(contentsOf: snippetURL("over-unders"), encoding: .utf8)
        let result = try MRCParser.parse(text)
        let metrics = PowerMetrics.calculate(result.details.workoutPoints)
        XCTAssertEqual(metrics.tss, 23, accuracy: 2.0)
        XCTAssertEqual(metrics.intensityFactor, 0.85, accuracy: 0.05)
    }

    func testExpandToSeconds() {
        let points = [
            WorkoutPoint(minutes: 0, ftpPercent: 50),
            WorkoutPoint(minutes: 1, ftpPercent: 100),
        ]
        let seconds = PowerMetrics.expandToSeconds(points)
        XCTAssertEqual(seconds.count, 60)
        XCTAssertEqual(seconds.first ?? 0, 50, accuracy: 1)
    }

    func testNormalizedPower() {
        // Constant 100% FTP → NP should equal 100
        let rolling = [Double](repeating: 100, count: 60)
        let np = PowerMetrics.normalizedPower(rolling)
        XCTAssertEqual(np, 100, accuracy: 0.01)
    }
}

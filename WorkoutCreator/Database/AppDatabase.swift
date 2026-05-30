import Foundation
import GRDB

final class AppDatabase {
    static let shared: AppDatabase = {
        do {
            return try AppDatabase()
        } catch {
            fatalError("Failed to open database: \(error)")
        }
    }()

    let dbQueue: DatabaseQueue

    private init() throws {
        let appSupport = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dbDir = appSupport.appendingPathComponent("WorkoutCreator", isDirectory: true)
        try FileManager.default.createDirectory(at: dbDir, withIntermediateDirectories: true)
        let dbURL = dbDir.appendingPathComponent("workouts.sqlite")

        dbQueue = try DatabaseQueue(path: dbURL.path)
        try migrate()
        SnippetSeeder.seedIfNeeded(dbQueue: dbQueue)
    }

    private func migrate() throws {
        var migrator = DatabaseMigrator()
        migrator.registerMigration(V1_InitialSchema.identifier, migrate: V1_InitialSchema.migrate)
        migrator.registerMigration(V2_AddVideoFields.identifier, migrate: V2_AddVideoFields.migrate)
        migrator.registerMigration(V3_AddSnippetGUID.identifier, migrate: V3_AddSnippetGUID.migrate)
        migrator.registerMigration(V4_AddIntervalRestThreshold.identifier, migrate: V4_AddIntervalRestThreshold.migrate)
        try migrator.migrate(dbQueue)
    }
}

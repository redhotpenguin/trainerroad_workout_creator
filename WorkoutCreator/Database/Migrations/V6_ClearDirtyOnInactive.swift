import GRDB

struct V6_ClearDirtyOnInactive: DatabaseMigration {
    static let identifier = "v6_clear_dirty_on_inactive"

    // Older builds left IsDirty=1 on soft-deleted workouts, so sync kept
    // republishing ghosts to TrainerRoad. Clear them in one shot.
    static func migrate(_ db: Database) throws {
        try db.execute(sql: "UPDATE workoutFile SET IsDirty = 0 WHERE IsActive = 0")
    }
}

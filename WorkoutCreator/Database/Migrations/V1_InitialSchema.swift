import GRDB

struct V1_InitialSchema: DatabaseMigration {
    static let identifier = "v1_initial"

    static func migrate(_ db: Database) throws {
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS workoutFile (
                WorkoutFileID INTEGER,
                Name TEXT,
                FileURL TEXT,
                FileByteArray BLOB,
                FileContents TEXT,
                Description TEXT,
                ThumbnailURL TEXT,
                ThumbnailByteArray BLOB,
                Duration REAL,
                TSS REAL,
                IntensityFactor REAL,
                Zones BLOB,
                CreatedDate TEXT,
                LastUpdate TEXT,
                IsFavorite INTEGER,
                SortOrder INTEGER,
                MemberID INTEGER,
                IsActive INTEGER,
                HasText INTEGER,
                Goals TEXT,
                LastUpdateTicks REAL DEFAULT 0,
                FTPMultiplier REAL DEFAULT 0,
                FTPHighThreshold REAL DEFAULT 0,
                FTPLowThreshold REAL DEFAULT 0,
                LTHRMultiplier REAL DEFAULT 0,
                LTHRHighThreshold REAL DEFAULT 0,
                LTHRLowThreshold REAL DEFAULT 0,
                VideoLocation TEXT,
                HasVideo INTEGER DEFAULT 0,
                VideoInstructionLink TEXT,
                VideoPreviewLink TEXT,
                VideoPublisherID INTEGER DEFAULT 0,
                WorkoutFileGUID TEXT,
                IsDirty INTEGER,
                SnippetGUID TEXT
            )
            """)

        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS INX_WorkoutFileID
            ON workoutFile (WorkoutFileID)
            """)

        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS workoutSummary (
                WorkoutSummaryID INTEGER PRIMARY KEY AUTOINCREMENT,
                MemberID INTEGER,
                WorkoutFileID INTEGER,
                WorkoutNotes TEXT,
                WorkoutDate DATE,
                LastUpdate DATE,
                IsFavorite INTEGER DEFAULT 0,
                WorkoutProcessed INTEGER DEFAULT 0,
                FTP INTEGER,
                LTHR INTEGER,
                WorkoutType INTEGER,
                ThumbnailByteArray BLOB,
                PictureByteArray BLOB,
                WorkoutGUID TEXT,
                PictureURL TEXT,
                ThumbnailURL TEXT,
                WorkoutURL TEXT,
                PowerSourceString TEXT,
                WorkoutSynced INTEGER DEFAULT 0,
                LastUpdateTicks REAL DEFAULT 0,
                ANTUSBPID TEXT,
                ANTUSBVID TEXT,
                ANTNumChannels INTEGER DEFAULT 0,
                AppVersion TEXT,
                OS TEXT,
                p5Sec INTEGER DEFAULT 0,
                p10Sec INTEGER DEFAULT 0,
                p20Sec INTEGER DEFAULT 0,
                p30Sec INTEGER DEFAULT 0,
                p1Min INTEGER DEFAULT 0,
                p2Min INTEGER DEFAULT 0,
                p5Min INTEGER DEFAULT 0,
                p10Min INTEGER DEFAULT 0,
                p15Min INTEGER DEFAULT 0,
                p20Min INTEGER DEFAULT 0,
                p30Min INTEGER DEFAULT 0,
                p60Min INTEGER DEFAULT 0,
                p180Min INTEGER DEFAULT 0,
                ANTConsoleXVersion TEXT,
                RolldownTime REAL,
                WahooConsoleXVersion TEXT
            )
            """)

        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS INX_WorkoutSummaryID
            ON workoutSummary (WorkoutSummaryID)
            """)

        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS INX_WorkoutSummary_WorkoutFileID
            ON workoutSummary (WorkoutFileID)
            """)

        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS workoutData (
                WorkoutDataID INTEGER PRIMARY KEY AUTOINCREMENT,
                WorkoutSummaryID INTEGER,
                Minutes REAL,
                Torq REAL,
                Kmh REAL,
                Watts INTEGER,
                Km REAL,
                Cadence INTEGER,
                HRate INTEGER,
                RollingWatts REAL,
                RollingWattsFourth REAL,
                Distance REAL,
                Ticks INTEGER,
                TargetData REAL,
                PowerMeterWatts INTEGER,
                RolldownTime REAL
            )
            """)

        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS INX_WorkoutDataID
            ON workoutData (WorkoutDataID)
            """)

        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS INX_WorkoutData_WorkoutSummaryID
            ON workoutData (WorkoutSummaryID)
            """)

        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS INX_WorkoutData_WorkoutSummaryID_Ticks
            ON workoutData (WorkoutSummaryID, Ticks)
            """)

        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS interval (
                IntervalID INTEGER PRIMARY KEY AUTOINCREMENT,
                WorkoutSummaryID INTEGER,
                IntervalTypeID INTEGER,
                SortOrder INTEGER,
                SuggestionTrigger INTEGER DEFAULT 0,
                MemberID INTEGER,
                Name TEXT,
                StartTick INTEGER,
                EndTick INTEGER,
                Duration INTEGER,
                Description TEXT,
                Kj INTEGER,
                TSS REAL,
                IntensityFactor REAL,
                NormalizedPower INTEGER,
                Distance REAL,
                WattsMin INTEGER,
                WattsAvg INTEGER,
                WattsMax INTEGER,
                TargetMin INTEGER,
                TargetAvg INTEGER,
                TargetMax INTEGER,
                HRMin INTEGER,
                HRAvg INTEGER,
                HRMax INTEGER,
                CadenceMin INTEGER,
                CadenceAvg INTEGER,
                CadenceMax INTEGER,
                SpeedMin REAL,
                SpeedAvg REAL,
                SpeedMax REAL,
                TorqueMin REAL,
                TorqueAvg REAL,
                TorqueMax REAL,
                ElevationMin REAL,
                ElevationAvg REAL,
                ElevationMax REAL
            )
            """)

        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS trainer (
                TrainerID INTEGER PRIMARY KEY,
                Description TEXT,
                Value0 REAL,
                Value1 REAL,
                Value2 REAL,
                Value3 REAL,
                Type TEXT,
                LastUpdate DATE,
                SortOrder INTEGER,
                PurchaseLink TEXT,
                Notes TEXT,
                Manufacturer TEXT,
                RolldownTime REAL DEFAULT 0,
                RolldownStartSpeed REAL DEFAULT 0,
                RolldownStopSpeed REAL DEFAULT 0,
                HasHighFormula INTEGER DEFAULT 0,
                HighValue0 REAL DEFAULT 0,
                HighValue1 REAL DEFAULT 0,
                HighValue2 REAL DEFAULT 0,
                HighValue3 REAL DEFAULT 0,
                HighRolldownTime REAL DEFAULT 0,
                HasLowFormula INTEGER DEFAULT 0,
                LowValue0 REAL DEFAULT 0,
                LowValue1 REAL DEFAULT 0,
                LowValue2 REAL DEFAULT 0,
                LowValue3 REAL DEFAULT 0,
                LowRolldownTime REAL DEFAULT 0,
                IsParent INTEGER DEFAULT 0,
                ParentID INTEGER DEFAULT 0,
                ResistanceSetting TEXT
            )
            """)

        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS device (
                tblDeviceID INTEGER PRIMARY KEY AUTOINCREMENT,
                DeviceType INTEGER,
                DeviceID INTEGER,
                ManufacturerID INTEGER,
                Serial REAL,
                Battery TEXT,
                ModelNumber INTEGER,
                HardwareVersion INTEGER,
                SoftwareVersion INTEGER,
                PageType INTEGER,
                WorkoutSummaryID INTEGER,
                DeviceUUID TEXT
            )
            """)
    }
}

protocol DatabaseMigration {
    static var identifier: String { get }
    static func migrate(_ db: Database) throws
}

import Foundation
import GRDB

struct WorkoutFile: Identifiable, Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "workoutFile"

    var id: Int?
    var name: String
    var fileURL: String?
    var fileByteArray: Data? = nil    // not decoded from API (binary blob)
    var fileContents: String?
    var description: String?
    var goals: String?
    var thumbnailURL: String?
    var thumbnailByteArray: Data? = nil  // not decoded from API (binary blob)
    var duration: Double
    var tss: Double
    var intensityFactor: Double
    var zones: Data? = nil               // API returns as JSON array; unused in UI
    var createdDate: String?
    var lastUpdate: String?
    var lastUpdateTicks: Double
    var isFavorite: Bool
    var sortOrder: Int
    var memberID: Int
    var isActive: Bool
    var hasText: Bool
    var hasVideo: Bool
    var videoLocation: String?
    var videoInstructionLink: String?
    var videoPreviewLink: String?
    var videoPublisherID: Int?
    var ftpMultiplier: Double
    var ftpLowThreshold: Double
    var ftpHighThreshold: Double
    var lthrMultiplier: Double
    var lthrLowThreshold: Double
    var lthrHighThreshold: Double
    var isDirty: Bool
    var snippetGUID: String?
    var intervalRestThreshold: Int?

    enum CodingKeys: String, CodingKey {
        case id = "WorkoutFileId"
        case name = "Name"
        case fileURL = "FileURL"
        // fileByteArray excluded — binary blob, not in API JSON
        case fileContents = "FileContents"
        case description = "Description"
        case goals = "Goals"
        case thumbnailURL = "ThumbnailURL"
        // thumbnailByteArray excluded — binary blob, not in API JSON
        case duration = "Duration"
        case tss = "TSS"
        case intensityFactor = "IntensityFactor"
        // zones excluded — API returns JSON array, stored as blob; unused in UI
        case createdDate = "CreatedDate"
        case lastUpdate = "LastUpdate"
        case lastUpdateTicks = "LastUpdateTicks"
        case isFavorite = "IsFavorite"
        case sortOrder = "SortOrder"
        case memberID = "MemberId"
        case isActive = "IsActive"
        case hasText = "HasText"
        case hasVideo = "HasVideo"
        case videoLocation = "VideoLocation"
        case videoInstructionLink = "VideoInstructionLink"
        case videoPreviewLink = "VideoPreviewLink"
        case videoPublisherID = "VideoPublisherId"
        case ftpMultiplier = "FTPMultiplier"
        case ftpLowThreshold = "FTPLowThreshold"
        case ftpHighThreshold = "FTPHighThreshold"
        case lthrMultiplier = "LTHRMultiplier"
        case lthrLowThreshold = "LTHRLowThreshold"
        case lthrHighThreshold = "LTHRHighThreshold"
        case isDirty = "IsDirty"
        case snippetGUID = "SnippetGUID"
        case intervalRestThreshold = "IntervalRestThreshold"
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = Int(inserted.rowID)
    }

    var isSnippet: Bool { id == -1 }

    static func blank(memberID: Int) -> WorkoutFile {
        let now = ISO8601DateFormatter().string(from: Date())
        return WorkoutFile(
            id: nil,
            name: "New Workout",
            fileURL: nil,
            fileByteArray: nil,
            fileContents: nil,
            description: nil,
            goals: nil,
            thumbnailURL: nil,
            thumbnailByteArray: nil,
            duration: 3600,
            tss: 0,
            intensityFactor: 0,
            zones: nil,
            createdDate: now,
            lastUpdate: now,
            lastUpdateTicks: 0,
            isFavorite: false,
            sortOrder: 0,
            memberID: memberID,
            isActive: true,
            hasText: false,
            hasVideo: false,
            videoLocation: nil,
            videoInstructionLink: nil,
            videoPreviewLink: nil,
            videoPublisherID: nil,
            ftpMultiplier: 0.5,
            ftpLowThreshold: 0,
            ftpHighThreshold: 1,
            lthrMultiplier: 0.5,
            lthrLowThreshold: 0,
            lthrHighThreshold: 1,
            isDirty: true,
            snippetGUID: nil,
            intervalRestThreshold: nil
        )
    }
}

// Custom Decodable in extension preserves the synthesized memberwise init.
// Every field uses try? so missing or mismatched API JSON keys get a safe default.
// Works identically for GRDB's SQLite row decoder (which provides all present columns).
extension WorkoutFile {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                    = try? c.decode(Int.self,    forKey: .id)
        name                  = (try? c.decode(String.self, forKey: .name)) ?? ""
        fileURL               = try? c.decode(String.self, forKey: .fileURL)
        fileContents          = try? c.decode(String.self, forKey: .fileContents)
        description           = try? c.decode(String.self, forKey: .description)
        goals                 = try? c.decode(String.self, forKey: .goals)
        thumbnailURL          = try? c.decode(String.self, forKey: .thumbnailURL)
        duration              = (try? c.decode(Double.self, forKey: .duration)) ?? 0
        tss                   = (try? c.decode(Double.self, forKey: .tss)) ?? 0
        intensityFactor       = (try? c.decode(Double.self, forKey: .intensityFactor)) ?? 0
        createdDate           = try? c.decode(String.self, forKey: .createdDate)
        lastUpdate            = try? c.decode(String.self, forKey: .lastUpdate)
        lastUpdateTicks       = (try? c.decode(Double.self, forKey: .lastUpdateTicks)) ?? 0
        isFavorite            = (try? c.decode(Bool.self,   forKey: .isFavorite)) ?? false
        sortOrder             = (try? c.decode(Int.self,    forKey: .sortOrder)) ?? 0
        memberID              = (try? c.decode(Int.self,    forKey: .memberID)) ?? 1
        isActive              = (try? c.decode(Bool.self,   forKey: .isActive)) ?? true
        hasText               = (try? c.decode(Bool.self,   forKey: .hasText)) ?? false
        hasVideo              = (try? c.decode(Bool.self,   forKey: .hasVideo)) ?? false
        videoLocation         = try? c.decode(String.self, forKey: .videoLocation)
        videoInstructionLink  = try? c.decode(String.self, forKey: .videoInstructionLink)
        videoPreviewLink      = try? c.decode(String.self, forKey: .videoPreviewLink)
        videoPublisherID      = try? c.decode(Int.self,    forKey: .videoPublisherID)
        ftpMultiplier         = (try? c.decode(Double.self, forKey: .ftpMultiplier)) ?? 0
        ftpLowThreshold       = (try? c.decode(Double.self, forKey: .ftpLowThreshold)) ?? 0
        ftpHighThreshold      = (try? c.decode(Double.self, forKey: .ftpHighThreshold)) ?? 1
        lthrMultiplier        = (try? c.decode(Double.self, forKey: .lthrMultiplier)) ?? 0
        lthrLowThreshold      = (try? c.decode(Double.self, forKey: .lthrLowThreshold)) ?? 0
        lthrHighThreshold     = (try? c.decode(Double.self, forKey: .lthrHighThreshold)) ?? 1
        isDirty               = (try? c.decode(Bool.self,   forKey: .isDirty)) ?? false
        snippetGUID           = try? c.decode(String.self, forKey: .snippetGUID)
        intervalRestThreshold = try? c.decode(Int.self,    forKey: .intervalRestThreshold)
    }
}

extension WorkoutFile: Hashable {
    // Compare display-relevant fields so SwiftUI re-renders rows when name/badges change.
    // Hash stays on id to keep Set/Dictionary identity stable.
    static func == (lhs: WorkoutFile, rhs: WorkoutFile) -> Bool {
        lhs.id == rhs.id
            && lhs.name == rhs.name
            && lhs.isFavorite == rhs.isFavorite
            && lhs.isDirty == rhs.isDirty
            && lhs.tss == rhs.tss
            && lhs.duration == rhs.duration
    }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

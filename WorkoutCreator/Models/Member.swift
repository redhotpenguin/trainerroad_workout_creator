import Foundation

struct Member: Codable, Equatable {
    var memberID: Int
    var username: String
    var email: String?
    var firstName: String?
    var lastName: String?
    var userActive: Bool?
    var validUntil: String?
    var loginText: String?
    var ftp: Int?
    var lthr: Int?
    var hideWorkoutText: Bool?
    var ftpUpdated: String?
    var lthrUpdated: String?
    var postWorkoutsToFacebook: Bool?
    var dob: String?
    var circumference: Int?
    var units: Int?
    var isMale: Bool?
    var lastUpdate: String?
    var lastLoginApp: String?
    var lastLoginWebsite: String?
    var weightUpdated: String?

    enum CodingKeys: String, CodingKey {
        case memberID = "MemberId"
        case username = "Username"
        case email = "Email"
        case firstName = "FirstName"
        case lastName = "LastName"
        case userActive = "UserActive"
        case validUntil = "ValidUntil"
        case loginText = "LoginText"
        case ftp = "FTP"
        case lthr = "LTHR"
        case hideWorkoutText = "HideWorkoutText"
        case ftpUpdated = "FTPUpdated"
        case lthrUpdated = "LTHRUpdated"
        case postWorkoutsToFacebook = "PostWorkoutsToFacebook"
        case dob = "DOB"
        case circumference = "Circumference"
        case units = "Units"
        case isMale = "IsMale"
        case lastUpdate = "LastUpdate"
        case lastLoginApp = "LastLoginApp"
        case lastLoginWebsite = "LastLoginWebsite"
        case weightUpdated = "WeightUpdated"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // API returns MemberId as a JSON string, not an integer
        if let idInt = try? c.decode(Int.self, forKey: .memberID) {
            memberID = idInt
        } else {
            let idStr = try c.decode(String.self, forKey: .memberID)
            guard let parsed = Int(idStr) else {
                throw DecodingError.dataCorruptedError(forKey: .memberID, in: c,
                    debugDescription: "MemberId '\(idStr)' is not a valid integer")
            }
            memberID = parsed
        }
        username = (try? c.decode(String.self, forKey: .username)) ?? ""
        email = try? c.decode(String.self, forKey: .email)
        firstName = try? c.decode(String.self, forKey: .firstName)
        lastName = try? c.decode(String.self, forKey: .lastName)
        userActive = try? c.decode(Bool.self, forKey: .userActive)
        validUntil = try? c.decode(String.self, forKey: .validUntil)
        loginText = try? c.decode(String.self, forKey: .loginText)
        ftp = try? c.decode(Int.self, forKey: .ftp)
        lthr = try? c.decode(Int.self, forKey: .lthr)
        hideWorkoutText = try? c.decode(Bool.self, forKey: .hideWorkoutText)
        ftpUpdated = try? c.decode(String.self, forKey: .ftpUpdated)
        lthrUpdated = try? c.decode(String.self, forKey: .lthrUpdated)
        postWorkoutsToFacebook = try? c.decode(Bool.self, forKey: .postWorkoutsToFacebook)
        dob = try? c.decode(String.self, forKey: .dob)
        circumference = try? c.decode(Int.self, forKey: .circumference)
        units = try? c.decode(Int.self, forKey: .units)
        isMale = try? c.decode(Bool.self, forKey: .isMale)
        lastUpdate = try? c.decode(String.self, forKey: .lastUpdate)
        lastLoginApp = try? c.decode(String.self, forKey: .lastLoginApp)
        lastLoginWebsite = try? c.decode(String.self, forKey: .lastLoginWebsite)
        weightUpdated = try? c.decode(String.self, forKey: .weightUpdated)
    }
}

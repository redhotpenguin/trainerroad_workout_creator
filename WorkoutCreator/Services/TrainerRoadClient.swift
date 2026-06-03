import Foundation
import Compression


actor TrainerRoadClient {
    private static let baseURL = "https://api.trainerroad.com/api"
    private let session: URLSession
    private let authHeader: String

    struct WorkoutIDRecord: Decodable {
        var id: Int
        var updated: String

        enum CodingKeys: String, CodingKey {
            case id = "Id"
            case updated = "Updated"
        }
    }

    struct PublishResult: Decodable {
        var workoutFileID: Int
        var previousWorkoutFileID: Int?
        var isSuccessful: Bool
        var lastUpdate: String?

        enum CodingKeys: String, CodingKey {
            // Note: the publish response uses uppercase "ID" (unlike the WorkoutFile
            // GET endpoints which use lowercase "Id").
            case workoutFileID = "WorkoutFileID"
            case previousWorkoutFileID = "PreviousWorkoutFileID"
            case isSuccessful = "IsSuccessful"
            case lastUpdate = "LastUpdate"
        }
    }

    init(username: String, password: String) {
        let credentials = Data("\(username):\(password)".utf8).base64EncodedString()
        authHeader = "Basic \(credentials)"
        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config)
    }

    func authenticate() async throws -> Member {
        var request = makeRequest(path: "/members", method: "POST")
        request.httpBody = Data()
        let (data, response) = try await session.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        if let raw = String(data: data, encoding: .utf8) {
            print("[TrainerRoad] POST /members status=\(statusCode) body=\(raw.prefix(500))")
        }
        do {
            return try JSONDecoder().decode(Member.self, from: data)
        } catch {
            print("[TrainerRoad] Member decode error: \(error)")
            throw error
        }
    }

    func fetchWorkoutIDs() async throws -> [WorkoutIDRecord] {
        let request = makeRequest(path: "/workoutfiles/getids", method: "GET")
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode([WorkoutIDRecord].self, from: data)
    }

    func fetchWorkouts(ids: [Int]) async throws -> [WorkoutFile] {
        let idString = ids.map { String($0) }.joined(separator: ",")
        let request = makeRequest(path: "/workoutfiles/getbatch?workoutIds=\(idString)", method: "GET")
        let (data, _) = try await session.data(for: request)
        let decoder = JSONDecoder()
        return try decoder.decode([WorkoutFile].self, from: data)
    }

    func publishWorkout(_ workout: WorkoutFile, isNew: Bool) async throws -> PublishResult {
        var payload = workout
        payload.intensityFactor = workout.intensityFactor / 100.0
        // For new workouts the local `id` is a SQLite rowid that means nothing
        // to the server — send null so the server creates a fresh record.
        // Otherwise keep the server-assigned id so this becomes an update.
        if isNew {
            payload.id = nil
        }

        let json = try JSONEncoder().encode(payload)

        var request = makeRequest(path: "/workoutfiles", method: "PUT")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = json

        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if let raw = String(data: data, encoding: .utf8) {
            print("[TrainerRoad] PUT /workoutfiles status=\(status) body=\(raw.prefix(500))")
        }
        return try JSONDecoder().decode(PublishResult.self, from: data)
    }

    /// TR has no true DELETE endpoint; "deleting" is done by PUTting the workout
    /// back with IsActive=false (the same pattern the publish path uses).
    func deleteWorkout(_ workout: WorkoutFile) async throws {
        var payload = workout
        payload.isActive = false
        payload.intensityFactor = workout.intensityFactor / 100.0

        let json = try JSONEncoder().encode(payload)

        var request = makeRequest(path: "/workoutfiles", method: "PUT")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = json

        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if let raw = String(data: data, encoding: .utf8) {
            print("[TrainerRoad] PUT (delete) /workoutfiles id=\(workout.id ?? -1) status=\(status) body=\(raw.prefix(300))")
        }
        if !(200..<300).contains(status) {
            throw URLError(.badServerResponse)
        }
    }

    private func makeRequest(path: String, method: String) -> URLRequest {
        let url = URL(string: Self.baseURL + path)!
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func gzipCompress(_ data: Data) -> Data? {
        let pageSize = data.count + 64
        return data.withUnsafeBytes { (inputPtr: UnsafeRawBufferPointer) -> Data? in
            var output = [UInt8](repeating: 0, count: pageSize)
            let compressedSize = compression_encode_buffer(
                &output, pageSize,
                inputPtr.bindMemory(to: UInt8.self).baseAddress!, data.count,
                nil,
                COMPRESSION_ZLIB
            )
            guard compressedSize > 0 else { return nil }
            return Data(output.prefix(compressedSize))
        }
    }
}

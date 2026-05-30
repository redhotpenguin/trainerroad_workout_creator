import Foundation
import Observation

@MainActor
@Observable
final class AuthStore {
    var currentMember: Member?
    var isLoggingIn = false
    var loginError: String?

    private var client: TrainerRoadClient?

    func login(username: String, password: String) async {
        isLoggingIn = true
        loginError = nil
        do {
            let client = TrainerRoadClient(username: username, password: password)
            let member = try await client.authenticate()
            KeychainHelper.save(username: username, password: password)
            self.client = client
            self.currentMember = member
        } catch {
            loginError = error.localizedDescription
        }
        isLoggingIn = false
    }

    private func authenticate(username: String, password: String) async {
        isLoggingIn = true
        do {
            let client = TrainerRoadClient(username: username, password: password)
            let member = try await client.authenticate()
            self.client = client
            self.currentMember = member
        } catch {
            // Silently fail — stale credentials; user will need to log in again
        }
        isLoggingIn = false
    }

    func logout() {
        KeychainHelper.delete()
        currentMember = nil
        client = nil
    }

    func restoreSession() async {
        guard let (username, password) = KeychainHelper.load() else { return }
        await authenticate(username: username, password: password)
    }

    func makeClient() -> TrainerRoadClient? {
        client
    }
}

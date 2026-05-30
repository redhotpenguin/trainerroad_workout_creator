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

    func logout() {
        KeychainHelper.delete()
        currentMember = nil
        client = nil
    }

    func restoreSession() async {
        guard let (username, password) = KeychainHelper.load() else { return }
        await login(username: username, password: password)
    }

    func makeClient() -> TrainerRoadClient? {
        client
    }
}

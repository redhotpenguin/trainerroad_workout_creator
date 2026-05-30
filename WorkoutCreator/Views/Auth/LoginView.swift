import SwiftUI

struct LoginView: View {
    @Environment(AuthStore.self) private var authStore
    @State private var username = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("WorkoutCreator")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Sign in with your TrainerRoad account")
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                TextField("Email", text: $username)
                    .textFieldStyle(.roundedBorder)
                    .disabled(authStore.isLoggingIn)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .disabled(authStore.isLoggingIn)
                    .onSubmit { login() }
            }
            .frame(width: 280)

            if let error = authStore.loginError {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
            }

            Button(action: login) {
                if authStore.isLoggingIn {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 80)
                } else {
                    Text("Sign In")
                        .frame(width: 80)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(username.isEmpty || password.isEmpty || authStore.isLoggingIn)
            .keyboardShortcut(.return, modifiers: [])
        }
        .padding(40)
        .frame(width: 400, height: 320)
    }

    private func login() {
        Task { await authStore.login(username: username, password: password) }
    }
}

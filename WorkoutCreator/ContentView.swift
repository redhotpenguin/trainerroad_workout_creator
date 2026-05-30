import SwiftUI

struct ContentView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(WorkoutStore.self) private var workoutStore
    @Environment(WorkoutSyncService.self) private var syncService

    @State private var showImport = false

    var body: some View {
        Group {
            if authStore.currentMember != nil {
                NavigationSplitView {
                    WorkoutListView()
                } detail: {
                    WorkoutEditorView()
                }
                .frame(minWidth: 900, minHeight: 600)
            } else {
                LoginView()
                    .frame(minWidth: 400, minHeight: 320)
            }
        }
        .sheet(isPresented: $showImport) {
            ImportView(isPresented: $showImport)
                .environment(workoutStore)
        }
        .task {
            await authStore.restoreSession()
            if let member = authStore.currentMember {
                await syncAndLoad(memberID: member.memberID)
            }
        }
        .onChange(of: authStore.currentMember) { _, member in
            guard let member else { return }
            Task { await syncAndLoad(memberID: member.memberID) }
        }
    }

    private func syncAndLoad(memberID: Int) async {
        // Load whatever is already in the DB immediately so the list isn't blank
        workoutStore.load(memberID: memberID)

        guard let client = authStore.makeClient() else { return }
        await syncService.sync(client: client, userMemberID: memberID)

        // Reload after sync so newly downloaded workouts appear
        workoutStore.load(memberID: memberID)

        if LegacyImporter.hasLegacyDatabase && workoutStore.workoutList.isEmpty {
            showImport = true
        }
    }
}

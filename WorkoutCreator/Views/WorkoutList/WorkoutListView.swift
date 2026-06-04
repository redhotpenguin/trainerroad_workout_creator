import SwiftUI

struct WorkoutListView: View {
    @Environment(WorkoutStore.self) private var store
    @Environment(WorkoutSyncService.self) private var syncService
    @Environment(AuthStore.self) private var authStore
    @State private var searchText = ""
    @State private var showFavoritesOnly = false

    private var filteredWorkouts: [WorkoutFile] {
        var list = store.workoutList
        if showFavoritesOnly { list = list.filter { $0.isFavorite } }
        if !searchText.isEmpty {
            list = list.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return list
    }

    var body: some View {
        @Bindable var store = store
        List(filteredWorkouts, selection: $store.selectedWorkoutID) { workout in
            WorkoutRow(workout: workout)
                .tag(workout.id)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        store.delete(workout)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .contextMenu {
                    Button(role: .destructive) {
                        store.delete(workout)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
        }
        .searchable(text: $searchText, prompt: "Search workouts")
        .toolbar {
            ToolbarItem {
                Button {
                    if let member = authStore.currentMember {
                        store.newWorkout(memberID: member.memberID)
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .help("New Workout")
            }
            ToolbarItem {
                Toggle(isOn: $showFavoritesOnly) {
                    Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                }
                .help("Favorites only")
            }
            ToolbarItem {
                Button {
                    guard let member = authStore.currentMember,
                          let client = authStore.makeClient() else { return }
                    Task {
                        await syncService.sync(client: client, userMemberID: member.memberID)
                        store.load(memberID: member.memberID)
                    }
                } label: {
                    Image(systemName: syncService.isSyncing ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                }
                .disabled(syncService.isSyncing)
                .help("Sync now")
            }
        }
        .safeAreaInset(edge: .bottom) {
            syncStatusBar
        }
        .onChange(of: store.selectedWorkoutID) { _, id in
            guard let id,
                  let workout = store.workoutList.first(where: { $0.id == id })
            else { return }
            store.select(workout)
        }
    }

    private var syncStatusBar: some View {
        HStack {
            if syncService.isSyncing {
                ProgressView(value: syncService.progress)
                    .progressViewStyle(.linear)
                    .frame(maxWidth: .infinity)
                Text("Syncing…")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else if let date = syncService.lastSyncDate {
                Text("Last sync: \(date.formatted(.relative(presentation: .named)))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
    }
}

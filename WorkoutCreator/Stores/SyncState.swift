import Foundation
import Observation

@Observable
final class SyncState {
    var isSyncing = false
    var lastSyncDate: Date?
    var progress: Double = 0
}

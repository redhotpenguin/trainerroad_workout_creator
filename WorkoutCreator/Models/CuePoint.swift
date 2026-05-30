import Foundation

struct CuePoint: Identifiable {
    var id: UUID = UUID()
    var startSeconds: Int
    var durationSeconds: Int
    var text: String
}

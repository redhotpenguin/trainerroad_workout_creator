import Foundation

struct WorkoutInterval: Identifiable {
    var id: UUID = UUID()
    var startSeconds: Int
    var endSeconds: Int
    var name: String
}

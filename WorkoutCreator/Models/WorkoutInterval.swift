import Foundation

struct WorkoutInterval: Identifiable {
    var id: UUID = UUID()
    var startSeconds: Int
    var endSeconds: Int
    var name: String
    var power: Double = 50   // % FTP target for this interval
}

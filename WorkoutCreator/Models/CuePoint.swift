import Foundation

struct CuePoint: Identifiable {
    var id: UUID = UUID()
    var startSeconds: Int
    var durationSeconds: Int
    var text: String
    // TR's MRC cue rows have trailing font/color fields (e.g. "8\t0\t0\t72\t16777215\t0").
    // We don't model them individually; preserve verbatim for round-trip fidelity
    // and default-fill for new cues so TR keeps rendering them.
    var formatSuffix: String = "8\t0\t0\t72\t16777215\t0"
}

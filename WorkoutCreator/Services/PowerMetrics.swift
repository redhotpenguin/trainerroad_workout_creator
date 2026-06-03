import Foundation

enum PowerMetrics {
    struct Result {
        var normalizedPower: Double
        var intensityFactor: Double
        var tss: Double
    }

    static func expandToSeconds(_ points: [WorkoutPoint]) -> [Double] {
        guard points.count >= 2 else { return [] }
        // Sort defensively: input may contain adjacent step pairs in either order,
        // or — in case of inverted/overlapping intervals — points that go backwards
        // and would crash the per-second expansion below.
        let sorted = points.sorted { $0.minutes < $1.minutes }
        var seconds: [Double] = []
        let totalSeconds = Int(sorted.last!.minutes * 60)

        for i in 0..<(sorted.count - 1) {
            let p1 = sorted[i]
            let p2 = sorted[i + 1]
            let startSec = Int(p1.minutes * 60)
            let endSec = Int(p2.minutes * 60)
            let isStep = p1.minutes == p2.minutes

            if isStep {
                // Step change: the segment has zero duration; p2 value takes effect
                continue
            }

            for s in startSec..<endSec {
                if p1.minutes == p2.minutes {
                    seconds.append(p2.ftpPercent)
                } else {
                    let frac = Double(s - startSec) / Double(endSec - startSec)
                    let val = p1.ftpPercent + frac * (p2.ftpPercent - p1.ftpPercent)
                    seconds.append(val)
                }
            }
        }

        // Pad or trim to exact totalSeconds
        while seconds.count < totalSeconds {
            seconds.append(sorted.last?.ftpPercent ?? 0)
        }
        return Array(seconds.prefix(totalSeconds))
    }

    static func rollingAverage(_ values: [Double], window: Int = 30) -> [Double] {
        guard !values.isEmpty else { return [] }
        var result: [Double] = []
        var windowSum = 0.0
        for (i, v) in values.enumerated() {
            windowSum += v
            if i >= window {
                windowSum -= values[i - window]
                result.append(windowSum / Double(window))
            } else {
                result.append(windowSum / Double(i + 1))
            }
        }
        return result
    }

    static func normalizedPower(_ rolling: [Double]) -> Double {
        guard !rolling.isEmpty else { return 0 }
        let meanFourthPower = rolling.reduce(0.0) { $0 + pow($1, 4) } / Double(rolling.count)
        return pow(meanFourthPower, 0.25)
    }

    static func intensityFactor(np: Double) -> Double {
        np / 100.0
    }

    static func tss(intensityFactor: Double, durationSeconds: Int) -> Double {
        100.0 * intensityFactor * intensityFactor * (Double(durationSeconds) / 3600.0)
    }

    static func calculate(_ points: [WorkoutPoint]) -> Result {
        guard points.count >= 2 else {
            return Result(normalizedPower: 0, intensityFactor: 0, tss: 0)
        }
        let seconds = expandToSeconds(points)
        let rolling = rollingAverage(seconds)
        let np = normalizedPower(rolling)
        let ifVal = intensityFactor(np: np)
        let durationSecs = Int((points.last?.minutes ?? 0) * 60)
        let tssVal = tss(intensityFactor: ifVal, durationSeconds: durationSecs)
        return Result(normalizedPower: np, intensityFactor: ifVal, tss: tssVal)
    }
}

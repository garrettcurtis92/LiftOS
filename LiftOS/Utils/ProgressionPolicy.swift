import Foundation

/// Minimal progression policy to enable smoke tests for machine progression.
/// This is intentionally simple and self-contained.
struct ProgressionPolicy {
    enum Mode {
        case repFirstThenWeight
    }

    /// Computes next target based on a top set and machine fine step.
    /// - Parameters:
    ///   - topSetWeight: Heaviest completed weight from the most recent completed session.
    ///   - topSetReps: Reps for that top set.
    ///   - targetRepRange: Desired rep range (e.g., 8...12).
    ///   - fineStep: Machine fine step increment (e.g., 5 lb or 2.5 kg).
    ///   - mode: Progression mode.
    /// - Returns: Suggested next weight.
    static func nextWeight(topSetWeight: Double,
                           topSetReps: Int,
                           targetRepRange: ClosedRange<Int>,
                           fineStep: Double,
                           mode: Mode = .repFirstThenWeight) -> Double {
        switch mode {
        case .repFirstThenWeight:
            if topSetReps < targetRepRange.upperBound {
                // Stay at weight, aim for more reps
                return roundToFineStep(topSetWeight, fineStep)
            } else {
                // Hit top of range: add fine step
                return roundToFineStep(topSetWeight + fineStep, fineStep)
            }
        }
    }

    private static func roundToFineStep(_ x: Double, _ step: Double) -> Double {
        guard step > 0 else { return x }
        let n = (x / step).rounded()
        return n * step
    }
}

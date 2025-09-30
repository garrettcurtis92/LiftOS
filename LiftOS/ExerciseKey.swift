import Foundation

/// Single source of truth for normalizing exercise names when used as keys or for lookups.
/// Rules:
/// - trim whitespace/newlines
/// - lowercase
/// - collapse multiple spaces to a single space
/// - remove surrounding punctuation like parentheses, dashes, slashes, brackets at the edges
public enum ExerciseKey {
    /// Normalize an exercise display name into a stable key for indexing.
    public static func normalize(_ raw: String) -> String {
        // 1) Trim and lowercase
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // 2) Collapse multiple spaces to a single space
        while s.contains("  ") { s = s.replacingOccurrences(of: "  ", with: " ") }

        // 3) Remove surrounding punctuation at the edges
        let edgePunctuation = CharacterSet(charactersIn: "-_/()[]{}·•—–")
        s = s.trimmingCharacters(in: edgePunctuation.union(.whitespacesAndNewlines))

        // 4) Also collapse spaces around dashes to a single dash with single spaces
        // e.g., "Bench  Press  --  Incline" -> "bench press -- incline"
        // Keep internal punctuation; we only normalize spacing.
        s = s.replacingOccurrences(of: "\t", with: " ")
        while s.contains("  ") { s = s.replacingOccurrences(of: "  ", with: " ") }

        return s
    }
}

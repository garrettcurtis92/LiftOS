import Foundation

/// Central helper for deciding if a prefill should be applied.
/// Wave C: prefill only if the field is empty and the user has not edited.
enum PrefillPolicy {
    static func shouldPrefill(weightIsEmpty: Bool, userHasEdited: Bool) -> Bool {
        return weightIsEmpty && !userHasEdited
    }
}

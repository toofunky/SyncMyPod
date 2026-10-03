import Foundation

nonisolated extension String {
    /// "player" becomes "Player" for titles; "iPod" is left as it is.
    var deviceKindTitle: String {
        guard let first, first.isLowercase, dropFirst().first?.isUppercase != true else { return self }
        return first.uppercased() + dropFirst()
    }
}

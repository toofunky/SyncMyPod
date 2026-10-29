import Foundation

extension Audiobook {
    /// "3h 12m left" for a started book, otherwise its whole length.
    var progressText: String {
        let remaining = duration - elapsed
        guard isStarted, remaining > 0 else { return Self.formatted(duration) }
        return "\(Self.formatted(remaining)) left"
    }

    static func formatted(_ seconds: TimeInterval) -> String {
        Duration.seconds(seconds).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }
}

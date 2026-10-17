import Foundation

nonisolated enum PodcastFeedError: LocalizedError, Equatable {
    case invalidURL
    case alreadySubscribed(String)
    case httpStatus(Int)
    case notAFeed

    var errorDescription: String? {
        switch self {
        case .invalidURL: "That doesn't look like a web address."
        case .alreadySubscribed(let title): "You're already subscribed to “\(title)”."
        case .httpStatus(let code): "The server responded with an error (\(code))."
        case .notAFeed: "That address isn't a podcast feed."
        }
    }
}

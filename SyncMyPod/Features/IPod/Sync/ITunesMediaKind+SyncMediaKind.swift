import Foundation

nonisolated extension ITunesMediaKind {
    init(_ kind: SyncMediaKind) {
        switch kind {
        case .music: self = .music
        case .podcast: self = .podcast
        case .audiobook: self = .audiobook
        }
    }
}

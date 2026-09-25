import Foundation

enum LibraryScanState: Equatable {
    case idle
    case scanning(LibraryScanProgress)
    case finished(LibraryScanSummary)
    case failed(String)
}

import Foundation

enum LibraryLoadState: Equatable {
    case loading
    case loaded(ITunesDatabase)
    case failed(String)
}

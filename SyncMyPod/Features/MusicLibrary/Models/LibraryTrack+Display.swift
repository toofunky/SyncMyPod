import Foundation

extension LibraryTrack {
    var trackPosition: TagNumberPair { TagNumberPair(number: trackNumber, count: trackCount) }
    var discPosition: TagNumberPair { TagNumberPair(number: discNumber, count: discCount) }
    var codecName: String { codec.displayName }
}

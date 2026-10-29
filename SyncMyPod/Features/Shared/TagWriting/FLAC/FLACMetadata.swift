import Foundation

/// The `fLaC` marker and metadata blocks at the start of a FLAC file, before its audio frames.
nonisolated struct FLACMetadata: Sendable {
    static let marker = Data("fLaC".utf8)

    /// Every block but padding, which `serialized` adds back to fit the space it's given.
    var blocks: [FLACMetadataBlock]
    /// The bytes from the start of the file to the first audio frame.
    let existingLength: Int

    var vorbisComment: VorbisComment {
        blocks.first { $0.type == FLACMetadataBlock.vorbisComment }.flatMap { VorbisComment(data: $0.body) }
            ?? VorbisComment()
    }

    /// Replaces the first Vorbis comment block, dropping any others, or adds one after the stream info.
    mutating func setVorbisComment(_ comment: VorbisComment) {
        let block = FLACMetadataBlock(type: FLACMetadataBlock.vorbisComment, body: comment.serialized())
        replaceBlocks(ofType: FLACMetadataBlock.vorbisComment, with: [block])
    }

    /// Puts `replacements` where the first block of `type` stood, or after the stream info.
    mutating func replaceBlocks(ofType type: UInt8, with replacements: [FLACMetadataBlock]) {
        let index = blocks.firstIndex { $0.type == type }
        blocks.removeAll { $0.type == type }
        blocks.insert(contentsOf: replacements, at: min(index ?? 1, blocks.count))
    }

    /// Exactly `minimumLength` bytes when the blocks fit with room for a padding block's header, or else
    /// just the blocks; a padding block fills the difference.
    func serialized(minimumLength: Int) -> Data {
        var data = Self.marker
        let bodies = blocks.reduce(0) { $0 + FLACMetadataBlock.headerLength + $1.body.count }
        let spare = minimumLength - data.count - bodies - FLACMetadataBlock.headerLength
        let padding = spare >= 0 && spare <= FLACMetadataBlock.maximumLength
            ? [FLACMetadataBlock(type: FLACMetadataBlock.padding, body: Data(count: spare))] : []
        let all = blocks + padding
        for (index, block) in all.enumerated() {
            data.append(block.serialized(isLast: index == all.count - 1))
        }
        return data
    }
}

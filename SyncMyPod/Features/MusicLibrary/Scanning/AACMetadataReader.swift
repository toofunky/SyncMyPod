import AVFoundation

nonisolated struct AACMetadataReader: Sendable {
    /// Returns `nil` when the file's audio isn't AAC (e.g. ALAC in an .m4a container).
    @concurrent
    func read(_ url: URL) async throws -> AudioFileMetadata? {
        let asset = AVURLAsset(url: url)
        guard let track = try await asset.loadTracks(withMediaType: .audio).first,
              let format = try await track.load(.formatDescriptions).first,
              format.mediaSubType == .mpeg4AAC else { return nil }
        let (duration, dataRate) = try await (asset.load(.duration), track.load(.estimatedDataRate))
        let tags = await AudioTagReader(items: try await asset.loadMetadata(for: .iTunesMetadata)).tags()
        return AudioFileMetadata(
            tags: tags,
            duration: duration.seconds,
            bitrate: Int((dataRate / 1_000).rounded()),
            sampleRate: Int(format.audioStreamBasicDescription?.mSampleRate ?? 0)
        )
    }
}

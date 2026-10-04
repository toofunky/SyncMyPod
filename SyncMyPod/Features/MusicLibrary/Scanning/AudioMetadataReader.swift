import AVFoundation

nonisolated struct AudioMetadataReader: Sendable {
    /// Returns `nil` when the file's audio isn't AAC, Apple Lossless, MP3, FLAC, or PCM in AIFF or WAV.
    @concurrent
    func read(_ url: URL) async throws -> AudioFileMetadata? {
        let asset = AVURLAsset(url: url)
        guard let track = try await asset.loadTracks(withMediaType: .audio).first,
              let format = try await track.load(.formatDescriptions).first,
              let codec = AudioCodec(format.mediaSubType, fileExtension: url.pathExtension) else { return nil }
        let (duration, items) = try await (asset.load(.duration), asset.load(.metadata))
        return AudioFileMetadata(
            codec: codec,
            tags: await AudioTagReader(items: items).tags(),
            duration: duration.seconds,
            bitrate: try await bitrate(of: track, at: url),
            sampleRate: Int(format.audioStreamBasicDescription?.mSampleRate ?? 0),
            artworkFingerprint: await CoverArtFingerprint.of(items)
        )
    }

    /// In kbps.
    private func bitrate(of track: AVAssetTrack, at url: URL) async throws -> Int {
        var bitsPerSecond = Double(try await track.load(.estimatedDataRate))
        if bitsPerSecond == 0 { bitsPerSecond = Double(AudioFileBitrate.bitsPerSecond(of: url) ?? 0) }
        return Int((bitsPerSecond / 1_000).rounded())
    }
}

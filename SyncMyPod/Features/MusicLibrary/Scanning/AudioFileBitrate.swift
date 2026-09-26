import AudioToolbox

/// Core Audio's bit rate for a file, which covers MP3 where AVFoundation estimates 0.
nonisolated enum AudioFileBitrate {
    static func bitsPerSecond(of url: URL) -> Int? {
        var fileID: AudioFileID?
        guard AudioFileOpenURL(url as CFURL, .readPermission, 0, &fileID) == noErr, let fileID else { return nil }
        defer { AudioFileClose(fileID) }
        var bitRate: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        guard AudioFileGetProperty(fileID, kAudioFilePropertyBitRate, &size, &bitRate) == noErr else { return nil }
        return Int(bitRate)
    }
}

import Foundation

nonisolated enum IPodSyncError: Error, Equatable, LocalizedError {
    case missingTrackList
    case missingMasterPlaylist
    case insufficientSpace(required: Int64, available: Int64)
    case verificationFailed
    case unsupportedDevice(String)

    var errorDescription: String? {
        switch self {
        case .missingTrackList:
            "The iPod's iTunesDB has no track list."
        case .missingMasterPlaylist:
            "The iPod's iTunesDB has no master playlist."
        case .insufficientSpace(let required, let available):
            "The iPod needs \(Self.format(required)) free but only has \(Self.format(available))."
        case .verificationFailed:
            "The iTunesDB written to the iPod didn't read back correctly, so the previous one was restored."
        case .unsupportedDevice(let name):
            "Adding music to \(name) isn't supported yet. Only the iPod with video (5th and 5.5th Generation) can be synced."
        }
    }

    private static func format(_ bytes: Int64) -> String {
        bytes.formatted(.byteCount(style: .file))
    }
}

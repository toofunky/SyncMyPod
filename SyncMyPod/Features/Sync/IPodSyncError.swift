import Foundation

nonisolated enum IPodSyncError: Error, Equatable, LocalizedError {
    case missingTrackList
    case missingMasterPlaylist
    case insufficientSpace(required: Int64, available: Int64)
    case verificationFailed
    case unsupportedDevice(String)
    case missingFireWireID
    case signatureMismatch

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
            "SyncMyPod couldn't identify \(name) precisely enough to write its library safely."
        case .missingFireWireID:
            "This iPod classic's FireWire ID couldn't be read, so its library can't be signed."
        case .signatureMismatch:
            "The iPod's current library signature doesn't match this device, so nothing was changed. Syncing could make the iPod unable to read its music."
        }
    }

    private static func format(_ bytes: Int64) -> String {
        bytes.formatted(.byteCount(style: .file))
    }
}

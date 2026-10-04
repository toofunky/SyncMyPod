import Foundation

nonisolated enum PlayerSyncError: Error, Equatable, LocalizedError {
    case insufficientSpace(required: Int64, available: Int64)
    case startupDisk
    case iPodVolume
    case missingSource(String)

    var errorDescription: String? {
        switch self {
        case .insufficientSpace(let required, let available):
            "The player needs \(Self.format(required)) free but only has \(Self.format(available))."
        case .startupDisk:
            "Choose a folder on the player's own drive or memory card, not on this Mac's startup disk."
        case .iPodVolume:
            "This drive is an iPod. SyncMyPod syncs it as an iPod automatically whenever it's connected."
        case .missingSource(let name):
            "“\(name)” couldn't be found in your music library folder. Rescan the library and try again."
        }
    }

    private static func format(_ bytes: Int64) -> String {
        bytes.formatted(.byteCount(style: .file))
    }
}

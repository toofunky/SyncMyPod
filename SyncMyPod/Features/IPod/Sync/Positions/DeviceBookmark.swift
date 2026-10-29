import Foundation
import SwiftData

/// The listening position an iPod last had for one synced episode or audiobook file, so a later read can tell
/// whether it was listened to on the iPod since.
@Model
nonisolated final class DeviceBookmark {
    @Attribute(.unique) var key: String
    var deviceID: String
    var sourcePath: String
    /// The iPod's track, so a file synced again, which starts over at 0, isn't taken as finished.
    var databaseID: UInt64
    var position: TimeInterval

    init(deviceID: String, sourcePath: String, databaseID: UInt64, position: TimeInterval) {
        key = Self.key(deviceID: deviceID, sourcePath: sourcePath)
        self.deviceID = deviceID
        self.sourcePath = sourcePath
        self.databaseID = databaseID
        self.position = position
    }

    static func key(deviceID: String, sourcePath: String) -> String {
        "\(deviceID)\u{1F}\(sourcePath)"
    }
}

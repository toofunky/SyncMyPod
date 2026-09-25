import Foundation
import SwiftData

/// What to sync to one iPod, remembered per device.
@Model
nonisolated final class IPodSyncSettings {
    @Attribute(.unique) var deviceID: String
    var modeRawValue = SyncMode.allSongs.rawValue
    var selectedAlbumKeys: [String] = []

    init(deviceID: String) {
        self.deviceID = deviceID
    }

    var mode: SyncMode {
        get { SyncMode(rawValue: modeRawValue) ?? .allSongs }
        set { modeRawValue = newValue.rawValue }
    }

    var selectedAlbums: Set<String> {
        get { Set(selectedAlbumKeys) }
        set { selectedAlbumKeys = newValue.sorted() }
    }

    @MainActor
    static func settings(for deviceID: String, in context: ModelContext) -> IPodSyncSettings {
        let descriptor = FetchDescriptor<IPodSyncSettings>(predicate: #Predicate { $0.deviceID == deviceID })
        if let existing = try? context.fetch(descriptor).first { return existing }
        let settings = IPodSyncSettings(deviceID: deviceID)
        context.insert(settings)
        return settings
    }
}

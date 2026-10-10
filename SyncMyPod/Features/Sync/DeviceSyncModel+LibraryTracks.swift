import SwiftData

extension DeviceSyncModel {
    /// Copies library songs to the device using its saved sync settings.
    func add(_ tracks: [LibraryTrack], to device: ConnectedDevice, in context: ModelContext) {
        sync(syncRequests(for: tracks, to: device, in: context), to: device)
    }

    private func syncRequests(for tracks: [LibraryTrack], to device: ConnectedDevice,
                              in context: ModelContext) -> [IPodSyncRequest] {
        switch device {
        case .iPod(let iPod):
            let settings = IPodSyncSettings.settings(for: device.id, in: context)
            let embedsLyrics = settings.syncsLyricsSidecars && iPod.showsLyrics
            return tracks.filter(\.codec.syncsToIPod).map {
                $0.syncRequest(preservingAlbumArtist: settings.preservesAlbumArtist,
                               embeddingLyricsSidecar: embedsLyrics)
            }
        case .audioPlayer(let player):
            return tracks.map { $0.syncRequest(preservingAlbumArtist: player.config.preserveAlbumArtist) }
        }
    }
}

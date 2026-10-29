import SwiftData

extension DeviceSyncModel {
    /// Copies library songs to the device using its saved sync settings.
    func add(_ tracks: [LibraryTrack], to device: ConnectedDevice, in context: ModelContext) {
        switch device {
        case .iPod(let iPod):
            let settings = DeviceSyncSettings.settings(for: device.id, in: context)
            let embedsLyrics = settings.syncsLyricsSidecars && iPod.showsLyrics
            sync(tracks.filter(\.codec.syncsToIPod).map {
                $0.syncRequest(preservingAlbumArtist: settings.preservesAlbumArtist,
                               embeddingLyricsSidecar: embedsLyrics)
            }, to: iPod)
        case .audioPlayer(let player):
            add(tracks.map { $0.syncRequest(preservingAlbumArtist: player.config.preserveAlbumArtist) }, to: player)
        }
    }
}

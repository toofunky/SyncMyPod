import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class IPodSyncModel {
    private(set) var isSyncing = false
    var result: IPodSyncResult?

    func add(_ tracks: [LibraryTrack], to device: IPodDevice, in context: ModelContext) {
        guard !isSyncing, !tracks.isEmpty else { return }
        guard device.requiresDatabaseHash == false else {
            let name = device.generationDescription ?? "this iPod"
            result = .failed(IPodSyncError.unsupportedDevice(name).localizedDescription)
            return
        }
        isSyncing = true
        let requests = tracks.map(\.syncRequest)
        Task {
            defer { isSyncing = false }
            do {
                let added = try await IPodTrackSyncer(volumeURL: device.volumeURL).add(requests)
                record(added, on: tracks, in: context)
                result = .added(count: added.count, skipped: tracks.count - added.count)
            } catch {
                result = .failed(error.localizedDescription)
            }
        }
    }

    private func record(_ added: [String: UInt64], on tracks: [LibraryTrack], in context: ModelContext) {
        for track in tracks {
            if let databaseID = added[track.filePath] {
                track.iPodDatabaseID = Int64(bitPattern: databaseID)
            }
        }
        try? context.save()
    }
}

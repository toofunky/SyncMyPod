import Foundation

extension LibraryTrack {
    var syncRequest: IPodSyncRequest {
        IPodSyncRequest(sourceURL: URL(filePath: filePath), draft: draft,
                        existingDatabaseID: iPodDatabaseID.map { UInt64(bitPattern: $0) })
    }

    private var draft: ITunesTrackDraft {
        ITunesTrackDraft(title: title, artist: artist, album: album, albumArtist: albumArtist, genre: genre,
                         fileSize: fileSize, duration: duration, trackNumber: trackNumber,
                         trackCount: trackCount, discNumber: discNumber, discCount: discCount, year: year,
                         bitrate: bitrate, sampleRate: sampleRate, dateAdded: .now,
                         lastModified: modificationDate)
    }
}

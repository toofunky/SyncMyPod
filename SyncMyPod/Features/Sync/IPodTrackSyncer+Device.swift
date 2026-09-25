import Foundation

nonisolated extension IPodTrackSyncer {
    /// Picks the artwork formats and database signing the connected model needs.
    init(device: IPodDevice) throws {
        switch device.requiresDatabaseHash {
        case false?:
            self.init(volumeURL: device.volumeURL, formats: ArtworkFormat.videoIPod)
        case true?:
            guard let fireWireID = device.firewireGUID.flatMap(FireWireID.init(hexString:)) else {
                throw IPodSyncError.missingFireWireID
            }
            self.init(volumeURL: device.volumeURL, formats: ArtworkFormat.classicIPod,
                      signer: Hash58(fireWireID: fireWireID))
        case nil:
            throw IPodSyncError.unsupportedDevice(device.generationDescription ?? "this iPod")
        }
    }
}

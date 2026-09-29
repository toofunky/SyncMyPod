import Foundation

nonisolated extension IPodTrackSyncer {
    /// Picks the artwork formats and database signing the connected model needs.
    init(device: IPodDevice) throws {
        switch device.databaseSigning {
        case .unsigned?:
            self.init(volumeURL: device.volumeURL, formats: ArtworkFormat.videoIPod)
        case .hash58?:
            guard let fireWireID = device.firewireGUID.flatMap(FireWireID.init(hexString:)) else {
                throw IPodSyncError.missingFireWireID
            }
            self.init(volumeURL: device.volumeURL, formats: ArtworkFormat.classicIPod,
                      signer: Hash58(fireWireID: fireWireID))
        case .hashAB?:
            throw IPodSyncError.syncNotYetSupported(device.generationDescription ?? "this iPod")
        case nil:
            throw IPodSyncError.unsupportedDevice(device.generationDescription ?? "this iPod")
        }
    }
}

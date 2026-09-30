import Foundation

nonisolated extension IPodTrackSyncer {
    /// Picks the artwork formats and database signing the connected model needs.
    init(device: IPodDevice) throws {
        switch device.databaseSigning {
        case .unsigned?:
            self.init(volumeURL: device.volumeURL, formats: ArtworkFormat.videoIPod)
        case .hash58?:
            self.init(volumeURL: device.volumeURL, formats: ArtworkFormat.classicIPod,
                      signer: Hash58(fireWireID: try Self.fireWireID(of: device)))
        case .hashAB?:
            guard let commands = device.libraryCommands else { throw IPodSyncError.missingLibraryCommands }
            let signer = HashAB(fireWireID: try Self.fireWireID(of: device))
            self.init(volumeURL: device.volumeURL, formats: ArtworkFormat.nano7G, signer: signer,
                      nanoLibrary: NanoLibraryWriter(commands: commands, signer: signer))
        case nil:
            throw IPodSyncError.unsupportedDevice(device.generationDescription ?? "this iPod")
        }
    }

    private static func fireWireID(of device: IPodDevice) throws -> FireWireID {
        guard let id = device.firewireGUID.flatMap(FireWireID.init(hexString:)) else {
            throw IPodSyncError.missingFireWireID
        }
        return id
    }
}

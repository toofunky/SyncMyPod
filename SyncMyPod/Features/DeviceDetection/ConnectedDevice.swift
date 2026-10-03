import Foundation

/// A mounted player the app can sync, whatever its kind.
nonisolated enum ConnectedDevice: Identifiable, Equatable, Sendable {
    case iPod(IPodDevice)
    case audioPlayer(AudioPlayerDevice)

    var id: String {
        switch self {
        case .iPod(let device): device.id
        case .audioPlayer(let device): device.id
        }
    }

    var volumeURL: URL {
        switch self {
        case .iPod(let device): device.volumeURL
        case .audioPlayer(let device): device.volumeURL
        }
    }

    var displayName: String {
        switch self {
        case .iPod(let device): device.volumeName
        case .audioPlayer(let device): device.config.name
        }
    }

    var availableBytes: Int64? {
        switch self {
        case .iPod(let device): device.availableBytes
        case .audioPlayer(let device): device.availableBytes
        }
    }

    var capacityBytes: Int64? {
        switch self {
        case .iPod(let device): device.capacityBytes
        case .audioPlayer(let device): device.capacityBytes
        }
    }

    var isEjectable: Bool {
        switch self {
        case .iPod: true
        case .audioPlayer(let device): device.isEjectable
        }
    }

    var kindName: String {
        switch self {
        case .iPod: "iPod"
        case .audioPlayer: "player"
        }
    }

    var systemImage: String {
        switch self {
        case .iPod: "ipod"
        case .audioPlayer: "headphones"
        }
    }

    /// iPods are recognized first, so a player's config on an iPod volume never hides the iPod.
    @concurrent
    static func scan(volumeAt url: URL) async -> ConnectedDevice? {
        if let iPod = await IPodDevice.scan(volumeAt: url) { return .iPod(iPod) }
        if let player = await AudioPlayerDevice.scan(volumeAt: url) { return .audioPlayer(player) }
        return nil
    }
}

#if DEBUG
nonisolated extension ConnectedDevice {
    static let previewDevices: [ConnectedDevice] = [.iPod(.preview), .audioPlayer(.preview),
                                                    .audioPlayer(.previewFolder)]
}
#endif

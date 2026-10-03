import Foundation

/// A mounted player the app can sync, whatever its kind.
nonisolated enum ConnectedDevice: Identifiable, Equatable, Sendable {
    case iPod(IPodDevice)

    var id: String {
        switch self {
        case .iPod(let device): device.id
        }
    }

    var volumeURL: URL {
        switch self {
        case .iPod(let device): device.volumeURL
        }
    }

    var displayName: String {
        switch self {
        case .iPod(let device): device.volumeName
        }
    }

    var availableBytes: Int64? {
        switch self {
        case .iPod(let device): device.availableBytes
        }
    }

    var capacityBytes: Int64? {
        switch self {
        case .iPod(let device): device.capacityBytes
        }
    }

    var kindName: String {
        switch self {
        case .iPod: "iPod"
        }
    }

    var systemImage: String {
        switch self {
        case .iPod: "ipod"
        }
    }

    @concurrent
    static func scan(volumeAt url: URL) async -> ConnectedDevice? {
        if let iPod = await IPodDevice.scan(volumeAt: url) { return .iPod(iPod) }
        return nil
    }
}

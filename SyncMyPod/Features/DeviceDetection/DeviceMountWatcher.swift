import Foundation
import Observation
import AppKit

@Observable
@MainActor
final class DeviceMountWatcher {
    /// In the order they were attached.
    private(set) var connectedDevices: [ConnectedDevice] = []
    private(set) var ejectingDeviceIDs: Set<String> = []

    @ObservationIgnored
    nonisolated(unsafe) private var mountObserver: NSObjectProtocol?
    @ObservationIgnored
    nonisolated(unsafe) private var unmountObserver: NSObjectProtocol?

    init() {
        observeWorkspaceNotifications()
        scanAlreadyMountedVolumes()
    }

    /// Doesn't watch volumes; for previews and tests.
    init(devices: [ConnectedDevice]) {
        devices.forEach(add)
    }

    #if DEBUG
    static func preview(connectedDevices: [ConnectedDevice] = []) -> DeviceMountWatcher {
        DeviceMountWatcher(devices: connectedDevices)
    }
    #endif

    deinit {
        let center = NSWorkspace.shared.notificationCenter
        if let mountObserver { center.removeObserver(mountObserver) }
        if let unmountObserver { center.removeObserver(unmountObserver) }
    }

    func device(withID id: String) -> ConnectedDevice? {
        connectedDevices.first { $0.id == id }
    }

    func eject(_ device: ConnectedDevice) async throws {
        guard !ejectingDeviceIDs.contains(device.id) else { return }
        ejectingDeviceIDs.insert(device.id)
        defer { ejectingDeviceIDs.remove(device.id) }
        try await Self.unmountAndEject(volumeAt: device.volumeURL)
        removeDevice(at: device.volumeURL)
    }

    /// Replaces a device already listed for the same volume or ID, keeping its place.
    func add(_ device: ConnectedDevice) {
        if let index = connectedDevices.firstIndex(where: { $0.volumeURL == device.volumeURL || $0.id == device.id }) {
            connectedDevices[index] = device
        } else {
            connectedDevices.append(device)
        }
    }

    func removeDevice(at volumeURL: URL) {
        connectedDevices.removeAll { $0.volumeURL == volumeURL }
    }

    @concurrent
    nonisolated private static func unmountAndEject(volumeAt url: URL) async throws {
        try NSWorkspace.shared.unmountAndEjectDevice(at: url)
    }

    private func observeWorkspaceNotifications() {
        let center = NSWorkspace.shared.notificationCenter
        mountObserver = center.addObserver(forName: NSWorkspace.didMountNotification,
                                            object: nil, queue: .main) { [weak self] note in
            guard let url = note.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL else { return }
            Task { @MainActor [weak self] in
                self?.handleVolumeAppeared(at: url)
            }
        }
        unmountObserver = center.addObserver(forName: NSWorkspace.didUnmountNotification,
                                              object: nil, queue: .main) { [weak self] note in
            guard let url = note.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL else { return }
            Task { @MainActor [weak self] in
                self?.removeDevice(at: url)
            }
        }
    }

    private func scanAlreadyMountedVolumes() {
        let keys: [URLResourceKey] = [.volumeNameKey, .volumeIsRemovableKey]
        let urls = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes]) ?? []
        urls.forEach(handleVolumeAppeared)
    }

    private func handleVolumeAppeared(at url: URL) {
        Task {
            guard let device = await ConnectedDevice.scan(volumeAt: url),
                  FileManager.default.fileExists(atPath: url.path) else { return }
            add(device)
        }
    }
}

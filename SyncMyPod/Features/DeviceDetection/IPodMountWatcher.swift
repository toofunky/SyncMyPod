import Foundation
import Observation
import AppKit

@Observable
@MainActor
final class IPodMountWatcher {
    private(set) var connectedDevice: IPodDevice?
    private(set) var isEjecting = false

    @ObservationIgnored
    nonisolated(unsafe) private var mountObserver: NSObjectProtocol?
    @ObservationIgnored
    nonisolated(unsafe) private var unmountObserver: NSObjectProtocol?

    init() {
        observeWorkspaceNotifications()
        scanAlreadyMountedVolumes()
    }

    #if DEBUG
    private init(previewDevice: IPodDevice?) {
        connectedDevice = previewDevice
    }

    static func preview(connectedDevice: IPodDevice? = nil) -> IPodMountWatcher {
        IPodMountWatcher(previewDevice: connectedDevice)
    }
    #endif

    deinit {
        let center = NSWorkspace.shared.notificationCenter
        if let mountObserver { center.removeObserver(mountObserver) }
        if let unmountObserver { center.removeObserver(unmountObserver) }
    }

    func ejectConnectedDevice() async throws {
        guard let device = connectedDevice, !isEjecting else { return }
        isEjecting = true
        defer { isEjecting = false }
        try await Self.unmountAndEject(volumeAt: device.volumeURL)
        handleVolumeDisappeared(at: device.volumeURL)
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
                self?.handleVolumeDisappeared(at: url)
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
            guard let device = await IPodDevice.scan(volumeAt: url),
                  FileManager.default.fileExists(atPath: url.path) else { return }
            connectedDevice = device   // last-attached wins for this slice
        }
    }

    private func handleVolumeDisappeared(at url: URL) {
        guard connectedDevice?.volumeURL == url else { return }
        connectedDevice = nil
    }
}

import Foundation
import Testing
@testable import SyncMyPod

@MainActor
struct DeviceMountWatcherTests {
    private func iPod(_ id: String, volume: String, name: String = "iPod") -> ConnectedDevice {
        .iPod(IPodDevice(id: id, volumeURL: URL(filePath: "/Volumes/\(volume)"), volumeName: name, capacityBytes: nil,
                         availableBytes: nil, sysInfo: IPodSysInfo(), usbIdentity: nil))
    }

    @Test func devicesKeepTheOrderTheyWereAttached() {
        let watcher = DeviceMountWatcher(devices: [iPod("A", volume: "A"), iPod("B", volume: "B")])
        #expect(watcher.connectedDevices.map(\.id) == ["A", "B"])
        #expect(watcher.device(withID: "B")?.volumeURL.lastPathComponent == "B")
    }

    @Test func remountReplacesTheDeviceInPlace() {
        let watcher = DeviceMountWatcher(devices: [iPod("A", volume: "A"), iPod("B", volume: "B")])
        watcher.add(iPod("A", volume: "A 1", name: "Renamed"))
        #expect(watcher.connectedDevices.map(\.id) == ["A", "B"])
        #expect(watcher.connectedDevices[0].displayName == "Renamed")
    }

    @Test func unmountRemovesOnlyThatVolume() {
        let watcher = DeviceMountWatcher(devices: [iPod("A", volume: "A"), iPod("B", volume: "B")])
        watcher.removeDevice(at: URL(filePath: "/Volumes/A"))
        #expect(watcher.connectedDevices.map(\.id) == ["B"])
    }

    @Test func sidebarFallsBackWhenTheSelectedDeviceLeaves() {
        #expect(SidebarItem.fallback(for: .device(id: "A"), connectedIDs: ["B"]) == .device(id: "B"))
        #expect(SidebarItem.fallback(for: .device(id: "A"), connectedIDs: []) == .noDevice)
        #expect(SidebarItem.fallback(for: .noDevice, connectedIDs: ["B"]) == .device(id: "B"))
        #expect(SidebarItem.fallback(for: .device(id: "A"), connectedIDs: ["A", "B"]) == .device(id: "A"))
        #expect(SidebarItem.fallback(for: .playlists, connectedIDs: []) == .playlists)
    }
}

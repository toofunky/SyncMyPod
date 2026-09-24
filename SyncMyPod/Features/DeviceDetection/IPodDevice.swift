import Foundation

struct IPodDevice: Identifiable, Equatable, Sendable {
    let id: String                 // FirewireGuid if present, else the volume path
    let volumeURL: URL
    let volumeName: String
    let capacityBytes: Int64?
    let availableBytes: Int64?
    let sysInfo: IPodSysInfo
    let usbIdentity: IPodUSBIdentity?

    // SysInfo is the authoritative source when iTunes has populated it, but it can be an
    // empty placeholder file (e.g. on a device iTunes never fully synced); the USB
    // descriptor read from IOKit is always available as a fallback.
    var modelNumber: String? { sysInfo.modelNumber }
    var firmwareVersion: String? { sysInfo.firmwareVersion }
    var boardHardwareName: String? { sysInfo.boardHardwareName }
    var firewireGUID: String? { sysInfo.firewireGUID ?? usbIdentity?.serialNumber }
    var serialNumber: String? { sysInfo.serialNumber ?? usbIdentity?.serialNumber }

    init?(scanningVolumeAt url: URL) {
        let controlDir = url.appendingPathComponent("iPod_Control", isDirectory: true)
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: controlDir.path, isDirectory: &isDirectory),
              isDirectory.boolValue else { return nil }

        volumeURL = url
        let values = try? url.resourceValues(forKeys: [
            .volumeNameKey, .volumeTotalCapacityKey, .volumeAvailableCapacityKey
        ])
        volumeName = values?.volumeName ?? url.lastPathComponent
        capacityBytes = values?.volumeTotalCapacity.map(Int64.init)
        availableBytes = values?.volumeAvailableCapacity.map(Int64.init)
        sysInfo = IPodSysInfo(loadingFrom: controlDir) ?? .empty
        usbIdentity = IPodUSBIdentity(volumeURL: url)
        id = sysInfo.firewireGUID ?? usbIdentity?.serialNumber ?? url.path
    }

    init(id: String, volumeURL: URL, volumeName: String, capacityBytes: Int64?,
         availableBytes: Int64?, sysInfo: IPodSysInfo, usbIdentity: IPodUSBIdentity?) {
        self.id = id
        self.volumeURL = volumeURL
        self.volumeName = volumeName
        self.capacityBytes = capacityBytes
        self.availableBytes = availableBytes
        self.sysInfo = sysInfo
        self.usbIdentity = usbIdentity
    }
}

#if DEBUG
extension IPodDevice {
    static let preview = IPodDevice(
        id: "000A270015D4335D",
        volumeURL: URL(fileURLWithPath: "/Volumes/iPod"),
        volumeName: "Michael's iPod",
        capacityBytes: 125_503_913_984,
        availableBytes: 125_159_718_912,
        sysInfo: {
            var info = IPodSysInfo()
            info.modelNumber = "MA146"
            info.firmwareVersion = "1.2"
            info.boardHardwareName = "PP5021"
            return info
        }(),
        usbIdentity: IPodUSBIdentity(vendorString: "Apple", productString: "iPod",
                                      serialNumber: "000A270015D4335D", vendorID: 1452, productID: 4617)
    )
}
#endif

import Foundation
import IOKit
import DiskArbitration

/// Device identity read from macOS's own USB registry (IOKit), rather than from
/// files on the iPod's volume. Classic iPods can leave `iPod_Control/Device/SysInfo`
/// empty (e.g. if iTunes never fully wrote its device-info cache), so this is used
/// as a fallback/supplement — it's always available as long as the device is
/// enumerated as a USB mass-storage device, which every mounted iPod is.
struct IPodUSBIdentity: Equatable, Sendable {
    var vendorString: String?      // kUSBVendorString, e.g. "Apple"
    var productString: String?     // kUSBProductString, e.g. "iPod"
    var serialNumber: String?      // kUSBSerialNumberString — the device's persistent USB serial.
                                    // On USB-only classic iPods this is the same value iTunes
                                    // would otherwise cache as "FirewireGuid" in SysInfo.
    var vendorID: Int?             // idVendor
    var productID: Int?            // idProduct

    init?(volumeURL: URL) {
        guard let bsdName = Self.bsdName(forVolumeAt: volumeURL),
              let info = Self.usbDeviceInfo(forBSDName: bsdName) else { return nil }

        vendorString = info["kUSBVendorString"] as? String
        productString = info["kUSBProductString"] as? String
        serialNumber = info["kUSBSerialNumberString"] as? String
        vendorID = info["idVendor"] as? Int
        productID = info["idProduct"] as? Int

        if vendorString == nil, productString == nil, serialNumber == nil,
           vendorID == nil, productID == nil {
            return nil
        }
    }

    init(vendorString: String?, productString: String?, serialNumber: String?,
         vendorID: Int?, productID: Int?) {
        self.vendorString = vendorString
        self.productString = productString
        self.serialNumber = serialNumber
        self.vendorID = vendorID
        self.productID = productID
    }

    private static func bsdName(forVolumeAt url: URL) -> String? {
        guard let session = DASessionCreate(kCFAllocatorDefault) else { return nil }
        guard let disk = DADiskCreateFromVolumePath(kCFAllocatorDefault, session, url as CFURL) else { return nil }
        guard let cName = DADiskGetBSDName(disk) else { return nil }
        return String(cString: cName)
    }

    /// Walks up the IOKit registry from the volume's disk entry to find the USB
    /// mass-storage interface node, which carries a "USB Device Info" dictionary
    /// with the raw descriptor fields.
    private static func usbDeviceInfo(forBSDName bsdName: String) -> [String: Any]? {
        guard let matchingDict = IOBSDNameMatching(kIOMainPortDefault, 0, bsdName) else { return nil }
        let service = IOServiceGetMatchingService(kIOMainPortDefault, matchingDict)
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }

        let property = IORegistryEntrySearchCFProperty(
            service, kIOServicePlane, "USB Device Info" as CFString, kCFAllocatorDefault,
            IOOptionBits(kIORegistryIterateRecursively | kIORegistryIterateParents)
        )
        return property as? [String: Any]
    }
}

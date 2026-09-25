import Foundation
import IOKit
import IOUSBHost

/// Reads SysInfoExtended straight from the iPod's firmware using the vendor control
/// request libgpod uses, for devices whose on-disk SysInfo files are empty or missing.
nonisolated enum IPodUSBSysInfoReader {
    private static let pageLength = 0x1000
    private static let maximumPages = 64

    static func readSysInfoExtended(locationID: Int) -> String? {
        let matching = IOServiceMatching("IOUSBHostDevice") as NSMutableDictionary
        matching[kIOPropertyMatchKey] = ["locationID": locationID]
        let service = IOServiceGetMatchingService(kIOMainPortDefault, matching)
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }

        guard let device = try? IOUSBHostDevice(__ioService: service, options: [],
                                                queue: nil, interestHandler: nil) else { return nil }
        defer { device.destroy() }
        guard let data = try? readPages(from: device), !data.isEmpty else { return nil }
        return String(decoding: data, as: UTF8.self)
    }

    private static func readPages(from device: IOUSBHostDevice) throws -> Data {
        var result = Data()
        for page in 0..<maximumPages {
            let request = IOUSBDeviceRequest(bmRequestType: 0xC0, bRequest: 0x40, wValue: 0x02,
                                             wIndex: UInt16(page), wLength: UInt16(pageLength))
            let buffer = NSMutableData(length: pageLength)!
            var transferred = 0
            try device.__send(request, data: buffer, bytesTransferred: &transferred, completionTimeout: 5)
            result.append(buffer.subdata(with: NSRange(location: 0, length: transferred)))
            if transferred < pageLength { break }
        }
        return result
    }
}

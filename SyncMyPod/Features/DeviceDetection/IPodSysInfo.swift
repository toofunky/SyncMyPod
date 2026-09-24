import Foundation

struct IPodSysInfo: Equatable, Sendable {
    var modelNumber: String?          // ModelNumStr
    var firewireGUID: String?         // FirewireGuid (legacy key name; still populated on USB-only models)
    var firmwareVersion: String?      // visibleBuildID
    var boardHardwareName: String?    // boardHwName
    var serialNumber: String?         // from SysInfoExtended, may be absent (esp. on 5.5G)

    static let empty = IPodSysInfo()

    init() {}

    /// `controlDirectory` is the volume's `iPod_Control` folder.
    init?(loadingFrom controlDirectory: URL) {
        let sysInfoURL = controlDirectory.appendingPathComponent("Device/SysInfo")
        guard let data = try? Data(contentsOf: sysInfoURL),
              let text = String(data: data, encoding: .utf8)
                        ?? String(data: data, encoding: .isoLatin1) else { return nil }

        var result = IPodSysInfo()
        for rawLine in text.split(whereSeparator: \.isNewline) {
            let parts = rawLine.split(separator: ":", maxSplits: 1)
                .map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2 else { continue }
            switch parts[0] {
            case "ModelNumStr":    result.modelNumber = parts[1]
            case "FirewireGuid":   result.firewireGUID = parts[1]
            case "visibleBuildID": result.firmwareVersion = parts[1]
            case "boardHwName":    result.boardHardwareName = parts[1]
            default: break
            }
        }

        // Optional, newer-generation-only richer info; tolerate absence entirely.
        let extendedURL = controlDirectory.appendingPathComponent("Device/SysInfoExtended")
        if let extData = try? Data(contentsOf: extendedURL),
           let plist = try? PropertyListSerialization.propertyList(from: extData, format: nil) as? [String: Any] {
            result.serialNumber = plist["SerialNumber"] as? String
        }
        self = result
    }
}

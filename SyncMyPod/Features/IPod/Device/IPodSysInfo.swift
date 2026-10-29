import Foundation

nonisolated struct IPodSysInfo: Equatable, Sendable {
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

        let extendedURL = controlDirectory.appendingPathComponent("Device/SysInfoExtended")
        if let extendedXML = try? String(contentsOf: extendedURL, encoding: .utf8) {
            result.mergeExtended(SysInfoExtendedParser.scalarValues(in: extendedXML))
        }
        self = result
    }

    var isMissingExtendedFields: Bool {
        firmwareVersion == nil || serialNumber == nil || firewireGUID == nil
    }

    /// Fills gaps from SysInfoExtended values without overriding anything SysInfo provided.
    mutating func mergeExtended(_ values: [String: String]) {
        serialNumber = serialNumber ?? values["SerialNumber"]
        firmwareVersion = firmwareVersion ?? values["VisibleBuildID"]
        firewireGUID = firewireGUID ?? values["FireWireGUID"]
    }
}

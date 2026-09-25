import Foundation

nonisolated enum IPodModelCatalog {
    static let videoProductID = 0x1209
    static let classicProductID = 0x1261

    /// Used when the exact generation can't be determined; a product ID spans several generations.
    static func familyName(forProductID productID: Int) -> String? {
        switch productID {
        case videoProductID: "iPod (5th or 5.5th Generation)"
        case classicProductID: "iPod classic"
        default: nil
        }
    }

    /// Whether every generation sharing this product ID needs a signed iTunesDB, or `nil` if unknown.
    static func requiresDatabaseHash(forProductID productID: Int) -> Bool? {
        switch productID {
        case videoProductID: false
        case classicProductID: true
        default: nil
        }
    }

    /// Accepts "MA146", "xA146" (SysInfo form) or "MA146LL/A"; the first letter is ignored.
    static func generation(forModelNumber modelNumber: String) -> IPodGeneration? {
        let key = String(modelNumber.dropFirst().prefix(4)).uppercased()
        return generationsByModel[key]
    }

    /// Apple serial numbers end in a three-character model code.
    static func modelNumber(forSerialNumber serialNumber: String) -> String? {
        modelNumbersBySerialSuffix[String(serialNumber.suffix(3)).uppercased()]
    }

    /// Every classic shares one USB product ID, but each generation had its own firmware line:
    /// 6G topped out at 1.1.2, 6.5G at 2.0.1, and 2.0.2+ shipped only on the 7G.
    static func classicGeneration(forFirmwareVersion version: String) -> IPodGeneration? {
        let parts = version.split(separator: ".").compactMap { Int($0) }
        guard let major = parts.first else { return nil }
        guard major >= 2 else { return .classic6G }
        let minor = parts.count > 1 ? parts[1] : 0
        let patch = parts.count > 2 ? parts[2] : 0
        return (minor, patch) < (0, 2) ? .classic6_5G : .classic7G
    }

    private static let generationsByModel: [String: IPodGeneration] = [
        "A002": .video5G, "A146": .video5G, "A003": .video5G, "A147": .video5G, "A452": .video5G,
        "A444": .video5_5G, "A446": .video5_5G, "A448": .video5_5G, "A450": .video5_5G, "A664": .video5_5G,
        "B029": .classic6G, "B147": .classic6G, "B145": .classic6G, "B150": .classic6G,
        "B562": .classic6_5G, "B565": .classic6_5G,
        "C293": .classic7G, "C297": .classic7G
    ]

    private static let modelNumbersBySerialSuffix: [String: String] = [
        "Y5N": "MB029", "YMV": "MB147", "YMU": "MB145", "YMX": "MB150",
        "2C5": "MB562", "2C7": "MB565",
        "9ZS": "MC293", "9ZU": "MC297"
    ]
}

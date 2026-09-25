import Foundation

nonisolated enum IPodModelCatalog {
    /// Accepts "MA146", "xA146" (SysInfo form) or "MA146LL/A"; the first letter is ignored.
    static func generation(forModelNumber modelNumber: String) -> IPodGeneration? {
        let key = String(modelNumber.dropFirst().prefix(4)).uppercased()
        return generationsByModel[key]
    }

    private static let generationsByModel: [String: IPodGeneration] = [
        "A002": .video5G, "A146": .video5G, "A003": .video5G, "A147": .video5G, "A452": .video5G,
        "A444": .video5_5G, "A446": .video5_5G, "A448": .video5_5G, "A450": .video5_5G, "A664": .video5_5G,
        "B029": .classic6G, "B147": .classic6G, "B145": .classic6G, "B150": .classic6G,
        "B562": .classic6_5G, "B565": .classic6_5G,
        "C293": .classic7G, "C297": .classic7G
    ]
}

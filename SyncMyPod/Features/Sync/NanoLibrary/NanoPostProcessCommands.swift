import Foundation

/// The SQL a nano's firmware asks iTunes to run after writing the base library tables. It adds columns,
/// derived tables, "Unknown" entries and indexes, so the library matches what that firmware expects.
nonisolated struct NanoPostProcessCommands: Equatable, Sendable {
    private static let key = "com.apple.mobile.iTunes.SQLMusicLibraryPostProcessCommands"

    /// Stored as Library.itdb's `user_version`.
    let version: Int
    let statements: [String]

    init(version: Int, statements: [String]) {
        self.version = version
        self.statements = statements
    }

    /// Picks the highest-numbered command set in the device's SysInfoExtended.
    init?(sysInfoExtended xml: String) {
        guard let root = Self.propertyList(from: xml),
              let dictionary = root[Self.key] as? [String: Any],
              let sql = dictionary["SQLCommands"] as? [String: String],
              let sets = dictionary["UserVersionCommandSets"] as? [String: Any],
              let version = sets.keys.compactMap(Int.init).max(),
              let set = sets[String(version)] as? [String: Any],
              let names = set["Commands"] as? [String] else { return nil }
        self.init(version: version, statements: names.compactMap { sql[$0] })
    }

    /// Nano firmware writes an empty `<key>` inside an array, which strict plist parsers reject.
    private static func propertyList(from xml: String) -> [String: Any]? {
        let repaired = xml.replacing(#/(<array>\s*)<key></key>\s*/#) { $0.output.1 }
        let data = Data(repaired.utf8)
        return (try? PropertyListSerialization.propertyList(from: data, format: nil)) as? [String: Any]
    }
}

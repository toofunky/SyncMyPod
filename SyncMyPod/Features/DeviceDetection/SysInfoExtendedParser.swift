import Foundation

/// iPod firmware emits SysInfoExtended as an invalid plist (keys inside arrays), which
/// PropertyListSerialization rejects, so scalar values are pulled out textually instead.
nonisolated enum SysInfoExtendedParser {
    static func scalarValues(in xml: String) -> [String: String] {
        let pattern = #/<key>([^<]+)</key>\s*<(?:string|integer)>([^<]*)</#
        var values: [String: String] = [:]
        for match in xml.matches(of: pattern) where values[String(match.1)] == nil {
            values[String(match.1)] = String(match.2)
        }
        return values
    }
}

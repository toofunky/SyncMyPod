import Foundation

nonisolated enum IPodGeneration: String, CaseIterable, Sendable {
    case video5G
    case video5_5G
    case classic6G
    case classic6_5G
    case classic7G
    case nano7G

    var displayName: String {
        switch self {
        case .video5G: "iPod (5th Generation)"
        case .video5_5G: "iPod (5.5th Generation)"
        case .classic6G: "iPod classic (6th Generation)"
        case .classic6_5G: "iPod classic (6.5th Generation)"
        case .classic7G: "iPod classic (7th Generation)"
        case .nano7G: "iPod nano (7th Generation)"
        }
    }

    var databaseSigning: IPodDatabaseSigning {
        switch self {
        case .video5G, .video5_5G: .unsigned
        case .classic6G, .classic6_5G, .classic7G: .hash58
        case .nano7G: .hashAB
        }
    }
}

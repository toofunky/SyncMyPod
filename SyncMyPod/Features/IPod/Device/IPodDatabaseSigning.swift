import Foundation

/// How a model's firmware checks that its music database was written by iTunes.
nonisolated enum IPodDatabaseSigning: Sendable {
    case unsigned
    case hash58
    case hashAB

    var displayName: String {
        switch self {
        case .unsigned: "None"
        case .hash58: "hash58"
        case .hashAB: "hashAB"
        }
    }
}

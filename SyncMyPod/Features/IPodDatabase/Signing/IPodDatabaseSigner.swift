import Foundation

/// Signs the music database the way a model's firmware checks it.
nonisolated protocol IPodDatabaseSigner: Sendable {
    func sign(_ database: Data) throws -> Data
    /// Whether an already signed database carries the signature this device's key produces.
    func isValid(_ database: Data) -> Bool
    /// Whether the database claims to be signed with this scheme at all.
    static func isSigned(_ database: Data) -> Bool
}

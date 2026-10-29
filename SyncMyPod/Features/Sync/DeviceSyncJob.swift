import Foundation

/// One sync to one device. Each kind of device supplies its own, so `DeviceSyncModel` needn't know them.
nonisolated protocol DeviceSyncJob: Sendable {
    var deviceID: String { get }
    /// "iPod", for example, as shown in the result's title and message.
    var deviceKind: String { get }
    /// How many files the progress bar counts.
    var total: Int { get }

    func run(progress: @escaping @Sendable (SyncProgress) async -> Void) async throws -> DeviceSyncCompletion
}

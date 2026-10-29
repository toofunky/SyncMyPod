import Foundation

/// The stored model keeps its original class name, since SwiftData names its table after it and renaming
/// would drop every device's saved sync choices.
typealias DeviceSyncSettings = IPodSyncSettings

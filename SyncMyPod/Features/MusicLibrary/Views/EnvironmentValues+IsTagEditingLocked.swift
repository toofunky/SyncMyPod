import SwiftUI

extension EnvironmentValues {
    /// Set while a scan or sync is reading the files, when saving tags would race it.
    @Entry var isTagEditingLocked = false
}

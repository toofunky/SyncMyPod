import SwiftUI

extension EnvironmentValues {
    /// Empty while nothing is connected or a sync is running.
    @Entry var libraryAddTargets: [LibraryAddTarget] = []
}

import SwiftData
import SwiftUI

extension View {
    /// Editing a song's tags changes it in place, which leaves a query's results equal, so views
    /// that group or sort songs also rebuild whenever the library saves.
    func onModelContextSave(perform action: @escaping @MainActor () -> Void) -> some View {
        task {
            for await _ in NotificationCenter.default.notifications(named: ModelContext.didSave) {
                action()
            }
        }
    }
}

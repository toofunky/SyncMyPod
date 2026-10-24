import SwiftData
import SwiftUI

/// The task only counts saves: its closure keeps the view from when it started, so running the action there would
/// read stale properties. `onChange` runs the action against the current view instead.
struct ModelContextSaveModifier: ViewModifier {
    let action: @MainActor () -> Void

    @State private var saveCount = 0

    func body(content: Content) -> some View {
        content
            .task {
                for await _ in NotificationCenter.default.notifications(named: ModelContext.didSave) {
                    saveCount += 1
                }
            }
            .onChange(of: saveCount) { action() }
    }
}

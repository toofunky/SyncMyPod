import SwiftUI

/// Presents the shared sync model's progress and result over any view that can start a sync.
struct SyncProgressSheetModifier: ViewModifier {
    @Environment(DeviceSyncModel.self) private var model

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: isPresented) {
                SyncProgressSheet(progress: model.progress, result: model.result, deviceKind: model.syncingDeviceKind,
                                  isCancelling: model.isCancelling, onCancel: model.cancel, onDone: { model.result = nil })
                    .interactiveDismissDisabled(model.isSyncing)
            }
    }

    private var isPresented: Binding<Bool> {
        Binding(get: { model.isSyncing || model.result != nil },
                set: { if !$0, !model.isSyncing { model.result = nil } })
    }
}

extension View {
    func syncProgressSheet() -> some View {
        modifier(SyncProgressSheetModifier())
    }
}

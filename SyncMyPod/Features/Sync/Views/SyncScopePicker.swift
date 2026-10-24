import SwiftUI

/// Chooses whether all, the selected or none of one kind of content syncs.
struct SyncScopePicker: View {
    let category: SyncCategory
    @Binding var scope: SyncScope

    var body: some View {
        Picker("Sync \(category.contentTitle)", selection: $scope) {
            ForEach(SyncScope.allCases) { Text(title(for: $0)).tag($0) }
        }
        .pickerStyle(.radioGroup)
        .horizontalRadioGroupLayout()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func title(for scope: SyncScope) -> String {
        switch scope {
        case .all: "All \(category.contentTitle)"
        case .selected: "Selected"
        case .none: "None"
        }
    }
}

#Preview {
    @Previewable @State var scope = SyncScope.selected
    SyncScopePicker(category: .podcasts, scope: $scope)
        .padding()
}

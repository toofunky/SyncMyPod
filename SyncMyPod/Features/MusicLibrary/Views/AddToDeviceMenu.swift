import SwiftUI

/// A button for a single connected device, or a menu of them when there are several.
struct AddToDeviceMenu: View {
    let targets: [LibraryAddTarget]
    let onAdd: (LibraryAddTarget) -> Void

    var body: some View {
        if targets.count > 1 {
            Menu("Add to Device", systemImage: "ipod") {
                ForEach(targets) { target in
                    Button(target.name, systemImage: target.systemImage) { onAdd(target) }
                }
            }
        } else if let target = targets.first {
            Button("Add to \(target.name)", systemImage: target.systemImage) { onAdd(target) }
        } else {
            Button("Add to iPod", systemImage: "ipod") {}
                .disabled(true)
        }
    }
}

#if DEBUG
#Preview("Several") {
    AddToDeviceMenu(targets: LibraryAddTarget.previews, onAdd: { _ in })
        .padding()
}

#Preview("One") {
    AddToDeviceMenu(targets: [LibraryAddTarget.previews[0]], onAdd: { _ in })
        .padding()
}
#endif

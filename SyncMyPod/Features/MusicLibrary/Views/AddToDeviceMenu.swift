import SwiftUI

/// A button for a single connected device, or a menu of them when there are several.
struct AddToDeviceMenu: View {
    let devices: [ConnectedDevice]
    let onAdd: (ConnectedDevice) -> Void

    var body: some View {
        if devices.count > 1 {
            Menu("Add to Device", systemImage: "ipod") {
                ForEach(devices) { device in
                    Button(device.displayName, systemImage: device.systemImage) { onAdd(device) }
                }
            }
        } else if let device = devices.first {
            Button("Add to \(device.displayName)", systemImage: device.systemImage) { onAdd(device) }
        } else {
            Button("Add to iPod", systemImage: "ipod") {}
                .disabled(true)
        }
    }
}

#if DEBUG
#Preview("Several") {
    AddToDeviceMenu(devices: [.iPod(.preview), .iPod(.previewNano)], onAdd: { _ in })
        .padding()
}

#Preview("One") {
    AddToDeviceMenu(devices: [.iPod(.preview)], onAdd: { _ in })
        .padding()
}
#endif

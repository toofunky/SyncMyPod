import SwiftUI

struct DeviceInfoView: View {
    let device: IPodDevice

    var body: some View {
        Form {
            Section("Volume") {
                LabeledContent("Name", value: device.volumeName)
                LabeledContent("Capacity", value: Self.format(device.capacityBytes))
                LabeledContent("Free Space", value: Self.format(device.availableBytes))
            }
            Section("Device Identity") {
                LabeledContent("Generation", value: device.generationDescription ?? "Unknown")
                LabeledContent("Model", value: device.modelNumber ?? "Unknown")
                LabeledContent("Firmware", value: device.firmwareVersion ?? "Unknown")
                if let boardHardwareName = device.boardHardwareName {
                    LabeledContent("Hardware Board", value: boardHardwareName)
                }
                LabeledContent("Serial Number", value: device.serialNumber ?? "Unknown")
                LabeledContent("FireWire GUID", value: device.firewireGUID ?? "Unknown")
            }
            if let usb = device.usbIdentity {
                Section("USB Descriptor") {
                    LabeledContent("Vendor", value: usb.vendorString ?? "Unknown")
                    LabeledContent("Product", value: usb.productString ?? "Unknown")
                    if let vendorID = usb.vendorID, let productID = usb.productID {
                        LabeledContent("Vendor / Product ID",
                                       value: String(format: "0x%04X / 0x%04X", vendorID, productID))
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private static func format(_ bytes: Int64?) -> String {
        guard let bytes else { return "Unknown" }
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

#if DEBUG
#Preview {
    DeviceInfoView(device: .preview)
}
#endif

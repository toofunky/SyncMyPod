import SwiftUI

struct InfoPopoverButton: View {
    private static let popoverWidth = 280.0
    private static let textSpacing = 6.0

    let title: String
    let message: String

    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel("About \(title)")
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: Self.textSpacing) {
                Text(title).font(.headline)
                Text(message).fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: Self.popoverWidth, alignment: .leading)
            .padding()
        }
    }
}

#Preview {
    InfoPopoverButton(title: "Preserve Album Artist",
                      message: "Files songs under the album artist and adds the guest artist to the title.")
        .padding()
}

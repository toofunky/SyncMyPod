import SwiftUI

struct ToolbarSearchField: View {
    private static let width = 220.0

    let prompt: String
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField(prompt, text: $text)
                .textFieldStyle(.plain)
            if !text.isEmpty {
                Button("Clear Search", systemImage: "xmark.circle.fill") { text = "" }
                    .buttonStyle(.borderless)
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .frame(width: Self.width)
    }
}

#if DEBUG
#Preview {
    @Previewable @State var text = "Pink Floyd"
    ToolbarSearchField(prompt: "Search Library", text: $text)
        .padding()
}
#endif

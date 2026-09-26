import SwiftUI
import UniformTypeIdentifiers

struct TagArtworkWell: View {
    private static let cornerRadius = 8.0
    private static let dropHighlightWidth = 2.0

    let artwork: TagArtworkPreview
    /// Returns `false` when the data isn't an image that can be embedded.
    let onReplace: (Data) -> Bool
    let onRemove: () -> Void

    @State private var isChoosingImage = false
    @State private var isDropTargeted = false
    @State private var isShowingUnsupported = false

    var body: some View {
        VStack {
            well
                .dropDestination(for: URL.self) { urls, _ in
                    replace(from: urls.first)
                } isTargeted: { isDropTargeted = $0 }
            HStack {
                Button("Choose…") { isChoosingImage = true }
                Button("Remove", role: .destructive, action: onRemove)
                    .disabled(isEmpty)
            }
        }
        .fileImporter(isPresented: $isChoosingImage, allowedContentTypes: [.jpeg, .png]) { result in
            if case .success(let url) = result { replace(from: url) }
        }
        .alert("Unsupported Image", isPresented: $isShowingUnsupported) {
        } message: {
            Text("Cover art must be a JPEG or PNG image.")
        }
    }

    private var well: some View {
        RoundedRectangle(cornerRadius: Self.cornerRadius)
            .fill(.quaternary)
            .aspectRatio(1, contentMode: .fit)
            .overlay { content }
            .clipShape(.rect(cornerRadius: Self.cornerRadius))
            .overlay {
                if isDropTargeted {
                    RoundedRectangle(cornerRadius: Self.cornerRadius)
                        .stroke(.tint, lineWidth: Self.dropHighlightWidth)
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch artwork {
        case .image(let image):
            Image(decorative: image, scale: 1)
                .resizable()
                .scaledToFill()
        case .mixed:
            Text("Mixed")
                .foregroundStyle(.secondary)
        case .none:
            Image(systemName: "photo")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        }
    }

    private var isEmpty: Bool {
        if case .none = artwork { true } else { false }
    }

    @discardableResult
    private func replace(from url: URL?) -> Bool {
        guard let url else { return false }
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url), onReplace(data) else {
            isShowingUnsupported = true
            return false
        }
        return true
    }
}

#Preview {
    TagArtworkWell(artwork: .none, onReplace: { _ in true }, onRemove: {})
        .padding()
}

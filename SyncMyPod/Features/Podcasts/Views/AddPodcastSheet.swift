import SwiftData
import SwiftUI

/// Subscribes to a podcast by its feed address; the name and artwork come from the feed itself.
struct AddPodcastSheet: View {
    var onSubscribe: (Podcast) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(PodcastsModel.self) private var model
    @State private var address = ""
    @State private var isSubscribing = false
    @State private var errorMessage: String?

    private static let width: CGFloat = 440

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Podcast")
                .font(.headline)
            Text("Paste the podcast's RSS feed address. Its name and artwork are read from the feed.")
                .font(.callout)
                .foregroundStyle(.secondary)
            TextField("Feed Address", text: $address, prompt: Text("https://example.com/feed.xml"))
                .labelsHidden()
                .textFieldStyle(.roundedBorder)
                .disabled(isSubscribing)
                .onSubmit(subscribe)
            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .font(.callout)
                    .foregroundStyle(.red)
            }
            buttons
        }
        .padding()
        .frame(width: Self.width)
    }

    private var buttons: some View {
        HStack {
            if isSubscribing {
                ProgressView()
                    .controlSize(.small)
                Text("Reading feed…")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Cancel", role: .cancel) { dismiss() }
                .keyboardShortcut(.cancelAction)
            Button("Add", action: subscribe)
                .keyboardShortcut(.defaultAction)
                .disabled(address.trimmingCharacters(in: .whitespaces).isEmpty || isSubscribing)
        }
    }

    private func subscribe() {
        guard !isSubscribing else { return }
        errorMessage = nil
        isSubscribing = true
        Task {
            defer { isSubscribing = false }
            do {
                onSubscribe(try await model.subscribe(to: address, in: context))
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#if DEBUG
#Preview {
    AddPodcastSheet { _ in }
        .environment(PodcastsModel())
        .modelContainer(.emptyPreview)
}
#endif

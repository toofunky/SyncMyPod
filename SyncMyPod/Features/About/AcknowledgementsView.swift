import SwiftUI
import WebKit

struct AcknowledgementsView: View {
    @Environment(\.dismiss) private var dismiss

    private static let creditsURL = Bundle.main.url(forResource: "Credits", withExtension: "html")

    var body: some View {
        VStack(spacing: 0) {
            WebView(url: Self.creditsURL)
                .webViewBackForwardNavigationGestures(.disabled)
            Divider()
            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(minWidth: 480, minHeight: 400)
    }
}

#Preview {
    AcknowledgementsView()
}

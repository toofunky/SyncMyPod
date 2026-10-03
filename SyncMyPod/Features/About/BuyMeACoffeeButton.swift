import SwiftUI

struct BuyMeACoffeeButton: View {
    static let url = URL(string: "https://buymeacoffee.com/Ogr7PoWL9a")

    private static let size: CGFloat = 32

    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            if let url = Self.url {
                openURL(url)
            }
        } label: {
            Image("BuyMeACoffee")
                .resizable()
                .scaledToFit()
                .frame(width: Self.size, height: Self.size)
                .clipShape(.circle)
        }
        .buttonStyle(.plain)
        .help("Buy Me a Coffee")
        .accessibilityLabel("Buy Me a Coffee")
    }
}

#Preview {
    BuyMeACoffeeButton()
        .padding()
}

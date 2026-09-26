import SwiftUI

struct AboutView: View {
    static let windowID = "about"

    @Environment(\.openURL) private var openURL

    private static let websiteURL = URL(string: "https://github.com/toofunky/SyncMyPod")
    private static let releaseNotesURL = URL(string: "https://github.com/toofunky/SyncMyPod/blob/main/RELEASES.md")

    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "SyncMyPod"
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "–"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
            Text(appName)
                .font(.title2.bold())
            Text("A modern app for syncing music from your Mac to a classic, click-wheel iPod.")
            Text(versionText)
                .font(.callout)
                .foregroundStyle(.secondary)
            Text("© 2026 Major Talent Studios LLC")
                .font(.callout)
            HStack {
                Button("Website") {
                    if let url = Self.websiteURL {
                        openURL(url)
                    }
                }
                Button("Release Notes") {
                    if let url = Self.releaseNotesURL {
                        openURL(url)
                    }
                }
                Button("Acknowledgements") {
                    if let url = Bundle.main.url(forResource: "Credits", withExtension: "html") {
                        openURL(url)
                    }
                }
            }
        }
        .padding()
        .frame(minWidth: 280)
    }
}

#Preview {
    AboutView()
}

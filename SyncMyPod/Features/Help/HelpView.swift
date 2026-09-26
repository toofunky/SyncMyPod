import SwiftUI

struct HelpView: View {
    static let windowID = "help"
    private static let sidebarMinWidth = 180.0
    private static let sidebarIdealWidth = 200.0

    @State private var selection: HelpTopic? = .gettingStarted

    var body: some View {
        NavigationSplitView {
            List(HelpTopic.allCases, selection: $selection) { topic in
                Label(topic.title, systemImage: topic.systemImage)
            }
            .navigationSplitViewColumnWidth(min: Self.sidebarMinWidth, ideal: Self.sidebarIdealWidth)
        } detail: {
            if let selection {
                HelpTopicView(topic: selection)
            } else {
                ContentUnavailableView("No Topic Selected", systemImage: "questionmark.circle",
                                       description: Text("Choose a help topic from the sidebar."))
            }
        }
        .frame(minWidth: 640, minHeight: 440)
    }
}

#Preview {
    HelpView()
}

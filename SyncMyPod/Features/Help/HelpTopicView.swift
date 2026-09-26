import SwiftUI

struct HelpTopicView: View {
    private static let sectionSpacing = 20.0
    private static let bodySpacing = 6.0
    private static let maxReadableWidth = 560.0

    let topic: HelpTopic

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Self.sectionSpacing) {
                header
                ForEach(topic.sections) { section in
                    VStack(alignment: .leading, spacing: Self.bodySpacing) {
                        Text(section.heading)
                            .font(.headline)
                        Text(LocalizedStringKey(section.body))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .frame(maxWidth: Self.maxReadableWidth, alignment: .leading)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(topic.title)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Self.bodySpacing) {
            Label(topic.title, systemImage: topic.systemImage)
                .font(.title.bold())
            Text(topic.summary)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    HelpTopicView(topic: .gettingStarted)
        .frame(width: 520, height: 520)
}

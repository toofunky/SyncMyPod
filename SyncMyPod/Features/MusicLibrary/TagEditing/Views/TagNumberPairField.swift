import SwiftUI

/// A "3 of 12" pair, such as a track or disc position.
struct TagNumberPairField: View {
    let title: String
    @Binding var number: String
    @Binding var count: String
    var numberPrompt = ""
    var countPrompt = ""

    var body: some View {
        LabeledContent(title) {
            HStack {
                TextField(TagField.trackNumber.label, text: digits($number), prompt: Text(numberPrompt))
                    .labelsHidden()
                Text("of")
                    .foregroundStyle(.secondary)
                TextField(TagField.trackCount.label, text: digits($count), prompt: Text(countPrompt))
                    .labelsHidden()
            }
        }
    }

    private func digits(_ text: Binding<String>) -> Binding<String> {
        Binding { text.wrappedValue } set: { text.wrappedValue = $0.filter { $0.isASCII && $0.isNumber } }
    }
}

#Preview {
    @Previewable @State var number = "3"
    @Previewable @State var count = ""
    Form {
        TagNumberPairField(title: "Track", number: $number, count: $count, countPrompt: "Mixed")
    }
    .formStyle(.grouped)
}

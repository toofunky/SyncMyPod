import SwiftUI

struct AlbumGridControls: View {
    static let columnRange = 2.0...6.0
    private static let sliderWidth = 120.0

    @Binding var sortOrder: AlbumSortOrder
    @Binding var columnCount: Double

    var body: some View {
        HStack {
            Spacer()
            Picker("Sort By", selection: $sortOrder) {
                ForEach(AlbumSortOrder.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.menu)
            .fixedSize()
            Slider(value: $columnCount, in: Self.columnRange, step: 1) {
                Text("Albums Across")
            } minimumValueLabel: {
                Image(systemName: "square.grid.2x2")
            } maximumValueLabel: {
                Image(systemName: "square.grid.3x3")
            }
            .labelsHidden()
            .frame(width: Self.sliderWidth)
            .help("Albums Across")
        }
        .controlSize(.small)
        .padding(.horizontal)
    }
}

#Preview {
    @Previewable @State var sortOrder = AlbumSortOrder.albumArtist
    @Previewable @State var columnCount = 4.0
    AlbumGridControls(sortOrder: $sortOrder, columnCount: $columnCount)
        .frame(width: 500)
        .padding(.vertical)
}

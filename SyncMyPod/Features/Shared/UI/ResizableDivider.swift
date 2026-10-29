import SwiftUI

/// A divider for an `HStack` that resizes the view before it by dragging, kept within `range`.
///
/// Used instead of `HSplitView`, which breaks inside the window's split view on macOS 27.
struct ResizableDivider: View {
    private static let grabWidth = 8.0

    @Binding var width: Double
    let range: ClosedRange<Double>

    @State private var dragStartWidth: Double?

    var body: some View {
        Divider()
            .overlay {
                Color.clear
                    .frame(width: Self.grabWidth)
                    .contentShape(.rect)
                    .pointerStyle(.columnResize)
                    .gesture(drag)
            }
            // Keeps the grab area above the view after the divider, which it overlaps.
            .zIndex(1)
    }

    /// Measured in global coordinates, since the divider moves under the pointer as the width changes.
    private var drag: some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .onChanged { value in
                let startWidth = dragStartWidth ?? width
                dragStartWidth = startWidth
                width = min(max(startWidth + value.translation.width, range.lowerBound), range.upperBound)
            }
            .onEnded { _ in dragStartWidth = nil }
    }
}

#if DEBUG
#Preview {
    @Previewable @State var width = 200.0
    HStack(spacing: 0) {
        Color.blue.opacity(0.2)
            .frame(width: width)
        ResizableDivider(width: $width, range: 120...320)
        Color.green.opacity(0.2)
    }
    .frame(width: 600, height: 300)
}
#endif

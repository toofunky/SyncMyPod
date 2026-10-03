import SwiftUI

/// A thin progress bar whose knob appears only under the pointer; clicking or dragging picks a new position.
struct PlaybackScrubber: View {
    private static let trackHeight = 4.0
    private static let knobSize = 16.0
    private static let knobShadowRadius = 1.0
    private static let accessibilityStep = 0.05
    private static let hoverAnimation = Animation.easeOut(duration: 0.15)

    /// From 0 at the start to 1 at the end.
    let fraction: Double
    let onScrub: (Double) -> Void
    let onCommit: (Double) -> Void

    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovering = false
    @State private var isDragging = false

    var body: some View {
        GeometryReader { proxy in
            bar(width: proxy.size.width)
                .frame(maxHeight: .infinity)
                .contentShape(.rect)
                .gesture(drag(width: proxy.size.width))
        }
        .frame(height: Self.knobSize)
        .onHover { isHovering = $0 }
        .animation(Self.hoverAnimation, value: isHovering)
        .accessibilityElement()
        .accessibilityLabel("Playback Position")
        .accessibilityValue(Text(fraction, format: .percent.precision(.fractionLength(0))))
        .accessibilityAdjustableAction(adjust)
    }

    private func bar(width: Double) -> some View {
        let filled = width * clamped(fraction)
        return ZStack(alignment: .leading) {
            Capsule()
                .fill(.quaternary)
                .frame(height: Self.trackHeight)
            Capsule()
                .fill(.secondary)
                .frame(width: filled, height: Self.trackHeight)
            Circle()
                .fill(.white)
                .shadow(radius: Self.knobShadowRadius)
                .frame(width: Self.knobSize, height: Self.knobSize)
                .offset(x: filled - Self.knobSize / 2)
                .opacity(isEnabled && (isHovering || isDragging) ? 1 : 0)
        }
    }

    private func drag(width: Double) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                isDragging = true
                onScrub(clamped(value.location.x / width))
            }
            .onEnded { value in
                isDragging = false
                onCommit(clamped(value.location.x / width))
            }
    }

    private func adjust(_ direction: AccessibilityAdjustmentDirection) {
        let step = direction == .increment ? Self.accessibilityStep : -Self.accessibilityStep
        onCommit(clamped(fraction + step))
    }

    private func clamped(_ value: Double) -> Double {
        value.isFinite ? min(max(value, 0), 1) : 0
    }
}

#if DEBUG
#Preview {
    PlaybackScrubber(fraction: 0.4, onScrub: { _ in }, onCommit: { _ in })
        .frame(width: 200)
        .padding()
}
#endif

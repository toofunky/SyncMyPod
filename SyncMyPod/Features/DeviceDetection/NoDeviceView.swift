import SwiftUI

struct NoDeviceView: View {
    var body: some View {
        ContentUnavailableView {
            Label("No Device Connected", systemImage: "ipod")
        } description: {
            Text("Connect a click-wheel iPod via USB, or add a digital audio player that shows up as a drive "
                 + "or memory card.")
        } actions: {
            AddAudioPlayerButton()
        }
    }
}

#if DEBUG
#Preview {
    NoDeviceView()
        .environment(DeviceMountWatcher.preview())
}
#endif

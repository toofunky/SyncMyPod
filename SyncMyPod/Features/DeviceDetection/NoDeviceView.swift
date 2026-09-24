import SwiftUI

struct NoDeviceView: View {
    var body: some View {
        ContentUnavailableView(
            "No iPod Connected",
            systemImage: "ipod",
            description: Text("Connect a click-wheel iPod via USB to see its details here.")
        )
    }
}

#Preview {
    NoDeviceView()
}

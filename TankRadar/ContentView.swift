import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("TankRadar")
            .font(.title)
    }
}

#Preview {
    ContentView()
        .environment(LocationService())
}

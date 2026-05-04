import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            MapScreen()
        }
    }
}

#Preview {
    ContentView()
        .environment(LocationService())
        .environment(StationStore())
}

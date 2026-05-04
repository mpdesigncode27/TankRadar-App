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
        .environment(MapDeepLinkStore(defaults: UserDefaults(suiteName: "tr.preview.ContentView.deeplink")!))
}

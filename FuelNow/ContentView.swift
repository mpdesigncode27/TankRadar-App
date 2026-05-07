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
        .environment(EntitlementManager())
        .environment(NetworkMonitor())
        .environment(MapDeepLinkStore(defaults: UserDefaults(suiteName: "tr.preview.ContentView.deeplink")!))
}

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(.brandGlyph)
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: 56, height: 56)
                .foregroundStyle(.trAccent)

            Text("TankRadar")
                .font(.title.bold())
                .foregroundStyle(.trLabelPrimary)

            Text("Design tokens (TAN-74)")
                .font(.subheadline)
                .foregroundStyle(.trLabelSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.trBackground)
    }
}

#Preview {
    ContentView()
        .environment(LocationService())
}

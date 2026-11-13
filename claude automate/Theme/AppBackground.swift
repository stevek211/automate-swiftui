import SwiftUI

/// App-wide page background: soft grey that warms to cream at the bottom
/// (from the Figma "My Garage" frames, 500:2 / 496:2339).
struct AppBackground: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: .garageGradientTop, location: 0),
                .init(color: .garageGradientTop, location: 0.7),
                .init(color: .garageGradientEnd, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

extension View {
    /// Puts the shared page gradient behind this screen, edge to edge.
    func appBackground() -> some View {
        background(AppBackground().ignoresSafeArea())
    }
}

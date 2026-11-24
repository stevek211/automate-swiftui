import SwiftUI

/// Persistent banner shown at the top of every screen when appState.isDemo == true.
/// Shows "Exploring demo data" with a "Back to my garage" button.
struct DemoBanner: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.isDemo {
            HStack(spacing: 8) {
                Image(systemName: "eye.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.agAccent)
                Text("Exploring demo data")
                    .font(.quicksandScaled(.semibold, size: 12))
                    .foregroundStyle(Color.agForeground)
                Spacer()
                Button {
                    withAnimation(.spring(duration: 0.25)) {
                        appState.isDemo = false
                    }
                } label: {
                    HStack(spacing: 3) {
                        Text("Back to my garage")
                            .font(.quicksandScaled(.semibold, size: 11))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(Color.agPrimary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.agAccent.opacity(0.08))
            .overlay(
                Rectangle()
                    .fill(Color.agAccent.opacity(0.3))
                    .frame(height: 1),
                alignment: .bottom
            )
        }
    }
}

#Preview {
    DemoBanner()
        .environment({
            let s = AppState()
            s.isDemo = true
            return s
        }())
}

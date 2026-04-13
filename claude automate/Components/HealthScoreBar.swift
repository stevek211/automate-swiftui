import SwiftUI

struct HealthScoreBar: View {
    let current: Int
    let total: Int

    @State private var animatedProgress: CGFloat = 0

    var progress: CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(current) / CGFloat(total)
    }

    var color: Color {
        if progress >= 0.9 { return .agSuccess }
        if progress >= 0.6 { return .agWarning }
        return .agDestructive
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AGSpacing.sm) {
            HStack {
                Text("\(current) of \(total) items current")
                    .font(.jakartaCaption)
                    .foregroundStyle(Color.agMutedForeground)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.jakartaCaption)
                    .foregroundStyle(color)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.agMuted)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * animatedProgress, height: 8)
                }
            }
            .frame(height: 8)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = progress
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        HealthScoreBar(current: 5, total: 6)
        HealthScoreBar(current: 3, total: 6)
        HealthScoreBar(current: 1, total: 6)
    }
    .padding()
}

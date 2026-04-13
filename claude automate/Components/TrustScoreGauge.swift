import SwiftUI

struct TrustScoreGauge: View {
    let score: Int
    let assessment: PriceAssessment
    @State private var animatedScore: CGFloat = 0

    var color: Color {
        switch assessment {
        case .great: return .agSuccess
        case .fair: return .agSuccess
        case .suspicious: return .agWarning
        case .overpriced: return .agDestructive
        }
    }

    var body: some View {
        VStack(spacing: AGSpacing.md) {
            ZStack {
                // Background arc
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(Color.agMuted, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(135))

                // Score arc
                Circle()
                    .trim(from: 0, to: animatedScore * 0.75)
                    .stroke(color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(135))

                // Score text
                VStack(spacing: 2) {
                    Text("\(score)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                    Text("Trust Score")
                        .font(.jakartaCaption)
                        .foregroundStyle(Color.agMutedForeground)
                }
            }
            .frame(width: 140, height: 140)

            // Assessment badge
            Text(assessment.rawValue)
                .font(.jakartaHeadline)
                .foregroundStyle(color)
                .padding(.horizontal, AGSpacing.lg)
                .padding(.vertical, AGSpacing.sm)
                .background(color.opacity(0.1))
                .clipShape(Capsule())
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                animatedScore = CGFloat(score) / 100.0
            }
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        TrustScoreGauge(score: 85, assessment: .fair)
        TrustScoreGauge(score: 35, assessment: .overpriced)
    }
}

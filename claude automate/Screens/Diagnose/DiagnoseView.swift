import SwiftUI

struct DiagnoseCategoryCard: View {
    let category: DiagnosticCategory
    let action: () -> Void

    var iconBg: Color {
        switch category {
        case .warningLight: return Color.agWarning10
        case .strangeNoise: return Color.agDestructive10
        case .unusualSmell: return Color.agPrimary10
        case .fluidLeak: return Color.agPrimary10
        case .drivesDifferent: return Color.agWarning10
        case .wontStart: return Color.agDestructive10
        }
    }

    var isComingSoon: Bool {
        switch category {
        case .warningLight, .strangeNoise: return false
        default: return true
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(iconBg)
                        .frame(width: 40, height: 40)
                    Image(systemName: category.iconName)
                        .font(.system(size: 18))
                        .foregroundStyle(Color.agForeground)
                }
                .padding(.bottom, 12)

                Text(category.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.agForeground)

                Text(category.description)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.agMutedForeground)
                    .padding(.top, 2)
                    .lineLimit(2)

                if isComingSoon {
                    Text("Coming soon")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.agMutedForeground)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 2)
                        .background(Color.agMuted)
                        .clipShape(Capsule())
                        .padding(.top, 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.agCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.agBorder, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ComingSoonView: View {
    let title: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 48))
                .foregroundStyle(Color.agMutedForeground)
            Text("\(title) diagnosis coming soon")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.agForeground)
            Text("We're working on adding this diagnostic tool.")
                .font(.system(size: 14))
                .foregroundStyle(Color.agMutedForeground)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .appBackground()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

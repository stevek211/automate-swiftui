import SwiftUI

struct DiagnoseView: View {
    @Environment(AppState.self) private var appState
    @State private var searchText = ""
    @State private var selectedCategory: DiagnosticCategory?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Diagnose")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.agForeground)
                    Text("Don't worry, let's find the fix")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.agMutedForeground)
                }

                // Search bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.agMutedForeground)
                    TextField("Search warning lights, noises...", text: $searchText)
                        .font(.system(size: 16))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.agCard)
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(Color.agBorder, lineWidth: 1)
                )

                // Category grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(DiagnosticCategory.allCases) { category in
                        DiagnoseCategoryCard(category: category) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
        .background(Color.agBackground)
        .navigationDestination(item: $selectedCategory) { category in
            switch category {
            case .warningLight:
                WarningLightDecoderView()
            case .strangeNoise:
                NoiseDiagnosisView()
            default:
                ComingSoonView(title: category.rawValue)
            }
        }
    }
}

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
        .background(Color.agBackground)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        DiagnoseView()
    }
    .environment(AppState())
}

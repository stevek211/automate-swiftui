import SwiftUI

struct DiagnosticCategoryCard: View {
    let category: DiagnosticCategory
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AGSpacing.md) {
                Image(systemName: category.iconName)
                    .font(.system(size: 28))
                    .foregroundStyle(Color.agPrimary)
                    .frame(width: 56, height: 56)
                    .background(Color.agPrimary.opacity(0.1))
                    .clipShape(Circle())

                VStack(spacing: AGSpacing.xs) {
                    Text(category.rawValue)
                        .font(.jakartaCallout)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.agForeground)

                    Text(category.description)
                        .font(.jakartaCaption2)
                        .foregroundStyle(Color.agMutedForeground)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(AGSpacing.cardPadding)
            .background(Color.agCard)
            .clipShape(RoundedRectangle(cornerRadius: AGSpacing.cornerRadius))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
        ForEach(DiagnosticCategory.allCases) { category in
            DiagnosticCategoryCard(category: category) {}
        }
    }
    .padding()
    .background(Color.agBackground)
}

import SwiftUI

struct ArticleCard: View {
    let article: LearningArticle

    var difficultyColor: Color {
        switch article.difficulty {
        case .beginner: return .agSuccess
        case .intermediate: return .agWarning
        case .advanced: return .agDestructive
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AGSpacing.md) {
            Text(article.title)
                .font(.jakartaHeadline)
                .foregroundStyle(Color.agForeground)

            Text(article.description)
                .font(.jakartaCallout)
                .foregroundStyle(Color.agMutedForeground)
                .lineLimit(2)

            HStack(spacing: AGSpacing.md) {
                // Difficulty badge
                Text(article.difficulty.rawValue)
                    .font(.jakartaCaption2)
                    .foregroundStyle(difficultyColor)
                    .padding(.horizontal, AGSpacing.sm)
                    .padding(.vertical, AGSpacing.xs)
                    .background(difficultyColor.opacity(0.1))
                    .clipShape(Capsule())

                // Read time
                Label("\(article.readTimeMinutes) min", systemImage: "clock")
                    .font(.jakartaCaption)
                    .foregroundStyle(Color.agMutedForeground)

                Spacer()

                // Category
                Text(article.category.rawValue)
                    .font(.jakartaCaption2)
                    .foregroundStyle(Color.agMutedForeground)
            }
        }
        .padding(AGSpacing.cardPadding)
        .background(Color.agCard)
        .clipShape(RoundedRectangle(cornerRadius: AGSpacing.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    VStack {
        ArticleCard(article: DemoData.articles[0])
        ArticleCard(article: DemoData.articles[7])
    }
    .padding()
    .background(Color.agBackground)
}

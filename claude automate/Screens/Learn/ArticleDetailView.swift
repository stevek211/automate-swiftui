import SwiftUI

struct ArticleDetailView: View {
    let article: LearningArticle

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AGSpacing.xl) {
                // Meta
                HStack(spacing: AGSpacing.md) {
                    Text(article.difficulty.rawValue)
                        .font(.quicksandScaled(.regular, size: 11))
                        .foregroundStyle(difficultyColor)
                        .padding(.horizontal, AGSpacing.sm)
                        .padding(.vertical, AGSpacing.xs)
                        .background(difficultyColor.opacity(0.1))
                        .clipShape(Capsule())

                    Label("\(article.readTimeMinutes) min read", systemImage: "clock")
                        .font(.quicksandScaled(.medium, size: 12))
                        .foregroundStyle(Color.agMutedForeground)

                    Spacer()

                    Text(article.category.rawValue)
                        .font(.quicksandScaled(.medium, size: 12))
                        .foregroundStyle(Color.agMutedForeground)
                }

                // Title & description
                Text(article.title)
                    .font(.quicksandScaled(.bold, size: 22))
                    .foregroundStyle(Color.agForeground)

                Text(article.description)
                    .font(.quicksandScaled(.regular, size: 15))
                    .foregroundStyle(Color.agMutedForeground)

                Divider()

                // Sections
                ForEach(article.sections, id: \.heading) { section in
                    VStack(alignment: .leading, spacing: AGSpacing.sm) {
                        Text(section.heading)
                            .font(.quicksandScaled(.semibold, size: 18))
                            .foregroundStyle(Color.agForeground)

                        Text(section.body)
                            .font(.quicksandScaled(.regular, size: 15))
                            .foregroundStyle(Color.agMutedForeground)
                            .lineSpacing(4)
                    }
                }

                // Related systems
                if !article.relatedSystemNames.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: AGSpacing.md) {
                        Text("Related Systems")
                            .font(.quicksandScaled(.semibold, size: 16))

                        FlowLayout(spacing: AGSpacing.sm) {
                            ForEach(article.relatedSystemNames, id: \.self) { name in
                                Text(name)
                                    .font(.quicksandScaled(.medium, size: 12))
                                    .foregroundStyle(Color.agPrimary)
                                    .padding(.horizontal, AGSpacing.md)
                                    .padding(.vertical, AGSpacing.sm)
                                    .background(Color.agPrimary.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .padding(AGSpacing.screenPadding)
        }
        .appBackground()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .standardBackButton()
    }

    var difficultyColor: Color {
        switch article.difficulty {
        case .beginner: return .agSuccess
        case .intermediate: return .agWarning
        case .advanced: return .agDestructive
        }
    }
}

#Preview {
    NavigationStack {
        ArticleDetailView(article: DemoData.articles[0])
    }
}

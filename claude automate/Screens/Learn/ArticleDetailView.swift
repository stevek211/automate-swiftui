import SwiftUI

struct ArticleDetailView: View {
    let article: LearningArticle

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AGSpacing.xl) {
                // Meta
                HStack(spacing: AGSpacing.md) {
                    Text(article.difficulty.rawValue)
                        .font(.jakartaCaption2)
                        .foregroundStyle(difficultyColor)
                        .padding(.horizontal, AGSpacing.sm)
                        .padding(.vertical, AGSpacing.xs)
                        .background(difficultyColor.opacity(0.1))
                        .clipShape(Capsule())

                    Label("\(article.readTimeMinutes) min read", systemImage: "clock")
                        .font(.jakartaCaption)
                        .foregroundStyle(Color.agMutedForeground)

                    Spacer()

                    Text(article.category.rawValue)
                        .font(.jakartaCaption)
                        .foregroundStyle(Color.agMutedForeground)
                }

                // Title & description
                Text(article.title)
                    .font(.jakartaTitle)
                    .foregroundStyle(Color.agForeground)

                Text(article.description)
                    .font(.jakartaBody)
                    .foregroundStyle(Color.agMutedForeground)

                Divider()

                // Sections
                ForEach(article.sections, id: \.heading) { section in
                    VStack(alignment: .leading, spacing: AGSpacing.sm) {
                        Text(section.heading)
                            .font(.jakartaTitle3)
                            .foregroundStyle(Color.agForeground)

                        Text(section.body)
                            .font(.jakartaBody)
                            .foregroundStyle(Color.agMutedForeground)
                            .lineSpacing(4)
                    }
                }

                // Related systems
                if !article.relatedSystemNames.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: AGSpacing.md) {
                        Text("Related Systems")
                            .font(.jakartaHeadline)

                        FlowLayout(spacing: AGSpacing.sm) {
                            ForEach(article.relatedSystemNames, id: \.self) { name in
                                Text(name)
                                    .font(.jakartaCaption)
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
        .background(Color.agBackground)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
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

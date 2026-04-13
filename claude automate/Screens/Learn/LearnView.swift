import SwiftUI

struct LearnView: View {
    @Environment(AppState.self) private var appState
    @State private var searchText = ""

    var filteredSystems: [CarSystem] {
        if searchText.isEmpty { return appState.carSystems }
        return appState.carSystems.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var filteredArticles: [LearningArticle] {
        if searchText.isEmpty { return appState.articles }
        return appState.articles.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Learn")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.agForeground)
                    Text("Understand your car, inside and out")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.agMutedForeground)
                }

                // Search bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.agMutedForeground)
                    TextField("Search systems & articles", text: $searchText)
                        .font(.system(size: 16))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.agCard)
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(Color.agBorder, lineWidth: 1)
                )

                // Car Systems Grid (3 col)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(filteredSystems) { system in
                        NavigationLink(value: system) {
                            VStack(spacing: 6) {
                                Image(systemName: system.iconName)
                                    .font(.system(size: 24))
                                    .foregroundStyle(Color.agPrimary)
                                    .frame(height: 28)

                                Text(system.name)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color.agForeground)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(12)
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

                // Articles
                if !filteredArticles.isEmpty {
                    Text("Articles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.agForeground)
                        .padding(.top, 4)

                    ForEach(filteredArticles) { article in
                        NavigationLink(value: article) {
                            LearnArticleRow(article: article)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
        .background(Color.agBackground)
        .navigationDestination(for: CarSystem.self) { system in
            SystemDetailView(system: system)
        }
        .navigationDestination(for: LearningArticle.self) { article in
            ArticleDetailView(article: article)
        }
    }
}

struct LearnArticleRow: View {
    let article: LearningArticle

    var difficultyColor: Color {
        switch article.difficulty {
        case .beginner: return .agSuccess
        case .intermediate: return .agWarning
        case .advanced: return .agDestructive
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(article.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.agForeground)
                .multilineTextAlignment(.leading)

            Text(article.description)
                .font(.system(size: 12))
                .foregroundStyle(Color.agMutedForeground)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            HStack(spacing: 8) {
                Text(article.difficulty.rawValue)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(difficultyColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 2)
                    .background(difficultyColor.opacity(0.1))
                    .clipShape(Capsule())

                Label("\(article.readTimeMinutes) min", systemImage: "clock")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.agMutedForeground)

                Spacer()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.agCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.agBorder, lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        LearnView()
    }
    .environment(AppState())
}

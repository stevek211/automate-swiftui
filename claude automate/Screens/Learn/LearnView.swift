import SwiftUI

struct LearnView: View {
    @Environment(AppState.self) private var appState
    @State private var searchText = ""
    @State private var selectedCategory: DiagnosticCategory?

    var filteredCategories: [DiagnosticCategory] {
        if searchText.isEmpty { return DiagnosticCategory.allCases }
        return DiagnosticCategory.allCases.filter {
            $0.rawValue.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }

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
                    Text("Learn & Diagnose")
                        .font(.quicksandScaled(.bold, size: 20))
                        .foregroundStyle(Color.agForeground)
                    Text("Find the fix and understand your car")
                        .font(.quicksandScaled(.regular, size: 14))
                        .foregroundStyle(Color.agMutedForeground)
                }

                // Search bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.agMutedForeground)
                    TextField("Search problems, systems & articles", text: $searchText)
                        .font(.quicksandScaled(.regular, size: 16))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.agCard)
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(Color.agBorder, lineWidth: 1)
                )

                // Diagnose (2 col)
                if !filteredCategories.isEmpty {
                    sectionHeader("Diagnose a problem")

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(filteredCategories) { category in
                            DiagnoseCategoryCard(category: category) {
                                selectedCategory = category
                            }
                        }
                    }
                }

                // Car Systems Grid (3 col)
                if !filteredSystems.isEmpty {
                    sectionHeader("Car systems")
                        .padding(.top, 4)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(filteredSystems) { system in
                        NavigationLink(value: system) {
                            VStack(spacing: 6) {
                                Image(systemName: system.iconName)
                                    .font(.system(size: 24))
                                    .foregroundStyle(Color.agPrimary)
                                    .frame(height: 28)

                                Text(system.name)
                                    .font(.quicksandScaled(.semibold, size: 11))
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
                    sectionHeader("Articles")
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
        .appBackground()
        .navigationDestination(for: CarSystem.self) { system in
            SystemDetailView(system: system)
        }
        .navigationDestination(for: LearningArticle.self) { article in
            ArticleDetailView(article: article)
        }
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

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.quicksandScaled(.semibold, size: 14))
            .foregroundStyle(Color.agForeground)
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
                .font(.quicksandScaled(.semibold, size: 14))
                .foregroundStyle(Color.agForeground)
                .multilineTextAlignment(.leading)

            Text(article.description)
                .font(.quicksandScaled(.regular, size: 12))
                .foregroundStyle(Color.agMutedForeground)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            HStack(spacing: 8) {
                Text(article.difficulty.rawValue)
                    .font(.quicksandScaled(.semibold, size: 10))
                    .foregroundStyle(difficultyColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 2)
                    .background(difficultyColor.opacity(0.1))
                    .clipShape(Capsule())

                Label("\(article.readTimeMinutes) min", systemImage: "clock")
                    .font(.quicksandScaled(.regular, size: 11))
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

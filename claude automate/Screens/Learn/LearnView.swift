import SwiftUI

// MARK: - Learn home (Figma 629:2288)
//
// One screen, two tabs picked at the top: "Learn" (the Figma home page) and
// "Diagnose" (the problem categories that used to sit inside Learn).

enum LearnTab: String, CaseIterable, Identifiable {
    case learn = "Learn"
    case diagnose = "Diagnose"
    var id: String { rawValue }
}

/// Where a Learn tile goes: a real guide when we have one, otherwise a placeholder.
enum LearnRoute: Hashable {
    case system(CarSystem)
    case article(LearningArticle)
    case comingSoon(String)
}

struct LearnView: View {
    @Environment(AppState.self) private var appState
    @State private var searchText = ""
    @State private var selectedCategory: DiagnosticCategory?
    @FocusState private var searchFocused: Bool

    private var tab: LearnTab { appState.learnTab }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                tabSwitcher

                switch tab {
                case .learn: learnContent
                case .diagnose: diagnoseContent
                }
            }
            .padding(.horizontal, 17)
            .padding(.top, 12)
            .padding(.bottom, 26)
        }
        .scrollDismissesKeyboard(.immediately)
        .appBackground()
        .navigationDestination(for: CarSystem.self) { system in
            SystemDetailView(system: system)
        }
        .navigationDestination(for: LearningArticle.self) { article in
            ArticleDetailView(article: article)
        }
        .navigationDestination(for: LearnRoute.self) { route in
            switch route {
            case .system(let system): SystemDetailView(system: system)
            case .article(let article): ArticleDetailView(article: article)
            case .comingSoon(let title): LearnComingSoonView(title: title)
            }
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

    // MARK: Tab switcher

    private var tabSwitcher: some View {
        HStack(spacing: 4) {
            ForEach(LearnTab.allCases) { item in
                let selected = tab == item
                Button {
                    searchFocused = false
                    withAnimation(.snappy(duration: 0.2)) { appState.learnTab = item }
                } label: {
                    Text(item.rawValue)
                        .font(.quicksandScaled(.semibold, size: 13))
                        .foregroundStyle(selected ? Color.agForeground : Color.agMutedForeground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .frame(minHeight: 36)
                        .background {
                            if selected {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.agCard)
                                    .shadow(color: .black.opacity(0.05), radius: 0.5, x: 0, y: 1)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Color.agMuted, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: Learn tab

    /// The Learn page for the car selected on Home (generic when there's none).
    private var page: LearnPage {
        let vehicle = appState.selectedVehicle
        return LearnPersonalizer.build(
            vehicle: vehicle,
            schedule: vehicle.flatMap { appState.oemSchedule(for: $0.id) },
            items: vehicle.map { appState.maintenanceItems(for: $0.id) } ?? []
        )
    }

    /// Short model name used in copy, e.g. "CR-V".
    private var carName: String? { page.vehicle?.model }

    private enum LearnSection: CaseIterable {
        case systems, routine, spendLess, deepDives
    }

    /// Sections with something to show, numbered in order (01, 02…).
    private var visibleSections: [(section: LearnSection, number: String)] {
        let page = page
        let visible = LearnSection.allCases.filter { section in
            switch section {
            case .systems: return !page.systems.isEmpty
            case .routine: return !page.routineCare.isEmpty
            case .spendLess: return !page.spendLess.isEmpty
            case .deepDives: return !page.deepDives.isEmpty
            }
        }
        return visible.enumerated().map { ($0.element, String(format: "%02d", $0.offset + 1)) }
    }

    @ViewBuilder
    private var learnContent: some View {
        learnHeader
        searchField

        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            if let hero = page.hero { heroCard(hero) }
            ForEach(visibleSections, id: \.number) { entry in
                switch entry.section {
                case .systems: systemsSection(entry.number)
                case .routine: routineCareSection(entry.number)
                case .spendLess: spendLessSection(entry.number)
                case .deepDives: deepDivesSection(entry.number)
                }
            }
        } else {
            searchResults
        }
    }

    /// "FOR YOUR 2019 HONDA CR-V ⌄" — switches the car Home and Learn both show.
    private var learnHeader: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let vehicle = page.vehicle {
                if appState.vehicles.count > 1 {
                    Menu {
                        ForEach(appState.vehicles) { car in
                            Button {
                                appState.selectedVehicleId = car.id
                            } label: {
                                if car.id == vehicle.id {
                                    Label(car.displayName, systemImage: "checkmark")
                                } else {
                                    Text(car.displayName)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            carEyebrow(vehicle)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color.agMutedForeground)
                        }
                        .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Showing \(vehicle.displayName). Change car")
                } else {
                    carEyebrow(vehicle)
                }
            } else {
                Text("CARS, EXPLAINED")
                    .font(.quicksandScaled(.semibold, size: 11))
                    .tracking(1.5)
                    .foregroundStyle(Color.agMutedForeground)
            }

            Text(page.vehicle.map { "Learn about\nyour \($0.model)!" } ?? "Learn about\nyour cars!")
                .font(.quicksandScaled(.bold, size: 28))
                .foregroundStyle(Color.agForeground)
                .lineSpacing(-2)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private func carEyebrow(_ vehicle: Vehicle) -> some View {
        Text("FOR YOUR \(vehicle.displayName.uppercased())")
            .font(.quicksandScaled(.semibold, size: 11))
            .tracking(1.5)
            .foregroundStyle(Color.agMutedForeground)
            .lineLimit(1)
    }

    private func pageHeader(eyebrow: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(eyebrow)
                .font(.quicksandScaled(.semibold, size: 11))
                .tracking(1.5)
                .foregroundStyle(Color.agMutedForeground)
            Text(title)
                .font(.quicksandScaled(.bold, size: 28))
                .foregroundStyle(Color.agForeground)
                .lineSpacing(-2)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image("learn-icon-search")
                .renderingMode(.template)
                .foregroundStyle(Color.agMutedForeground)
                .frame(width: 16, height: 16)
                .accessibilityHidden(true)
            TextField("What does a timing belt do?", text: $searchText)
                .font(.quicksandScaled(.regular, size: 15))
                .foregroundStyle(Color.agForeground)
                .focused($searchFocused)
                .submitLabel(.search)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.agMutedForeground)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.leading, 17)
        .padding(.trailing, 18)
        .padding(.vertical, 15)
        .background(Color.agCard, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.agBorder, lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
    }

    // "Start here" hero (Figma 638:3951) — the car's most urgent service when it has one.
    @ViewBuilder
    private func heroCard(_ hero: LearnHero) -> some View {
        NavigationLink(value: topicDestination(hero.card.topic)) {
            VStack(alignment: .leading, spacing: 5) {
                ZStack(alignment: .topLeading) {
                    if hero.usesOilArt {
                        GeometryReader { geo in
                            // Figma crops the art to 148.6% height, shifted up 24.3%.
                            Image("learn-hero-oil")
                                .resizable()
                                .frame(width: geo.size.width, height: geo.size.height * 1.486)
                                .offset(y: -geo.size.height * 0.243)
                        }
                        .frame(height: 134)
                        .clipped()
                        .accessibilityHidden(true)
                    } else {
                        LearnTopicIcon(topic: hero.card.topic, size: 56)
                            .frame(maxWidth: .infinity)
                            .frame(height: 134)
                            .background(hero.card.topic.tint.color, in: RoundedRectangle(cornerRadius: 17))
                            .accessibilityHidden(true)
                    }

                    Text(hero.eyebrow)
                        .font(.quicksandScaled(.regular, size: 14))
                        .foregroundStyle(Color.agMutedForeground)
                        .padding(.leading, hero.usesOilArt ? 6 : 12)
                        .padding(.top, 11)
                }

                Text(hero.title)
                    .font(.quicksandScaled(.semibold, size: 14))
                    .tracking(0.28)
                    .foregroundStyle(Color.agForeground.opacity(0.85))
                    .multilineTextAlignment(.leading)

                HStack(spacing: 6) {
                    Text("Read the guide")
                        .font(.quicksandScaled(.medium, size: 13))
                    Image("learn-icon-arrow")
                        .renderingMode(.template)
                        .frame(width: 10.3, height: 9)
                }
                .foregroundStyle(Color.agMutedForeground)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // How your car works
    private func systemsSection(_ number: String) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            LearnSectionHeader(
                number: number,
                title: "How your \(carName ?? "car") works",
                subtitle: "The big systems, simply",
                showsSeeAll: true, seeAll: .comingSoon("All systems")
            )

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8.6), count: 3), spacing: 8.6) {
                ForEach(page.systems) { card in
                    NavigationLink(value: topicDestination(card.topic)) {
                        VStack(spacing: 6) {
                            LearnTopicIcon(topic: card.topic, size: 30)
                                .accessibilityHidden(true)
                            Text(card.topic.title)
                                .font(.quicksandScaled(.medium, size: 12))
                                .foregroundStyle(Color.agForeground)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .padding(.horizontal, 6)
                        .background(Color.agMuted.opacity(0.5), in: RoundedRectangle(cornerRadius: 17))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
    }

    // Routine care
    private func routineCareSection(_ number: String) -> some View {
        VStack(alignment: .leading, spacing: 12.5) {
            LearnSectionHeader(
                number: number,
                title: "Routine care",
                subtitle: carName.map { "Small jobs that keep your \($0) healthy" } ?? "Small jobs that keep it healthy",
                showsSeeAll: true, seeAll: .comingSoon("All routine care")
            )

            VStack(spacing: 0) {
                ForEach(Array(page.routineCare.enumerated()), id: \.element.id) { index, card in
                    NavigationLink(value: topicDestination(card.topic)) {
                        HStack(spacing: 13) {
                            LearnTopicIcon(topic: card.topic, size: 21.6)
                                .frame(width: 39, height: 39)
                                .background(Color.agPrimary10, in: RoundedRectangle(cornerRadius: 13))
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 0) {
                                HStack(spacing: 6) {
                                    Text(card.topic.title)
                                        .font(.quicksandScaled(.semibold, size: 14))
                                        .foregroundStyle(Color.agForeground)
                                    if let status = card.status, card.isUrgent {
                                        LearnStatusTag(status: status)
                                    }
                                }
                                Text(card.subtitle)
                                    .font(.quicksandScaled(.regular, size: 12))
                                    .foregroundStyle(Color.agMutedForeground)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Text(card.cost)
                                .font(.quicksandScaled(.semibold, size: 12))
                                .foregroundStyle(Color.agMutedForeground)
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 13)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .overlay(alignment: .top) {
                        if index > 0 {
                            Rectangle().fill(Color.agBorder).frame(height: 0.7)
                        }
                    }
                }
            }
            .padding(1)
            .background(Color.agCard, in: RoundedRectangle(cornerRadius: 17))
            .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(Color.agBorder, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 17))
        }
    }

    // Spend less later — horizontal carousel that bleeds to the screen edges
    private func spendLessSection(_ number: String) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            LearnSectionHeader(
                number: number,
                title: "Spend less later",
                subtitle: page.isPersonalized
                    ? "Bigger services on your \(carName ?? "car")'s schedule"
                    : "Preventative services worth knowing"
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 10.8) {
                    ForEach(page.spendLess) { card in
                        NavigationLink(value: topicDestination(card.topic)) {
                            SpendLessCard(card: card)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 17)
            }
            .padding(.horizontal, -17)
        }
    }

    // Deep dives
    private func deepDivesSection(_ number: String) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            LearnSectionHeader(number: number, title: "Deep dives", subtitle: "Long reads for major work")

            VStack(spacing: 8.6) {
                ForEach(page.deepDives) { card in
                    NavigationLink(value: topicDestination(card.topic)) {
                        HStack(spacing: 13) {
                            VStack(alignment: .leading, spacing: 1.75) {
                                Text(card.topic.title)
                                    .font(.quicksandScaled(.semibold, size: 14))
                                    .foregroundStyle(Color.agForeground)
                                HStack(spacing: 4.3) {
                                    Image("learn-icon-clock")
                                        .renderingMode(.template)
                                        .frame(width: 10.8, height: 10.8)
                                        .accessibilityHidden(true)
                                    Text(card.subtitle)
                                        .font(.quicksandScaled(.regular, size: 12))
                                }
                                .foregroundStyle(Color.agMutedForeground)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Image("learn-icon-chevron")
                                .renderingMode(.template)
                                .foregroundStyle(Color.agForeground)
                                .frame(width: 16.2, height: 16.2)
                                .frame(width: 34.5, height: 34.5)
                                .background(Color.agCard, in: Circle())
                                .accessibilityHidden(true)
                        }
                        .padding(15)
                        .background(Color.agMuted.opacity(0.5), in: RoundedRectangle(cornerRadius: 17))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
    }

    // MARK: Search

    private var searchQuery: String { searchText.trimmingCharacters(in: .whitespaces) }

    private var matchingSystems: [CarSystem] {
        appState.carSystems.filter {
            $0.name.localizedCaseInsensitiveContains(searchQuery)
                || $0.description.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    private var matchingArticles: [LearningArticle] {
        appState.articles.filter {
            $0.title.localizedCaseInsensitiveContains(searchQuery)
                || $0.description.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    @ViewBuilder
    private var searchResults: some View {
        if matchingSystems.isEmpty && matchingArticles.isEmpty {
            VStack(spacing: 8) {
                Text("No guides for \u{201C}\(searchQuery)\u{201D} yet")
                    .font(.quicksandScaled(.semibold, size: 15))
                    .foregroundStyle(Color.agForeground)
                Text("Try a part name like brakes, battery or oil.")
                    .font(.quicksandScaled(.regular, size: 13))
                    .foregroundStyle(Color.agMutedForeground)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 24)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(matchingSystems) { system in
                    NavigationLink(value: system) {
                        HStack(spacing: 12) {
                            Image(systemName: system.iconName)
                                .foregroundStyle(Color.agPrimary)
                                .frame(width: 39, height: 39)
                                .background(Color.agPrimary10, in: RoundedRectangle(cornerRadius: 13))
                            VStack(alignment: .leading, spacing: 0) {
                                Text(system.name)
                                    .font(.quicksandScaled(.semibold, size: 14))
                                    .foregroundStyle(Color.agForeground)
                                Text(system.description)
                                    .font(.quicksandScaled(.regular, size: 12))
                                    .foregroundStyle(Color.agMutedForeground)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(13)
                        .background(Color.agCard, in: RoundedRectangle(cornerRadius: 17))
                        .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(Color.agBorder, lineWidth: 1))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                ForEach(matchingArticles) { article in
                    NavigationLink(value: article) {
                        LearnArticleRow(article: article)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
    }

    // MARK: Diagnose tab

    @ViewBuilder
    private var diagnoseContent: some View {
        pageHeader(eyebrow: "SOMETHING FEEL OFF?", title: "Diagnose\na problem")

        Text("Pick what you're noticing and we'll help you narrow down the cause.")
            .font(.quicksandScaled(.regular, size: 13))
            .foregroundStyle(Color.agMutedForeground)
            .padding(.top, -14)

        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(DiagnosticCategory.allCases) { category in
                DiagnoseCategoryCard(category: category) {
                    selectedCategory = category
                }
            }
        }
    }

    // MARK: Destinations

    /// Real guide when we have one, otherwise a placeholder.
    private func destination(articlePrefix: String, fallback: String) -> LearnRoute {
        if let article = appState.articles.first(where: { $0.title.lowercased().hasPrefix(articlePrefix) }) {
            return .article(article)
        }
        return .comingSoon(fallback)
    }

    private func systemDestination(_ name: String) -> LearnRoute {
        if let system = appState.carSystems.first(where: { $0.name == name }) {
            return .system(system)
        }
        return .comingSoon(name)
    }

    private func topicDestination(_ topic: LearnTopic) -> LearnRoute {
        if let name = topic.carSystemName {
            return systemDestination(name)
        }
        if let prefix = topic.articlePrefix {
            return destination(articlePrefix: prefix, fallback: topic.title)
        }
        return .comingSoon(topic.title)
    }
}

// MARK: - Section header ("01  How your car works" … "See all >")

private struct LearnSectionHeader: View {
    let number: String
    let title: String
    let subtitle: String
    var showsSeeAll = false
    var seeAll: LearnRoute = .comingSoon("All topics")

    var body: some View {
        HStack(alignment: .bottom) {
            HStack(alignment: .firstTextBaseline, spacing: 9) {
                Text(number)
                    .font(.quicksandScaled(.bold, size: 12))
                    .foregroundStyle(Color.agPrimary)
                    .frame(minWidth: 14, alignment: .leading)
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .font(.quicksandScaled(.bold, size: 16))
                        .foregroundStyle(Color.agForeground)
                        .accessibilityAddTraits(.isHeader)
                    Text(subtitle)
                        .font(.quicksandScaled(.regular, size: 12))
                        .foregroundStyle(Color.agMutedForeground)
                }
            }
            Spacer(minLength: 8)
            if showsSeeAll {
                NavigationLink(value: seeAll) {
                    HStack(spacing: 0) {
                        Text("See all")
                            .font(.quicksandScaled(.semibold, size: 12))
                        Image("learn-icon-chevron-small")
                            .renderingMode(.template)
                            .frame(width: 13, height: 13)
                    }
                    .foregroundStyle(Color.agPrimary)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 2)
            }
        }
        .padding(.bottom, 9)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.agBorder).frame(height: 0.7)
        }
    }
}

// MARK: - "Spend less later" card

private struct SpendLessCard: View {
    let card: LearnCard

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                LearnTopicIcon(topic: card.topic, size: 21.6)
                    .frame(width: 39, height: 39)
                    .background(card.topic.tint.color, in: RoundedRectangle(cornerRadius: 13))
                    .accessibilityHidden(true)
                Spacer(minLength: 4)
                if let status = card.status, card.isUrgent {
                    LearnStatusTag(status: status)
                }
            }
            .padding(.bottom, 8)

            Text(card.topic.title)
                .font(.quicksandScaled(.semibold, size: 14))
                .foregroundStyle(Color.agForeground)
                .lineSpacing(-1)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 9)

            Text(card.subtitle)
                .font(.quicksandScaled(.regular, size: 11))
                .foregroundStyle(Color.agMutedForeground)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 6)

            if let detail = card.detail {
                Text(detail)
                    .font(.quicksandScaled(.medium, size: 11))
                    .foregroundStyle(Color.agForeground.opacity(0.7))
                    .padding(.bottom, 2)
            }

            Text(card.cost)
                .font(.quicksandScaled(.semibold, size: 12))
                .foregroundStyle(Color.agPrimary)
        }
        .padding(14.7)
        .frame(width: 162, height: card.detail == nil ? 182 : 196, alignment: .topLeading)
        .background(Color.agCard, in: RoundedRectangle(cornerRadius: 17))
        .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(Color.agBorder, lineWidth: 1))
    }
}

// MARK: - Shared bits

/// A topic's Figma icon (or emoji / SF Symbol placeholder) at a given size.
private struct LearnTopicIcon: View {
    let topic: LearnTopic
    let size: CGFloat

    var body: some View {
        Group {
            if let emoji = topic.emoji {
                Text(emoji).font(.system(size: size * 0.8))
            } else if let symbol = topic.systemSymbol {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.75, weight: .medium))
                    .foregroundStyle(Color.agPrimary)
            } else {
                Image(topic.icon)
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(width: size, height: size)
    }
}

/// "Overdue" / "Due soon" pill.
private struct LearnStatusTag: View {
    let status: MaintenanceStatus

    var body: some View {
        Text(status.rawValue)
            .font(.quicksandScaled(.semibold, size: 11))
            .foregroundStyle(Color.statusColor(status))
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(Color.statusColor(status).opacity(0.12), in: Capsule())
            .lineLimit(1)
            .fixedSize()
    }
}

// MARK: - Placeholder for topics without a guide yet

struct LearnComingSoonView: View {
    let title: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.pages")
                .font(.system(size: 40))
                .foregroundStyle(Color.agMutedForeground)
            Text("\(title.replacingOccurrences(of: "\n", with: " ")) guide coming soon")
                .font(.quicksandScaled(.semibold, size: 17))
                .foregroundStyle(Color.agForeground)
                .multilineTextAlignment(.center)
            Text("We're writing this one now.")
                .font(.quicksandScaled(.regular, size: 14))
                .foregroundStyle(Color.agMutedForeground)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .appBackground()
        .navigationTitle(title.replacingOccurrences(of: "\n", with: " "))
        .navigationBarTitleDisplayMode(.inline)
        .standardBackButton()
    }
}

// MARK: - Article row (search results)

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
                    .font(.quicksandScaled(.semibold, size: 11))
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

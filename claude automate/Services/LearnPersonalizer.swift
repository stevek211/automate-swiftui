import Foundation

// MARK: - Learn page personalization
//
// Turns the topic catalog into the Learn page for one car, using only data the
// app already stores for it: the OEM schedule (`AppState.oemSchedules`) and its
// maintenance items (status + cost). No network calls.
//
// - Topics the car doesn't need are dropped (no timing belt on a chain engine,
//   no oil change on an EV).
// - Intervals come from the car's own schedule, costs from its maintenance items.
// - Overdue / due-soon topics float to the top and the most urgent one becomes
//   the "Start here" hero.
// With no schedule yet we fall back to the generic Figma page.

enum Powertrain {
    case combustion, hybrid, electric, unknown
}

/// One topic as it should appear for a specific car.
struct LearnCard: Identifiable, Hashable {
    let topic: LearnTopic
    var subtitle: String
    var cost: String
    /// Extra line on "Spend less later" cards, e.g. "Next at 105k mi".
    var detail: String? = nil
    var status: MaintenanceStatus? = nil
    /// Next scheduled mileage for this car, used for ordering.
    var nextDueMiles: Int? = nil

    var id: String { topic.id }

    var isUrgent: Bool { status == .overdue || status == .dueSoon }
}

struct LearnHero: Hashable {
    let eyebrow: String
    let title: String
    let card: LearnCard
    /// Only the oil change has the Figma illustration; other topics show their icon.
    var usesOilArt: Bool { card.topic.id == "oil" }
}

struct LearnPage {
    let vehicle: Vehicle?
    let powertrain: Powertrain
    /// True when the content was filtered against the car's schedule.
    let isPersonalized: Bool
    let hero: LearnHero?
    let systems: [LearnCard]
    let routineCare: [LearnCard]
    let spendLess: [LearnCard]
    let deepDives: [LearnCard]
}

enum LearnPersonalizer {

    static func build(
        vehicle: Vehicle?,
        schedule: [OEMScheduleItemInput]?,
        items: [MaintenanceItem]
    ) -> LearnPage {
        let schedule = (schedule?.isEmpty == false) ? schedule : nil
        let isPersonalized = vehicle != nil && schedule != nil
        let powertrain = isPersonalized
            ? inferPowertrain(vehicle: vehicle, schedule: schedule ?? [])
            : .unknown
        let mileage = vehicle?.mileage ?? 0
        let items = vehicle.map { v in items.filter { $0.vehicleId == v.id } } ?? []

        func include(_ topic: LearnTopic) -> Bool {
            guard isPersonalized, let schedule else { return topic.inGeneric }
            switch topic.applies {
            case .universal: return true
            case .combustion: return powertrain != .electric
            case .electric: return powertrain == .electric
            case .hybrid: return powertrain == .hybrid
            case .whenScheduled: return schedule.contains { topic.matches(name: $0.name, category: $0.category) }
            }
        }

        func card(_ topic: LearnTopic, showsInterval: Bool) -> LearnCard {
            var card = LearnCard(topic: topic, subtitle: topic.subtitle, cost: topic.cost)
            guard vehicle != nil, topic.hasMatcher else { return card }

            if let item = items.first(where: { topic.matches(name: $0.name, category: $0.category) }) {
                card.status = item.status
                if item.estimatedCostHigh > 0 { card.cost = item.estimatedCostDisplay }
            }

            if let entry = schedule?.first(where: { topic.matches(name: $0.name, category: $0.category) }) {
                card.nextDueMiles = entry.occurrences(around: mileage).next
                if showsInterval, let interval = intervalText(entry) {
                    card.subtitle = interval
                }
                if !showsInterval, !card.isUrgent, let next = card.nextDueMiles {
                    card.detail = "Next at \(shortMiles(next))"
                }
            }
            return card
        }

        let systems = LearnTopicCatalog.systems.filter(include)
            .map { card($0, showsInterval: false) }
        let routine = sortByUrgency(LearnTopicCatalog.routineCare.filter(include)
            .map { card($0, showsInterval: true) })
        let spendLess = sortByUrgency(LearnTopicCatalog.spendLess.filter(include)
            .map { card($0, showsInterval: false) })
        let deepDives = LearnTopicCatalog.deepDives.filter(include)
            .map { card($0, showsInterval: false) }

        return LearnPage(
            vehicle: vehicle,
            powertrain: powertrain,
            isPersonalized: isPersonalized,
            hero: hero(vehicle: vehicle, routine: routine, spendLess: spendLess),
            systems: systems,
            routineCare: routine,
            spendLess: spendLess,
            deepDives: deepDives
        )
    }

    // MARK: - Powertrain

    /// Best guess from the schedule: an engine shows up as oil changes or spark
    /// plugs; a hybrid as hybrid/inverter items (or "Hybrid" in the model name).
    static func inferPowertrain(vehicle: Vehicle?, schedule: [OEMScheduleItemInput]) -> Powertrain {
        let names = schedule.map { $0.name.lowercased() }
        let model = "\(vehicle?.model ?? "") \(vehicle?.trim ?? "")".lowercased()

        let hasEngine = schedule.contains { $0.category.lowercased() == "oil" || $0.category.lowercased() == "ignition" }
            || names.contains { $0.contains("engine oil") || $0.contains("oil change") || $0.contains("spark plug") }
        let hybridHint = model.contains("hybrid")
            || names.contains { $0.contains("hybrid") || $0.contains("inverter") }

        if !hasEngine { return .electric }
        return hybridHint ? .hybrid : .combustion
    }

    // MARK: - Ordering

    private static func sortByUrgency(_ cards: [LearnCard]) -> [LearnCard] {
        cards.enumerated().sorted { a, b in
            let ra = urgencyRank(a.element.status), rb = urgencyRank(b.element.status)
            if ra != rb { return ra < rb }
            let da = a.element.nextDueMiles ?? .max, db = b.element.nextDueMiles ?? .max
            if da != db { return da < db }
            return a.offset < b.offset
        }
        .map(\.element)
    }

    private static func urgencyRank(_ status: MaintenanceStatus?) -> Int {
        switch status {
        case .overdue: return 0
        case .dueSoon: return 1
        default: return 2
        }
    }

    // MARK: - Hero

    private static func hero(vehicle: Vehicle?, routine: [LearnCard], spendLess: [LearnCard]) -> LearnHero? {
        let urgent = sortByUrgency((routine + spendLess).filter(\.isUrgent))
        if let vehicle, let top = urgent.first {
            let name = top.topic.title.replacingOccurrences(of: "\n", with: " ")
            let state = top.status == .overdue ? "is overdue" : "is due soon"
            return LearnHero(
                eyebrow: "UP NEXT FOR YOUR \(vehicle.model.uppercased())",
                title: "\(name) \(state): here's what it does",
                card: top
            )
        }
        if let oil = routine.first(where: { $0.topic.id == "oil" }) {
            return LearnHero(eyebrow: "START HERE", title: "Oil Change: the one service most cars needs", card: oil)
        }
        if let first = routine.first {
            let name = first.topic.title.replacingOccurrences(of: "\n", with: " ")
            return LearnHero(eyebrow: "START HERE", title: "\(name): what it is and why it matters", card: first)
        }
        return nil
    }

    // MARK: - Formatting

    static func intervalText(_ entry: OEMScheduleItemInput) -> String? {
        switch entry.type {
        case .oneTime:
            guard let first = entry.resolvedFirstDueMiles else { return nil }
            return "Once, at \(shortMiles(first))"
        case .recurring, .recurringAfterFirst:
            guard let interval = entry.resolvedIntervalMiles else { return nil }
            let prefix = entry.usesTypicalInterval ? "About every" : "Every"
            if entry.type == .recurringAfterFirst,
               let first = entry.resolvedFirstDueMiles, first != interval {
                return "First at \(shortMiles(first)), then every \(shortMiles(interval))"
            }
            return "\(prefix) \(shortMiles(interval))"
        }
    }

    /// 7500 → "7,500 mi", 105000 → "105k mi".
    static func shortMiles(_ miles: Int) -> String {
        if miles >= 10_000, miles % 1_000 == 0 { return "\(miles / 1_000)k mi" }
        return "\(miles.formatted(.number)) mi"
    }
}

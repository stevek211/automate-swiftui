import SwiftUI

// MARK: - Learn topic catalog
//
// Every topic the Learn page can show, with generic copy from the Figma page
// (used when we know nothing about the car) plus the rules LearnPersonalizer
// uses to decide whether a topic applies to a given car and to find that car's
// schedule item / maintenance item for it.

struct LearnTopic: Identifiable, Hashable {
    enum Tint: Hashable {
        case brand, warningStrong, warning, danger, success

        var color: Color {
            switch self {
            case .brand: return .agPrimary10
            case .warningStrong: return .agWarning15
            case .warning: return .agWarning10
            case .danger: return .agDestructive10
            case .success: return .agSuccess.opacity(0.10)
            }
        }
    }

    /// Which cars a topic is shown for once we know the car's schedule.
    enum Applies: Hashable {
        /// Every car.
        case universal
        /// Cars with an engine (gas or hybrid).
        case combustion
        /// Battery-electric cars only.
        case electric
        /// Hybrids only.
        case hybrid
        /// Only when the car's schedule has a matching item (e.g. timing belt).
        case whenScheduled
    }

    let id: String
    let title: String
    /// Generic second line: interval for routine rows, blurb for cards, read time for deep dives.
    var subtitle: String = ""
    /// Generic cost range.
    var cost: String = ""
    var icon: String = ""
    var systemSymbol: String? = nil
    var emoji: String? = nil
    var tint: Tint = .brand
    /// Lowercased title prefix of a `LearningArticle` this links to, if one exists.
    var articlePrefix: String? = nil
    /// Name of a `CarSystem` this links to, if one exists.
    var carSystemName: String? = nil

    var applies: Applies = .universal
    /// Shown on the generic (not personalized) page — the original Figma set.
    var inGeneric: Bool = true
    /// Lowercased fragments that identify this topic in schedule / maintenance item names.
    var keywords: [String] = []
    /// Fragments that rule a name out (e.g. "cabin" for the engine air filter).
    var excludes: [String] = []
    /// Schedule categories that identify this topic on their own (e.g. "oil").
    var categories: [String] = []

    /// True when a schedule or maintenance item with this name/category is this topic.
    func matches(name: String, category: String) -> Bool {
        let n = name.lowercased()
        if excludes.contains(where: n.contains) { return false }
        if keywords.contains(where: n.contains) { return true }
        let c = category.lowercased()
            .replacingOccurrences(of: "ai-", with: "")
            .replacingOccurrences(of: "baseline-", with: "")
        return categories.contains(c)
    }

    var hasMatcher: Bool { !keywords.isEmpty || !categories.isEmpty }
}

enum LearnTopicCatalog {
    // MARK: 01 How your car works

    static let systems: [LearnTopic] = [
        LearnTopic(id: "sys-engine", title: "Engine", icon: "learn-sys-engine",
                   carSystemName: "Engine", applies: .combustion),
        LearnTopic(id: "sys-motor", title: "Electric Motor", systemSymbol: "bolt.car",
                   applies: .electric, inGeneric: false),
        LearnTopic(id: "sys-brakes", title: "Brakes", icon: "learn-sys-brakes", carSystemName: "Brakes"),
        LearnTopic(id: "sys-tires", title: "Tires & Wheels", icon: "learn-sys-tires", carSystemName: "Tires & Wheels"),
        LearnTopic(id: "sys-battery", title: "Battery", icon: "learn-sys-battery", carSystemName: "Battery"),
        LearnTopic(id: "sys-hybrid", title: "Hybrid System", systemSymbol: "leaf",
                   applies: .hybrid, inGeneric: false),
        LearnTopic(id: "sys-cooling", title: "Cooling System", icon: "learn-sys-cooling"),
        LearnTopic(id: "sys-suspension", title: "Suspension", icon: "learn-sys-suspension"),
    ]

    // MARK: 02 Routine care

    static let routineCare: [LearnTopic] = [
        LearnTopic(id: "oil", title: "Oil Change", subtitle: "Every 5k–7k mi", cost: "$85-100",
                   icon: "learn-care-oil", articlePrefix: "oil change", applies: .combustion,
                   keywords: ["oil change", "engine oil", "oil and filter", "oil & filter"],
                   excludes: ["transmission", "differential", "transfer", "fluid"],
                   categories: ["oil"]),
        LearnTopic(id: "tire-rotation", title: "Tire Rotation", subtitle: "Every 6 months", cost: "$0–50",
                   icon: "learn-care-tire", articlePrefix: "tires 101",
                   keywords: ["tire rotation", "rotate tire", "rotate the tire"]),
        LearnTopic(id: "air-filter", title: "Air Filter", subtitle: "Every 15k mi", cost: "$15–30",
                   icon: "learn-care-airfilter", applies: .combustion,
                   keywords: ["engine air", "air filter", "air cleaner"],
                   excludes: ["cabin", "pollen", "climate"]),
        LearnTopic(id: "brake-fluid", title: "Brake Fluid Flush", subtitle: "Every 2 years", cost: "$118–213",
                   icon: "learn-care-brakefluid", keywords: ["brake fluid"]),
        LearnTopic(id: "cabin-filter", title: "Cabin Air Filter", subtitle: "Every 15k mi", cost: "$15–40",
                   icon: "learn-care-cabin", keywords: ["cabin", "pollen", "climate control filter"]),
    ]

    // MARK: 03 Spend less later

    static let spendLess: [LearnTopic] = [
        LearnTopic(id: "battery", title: "Battery\nReplacement", subtitle: "Powers your electrical system",
                   cost: "$201–405", icon: "learn-save-battery", tint: .warningStrong,
                   keywords: ["12v battery", "12-volt battery", "battery"],
                   excludes: ["hybrid", "high-voltage", "high voltage", "traction"]),
        LearnTopic(id: "timing-belt", title: "Timing Belt\nReplacement",
                   subtitle: "The one service that can total your engine with no warning",
                   cost: "$935–2,278", icon: "learn-save-timingbelt", tint: .danger,
                   applies: .whenScheduled, keywords: ["timing belt"]),
        LearnTopic(id: "coolant", title: "Coolant Flush", subtitle: "Keeps your engine from overheating",
                   cost: "$100–200", icon: "learn-sys-cooling", tint: .brand,
                   applies: .whenScheduled, inGeneric: false,
                   keywords: ["coolant", "antifreeze"], excludes: ["inverter", "level"]),
        LearnTopic(id: "alignment", title: "Wheel Alignment", subtitle: "Keeps car driving straight",
                   cost: "$75–200", icon: "learn-save-alignment", tint: .success, keywords: ["alignment"]),
        LearnTopic(id: "transmission-fluid", title: "Transmission Fluid",
                   subtitle: "Skipping this kills transmissions", cost: "$150–300", emoji: "⚙️", tint: .warning,
                   applies: .whenScheduled,
                   keywords: ["transmission fluid", "transmission oil", "cvt fluid", "atf", "gearbox oil"],
                   categories: ["transmission"]),
        LearnTopic(id: "spark-plugs", title: "Spark Plugs", subtitle: "Ignites fuel in engine",
                   cost: "$80–200", icon: "learn-save-sparkplugs", tint: .danger,
                   applies: .combustion, keywords: ["spark plug"]),
    ]

    // MARK: 04 Deep dives

    static let deepDives: [LearnTopic] = [
        LearnTopic(id: "dd-brakes", title: "Brake Job Breakdown", subtitle: "10 min read · $150–800",
                   articlePrefix: "brake job breakdown"),
        LearnTopic(id: "dd-transmission", title: "Transmission Service", subtitle: "12 min read · $150–400",
                   applies: .whenScheduled,
                   keywords: ["transmission fluid", "transmission oil", "cvt fluid", "atf", "gearbox oil"],
                   categories: ["transmission"]),
        LearnTopic(id: "dd-tuneup", title: "Engine Tune-Up", subtitle: "8 min read · $200–800",
                   applies: .combustion),
    ]
}

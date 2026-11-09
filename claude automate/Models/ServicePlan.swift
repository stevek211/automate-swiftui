import Foundation

// MARK: - Service Plan Models
//
// Milestone-based representation of an OEM maintenance schedule used by the
// Service Plan timeline UI. Derived from a flat list of items with recurrence
// metadata (see ServicePlanBuilder).

enum ServiceAction: String, Codable {
    case replace
    case perform
    case inspect
    case rotate
    case clean
    case adjust
    case check

    /// Normalize an arbitrary OEM action string into one of our enum cases.
    /// Handles compound actions like "rotate and inspect" or "inspect and replace if necessary"
    /// by picking the most specific primary verb; unknown verbs fall back to `.perform`.
    static func normalize(_ raw: String) -> ServiceAction {
        let lower = raw.lowercased()
        // Exact or prefix matches first
        if lower.hasPrefix("replace")                       { return .replace }
        if lower.hasPrefix("inspect")                       { return .inspect }
        if lower.hasPrefix("rotate")                        { return .rotate }
        if lower.hasPrefix("clean")                         { return .clean }
        if lower.hasPrefix("adjust")                        { return .adjust }
        if lower.hasPrefix("check")                         { return .check }
        if lower.hasPrefix("perform")                       { return .perform }
        // Compound phrases — pick the dominant verb by presence
        if lower.contains("replace")                        { return .replace }
        if lower.contains("rotate")                         { return .rotate }
        if lower.contains("inspect")                        { return .inspect }
        if lower.contains("check")                          { return .check }
        if lower.contains("clean")                          { return .clean }
        if lower.contains("adjust")                         { return .adjust }
        if lower.hasPrefix("change") || lower.contains("change") { return .replace }
        if lower.hasPrefix("lubricate") || lower.contains("lubricate") { return .perform }
        if lower.hasPrefix("drain") || lower.contains("drain and fill") { return .replace }
        return .perform
    }

    var displayText: String {
        switch self {
        case .replace: return "REPLACE"
        case .perform: return "PERFORM"
        case .inspect: return "INSPECT"
        case .rotate:  return "ROTATE"
        case .clean:   return "CLEAN"
        case .adjust:  return "ADJUST"
        case .check:   return "CHECK"
        }
    }

    /// Used by the UI to group items on a milestone card into "Replacements"
    /// vs "Inspections & Service".
    var group: ServiceItemGroup {
        switch self {
        case .replace: return .replacements
        case .perform, .inspect, .rotate, .clean, .adjust, .check: return .inspections
        }
    }
}

enum ServiceItemGroup: String {
    case replacements = "REPLACEMENTS"
    case inspections  = "INSPECTIONS & SERVICE"
}

struct ServicePlanItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let action: ServiceAction
    let category: String // oil, tires, brakes, filters, etc. — drives icon choice
}

struct ServicePlanMilestone: Identifiable, Hashable {
    let id = UUID()
    let mileage: Int
    let months: Int?
    let items: [ServicePlanItem]

    var replacements: [ServicePlanItem] {
        items.filter { $0.action.group == .replacements }
    }

    var inspections: [ServicePlanItem] {
        items.filter { $0.action.group == .inspections }
    }

    var replaceCount: Int { replacements.count }
}

struct ServicePlan {
    let milestones: [ServicePlanMilestone]
    let currentMileage: Int

    /// Index of the first milestone strictly greater than `currentMileage`
    /// (i.e. "next"). Returns `milestones.count` if we're past everything.
    var nextMilestoneIndex: Int {
        milestones.firstIndex(where: { $0.mileage > currentMileage }) ?? milestones.count
    }

    var completedMilestones: ArraySlice<ServicePlanMilestone> {
        milestones.prefix(nextMilestoneIndex)
    }

    var upcomingMilestones: ArraySlice<ServicePlanMilestone> {
        milestones.suffix(from: nextMilestoneIndex)
    }

    /// Miles remaining until the next milestone (0 if none).
    var milesUntilNext: Int {
        guard let next = upcomingMilestones.first else { return 0 }
        return max(0, next.mileage - currentMileage)
    }
}

// MARK: - Builder input type
//
// A simplified representation of a single OEM maintenance item with recurrence
// metadata. Callers convert the private OEMMaintenanceItem from
// AIMaintenanceAnalyzer into this shape (or populate directly from any source).

/// A single citation for the OEM schedule (manufacturer PDF, dealer page,
/// specialist site, forum) — rendered as a clickable link in the Service Plan
/// footer so users can verify the schedule against its source.
struct OEMScheduleSource: Codable, Hashable, Identifiable {
    let type: String   // "official" | "dealer" | "specialist" | "forum"
    let name: String
    let url: String?

    var id: String { name + (url ?? "") }

    /// Parsed URL if the string is well-formed; nil otherwise.
    var linkURL: URL? {
        guard let url, let parsed = URL(string: url), parsed.scheme != nil else { return nil }
        return parsed
    }
}

struct OEMScheduleItemInput: Codable, Hashable {
    enum Recurrence: String, Codable {
        case recurring
        case oneTime = "one_time"
        case recurringAfterFirst = "recurring_after_first"
    }

    let name: String
    let action: ServiceAction
    let category: String
    let type: Recurrence
    let intervalMiles: Int?
    let firstDueMiles: Int?
    let subsequentIntervalMiles: Int?
    let severeOnly: Bool

    /// Convenience factory from the raw JSON-ish strings the Perplexity schema uses.
    static func make(
        name: String,
        action: String,
        category: String,
        type: String,
        intervalMiles: Int?,
        firstDueMiles: Int?,
        subsequentIntervalMiles: Int?,
        severeOnly: Bool = false
    ) -> OEMScheduleItemInput {
        OEMScheduleItemInput(
            name: name,
            action: ServiceAction.normalize(action),
            category: category,
            type: Recurrence(rawValue: type) ?? .recurring,
            intervalMiles: intervalMiles,
            firstDueMiles: firstDueMiles,
            subsequentIntervalMiles: subsequentIntervalMiles,
            severeOnly: severeOnly
        )
    }
}

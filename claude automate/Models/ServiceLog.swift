import Foundation

struct ServiceLog: Identifiable, Hashable, Codable {
    let id: UUID
    var vehicleId: UUID
    var name: String
    var date: Date
    var mileage: Int
    var cost: Double
    var shop: String?
    var notes: String?
    var category: ServiceCategory

    /// Shop name on the estimated records created from the add-car questions.
    static let baselineShop = "AutoGuard Baseline"

    /// An estimate from the add-car questions, not a service the user logged.
    /// Feeds the service plan, but isn't real spending.
    var isBaselineEstimate: Bool { shop == Self.baselineShop }
}

enum ServiceCategory: String, Codable, CaseIterable, Identifiable {
    case oil = "Oil"
    case brakes = "Brakes"
    case tires = "Tires"
    case battery = "Battery"
    case transmission = "Transmission"
    case filters = "Filters"
    case cooling = "Cooling"
    case electrical = "Electrical"
    case fluids = "Fluids"
    case general = "General"
    case inspection = "Inspection"
    case other = "Other"

    var id: String { rawValue }

    /// The category a service-plan item belongs to ("oil", "Tires"), matched
    /// case-insensitively; nil when the plan uses a name we don't have.
    static func fromPlanCategory(_ raw: String) -> ServiceCategory? {
        let lower = raw.lowercased()
        return allCases.first { $0.rawValue.lowercased() == lower }
    }

    /// Best guess from a service's name, e.g. "Oil & Filter Change" → .oil.
    static func inferred(from name: String) -> ServiceCategory {
        let text = name.lowercased()
        if text.contains("oil") { return .oil }
        if text.contains("brake") { return .brakes }
        if text.contains("tire") || text.contains("wheel") || text.contains("alignment") { return .tires }
        if text.contains("battery") { return .battery }
        if text.contains("transmission") || text.contains("cvt") { return .transmission }
        if text.contains("filter") { return .filters }
        if text.contains("coolant") || text.contains("ac service") { return .cooling }
        if text.contains("spark") || text.contains("wiper") { return .electrical }
        if text.contains("fluid") { return .fluids }
        if text.contains("inspect") { return .inspection }
        return .general
    }

    var iconName: String {
        switch self {
        case .oil: return "drop.fill"
        case .brakes: return "brake.signal"
        case .tires: return "tire"
        case .battery: return "battery.100percent"
        case .transmission: return "gearshape.2.fill"
        case .filters: return "air.purifier.fill"
        case .cooling: return "thermometer.snowflake"
        case .electrical: return "bolt.fill"
        case .fluids: return "drop.fill"
        case .general: return "wrench.and.screwdriver.fill"
        case .inspection: return "magnifyingglass"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

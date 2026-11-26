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

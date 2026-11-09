import Foundation

struct Vehicle: Identifiable, Hashable, Codable {
    let id: UUID
    var year: Int
    var make: String
    var model: String
    var trim: String?
    var mileage: Int
    var color: String
    var vin: String?
    var healthScore: Int
    var lastService: Date?
    var nextService: Date?
    var maintenanceCurrent: Int
    var maintenanceTotal: Int
    var usage: [String]
    var conditions: [String]
    var annualMileage: String?
    /// When `mileage` was last entered or updated. nil for vehicles saved
    /// before this was tracked (decodes as nil from older persisted data).
    var mileageUpdatedAt: Date? = nil

    var displayName: String {
        "\(year) \(make) \(model)"
    }

    var fullDisplayName: String {
        if let trim {
            return "\(year) \(make) \(model) \(trim)"
        }
        return displayName
    }
}

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
    /// One of `bodyStyleOptions`, from the VIN lookup or the picker. Picks the
    /// right body in the stock photo; nil when unknown.
    var bodyStyle: String? = nil

    /// Body styles offered in the picker. The first five change the stock photo;
    /// SUVs, trucks and vans come in one body per model.
    static let bodyStyleOptions = ["Sedan", "Coupe", "Convertible", "Hatchback", "Wagon", "SUV", "Truck", "Van"]

    /// Maps an NHTSA body class ("Sedan/Saloon", "Sport Utility Vehicle (SUV)/Multi-Purpose
    /// Vehicle (MPV)", ...) to one of `bodyStyleOptions`, or nil if none fits.
    static func bodyStyle(fromNHTSA bodyClass: String?) -> String? {
        guard let body = bodyClass?.lowercased(), !body.isEmpty else { return nil }
        if body.contains("convertible") || body.contains("cabriolet") || body.contains("roadster") { return "Convertible" }
        if body.contains("coupe") { return "Coupe" }
        if body.contains("wagon") { return "Wagon" }
        if body.contains("hatchback") || body.contains("liftback") { return "Hatchback" }
        if body.contains("sedan") || body.contains("saloon") { return "Sedan" }
        if body.contains("sport utility") || body.contains("suv") || body.contains("crossover") { return "SUV" }
        if body.contains("pickup") || body.contains("truck") { return "Truck" }
        if body.contains("van") || body.contains("minivan") { return "Van" }
        return nil
    }

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

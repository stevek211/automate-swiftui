import Foundation

struct MaintenanceItem: Identifiable, Hashable, Codable {
    let id: UUID
    var vehicleId: UUID
    var name: String
    var status: MaintenanceStatus
    var dueDate: Date?
    var dueMileage: Int?
    var description: String
    var estimatedCostLow: Double
    var estimatedCostHigh: Double
    var category: String
    var diyDifficulty: Int // 1-5

    var estimatedCostDisplay: String {
        "$\(Int(estimatedCostLow))–$\(Int(estimatedCostHigh))"
    }
}

enum MaintenanceStatus: String, Codable, CaseIterable, Identifiable {
    case overdue = "Overdue"
    case dueSoon = "Due Soon"
    case onTrack = "On Track"
    case completed = "Completed"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .overdue: return "exclamationmark.circle.fill"
        case .dueSoon: return "clock.fill"
        case .onTrack: return "checkmark.circle.fill"
        case .completed: return "checkmark.seal.fill"
        }
    }
}

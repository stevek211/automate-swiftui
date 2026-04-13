import Foundation

struct CarSystem: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var category: SystemCategory
    var description: String
    var iconName: String
    var overview: String
    var components: [SystemComponent]
    var howItWorks: [String]
    var commonIssues: [CommonIssue]
    var serviceSchedule: [String]
}

enum SystemCategory: String, Codable, CaseIterable, Identifiable {
    case basics = "Basics"
    case issues = "Issues"
    case care = "Care"
    case service = "Service"

    var id: String { rawValue }
}

struct SystemComponent: Hashable, Codable {
    var name: String
    var description: String
}

struct CommonIssue: Hashable, Codable, Identifiable {
    var id: String { name }
    var name: String
    var symptoms: [String]
    var causes: [String]
    var estimatedCost: String
}

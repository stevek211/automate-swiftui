import Foundation

struct SeasonalAlert: Identifiable, Hashable {
    let id = UUID()
    var season: Season
    var title: String
    var message: String
    var checklist: [String]
}

enum Season: String, CaseIterable {
    case winter = "Winter"
    case spring = "Spring"
    case summer = "Summer"
    case fall = "Fall"

    var iconName: String {
        switch self {
        case .winter: return "snowflake"
        case .spring: return "leaf.fill"
        case .summer: return "sun.max.fill"
        case .fall: return "wind"
        }
    }

    static var current: Season {
        let month = Calendar.current.component(.month, from: .now)
        switch month {
        case 3...5: return .spring
        case 6...8: return .summer
        case 9...11: return .fall
        default: return .winter
        }
    }
}

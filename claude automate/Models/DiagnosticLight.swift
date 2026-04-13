import Foundation

struct DiagnosticLight: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var iconName: String
    var severity: Severity
    var category: LightCategory
    var description: String
    var action: String
    var estimatedCost: String
    var causes: [String]
}

enum Severity: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"

    var id: String { rawValue }
}

enum LightCategory: String, Codable, CaseIterable, Identifiable {
    case warning = "Warning"
    case safety = "Safety"
    case lighting = "Lighting"
    case info = "Info"

    var id: String { rawValue }
}

struct NoiseDiagnosis: Identifiable, Hashable, Codable {
    let id: UUID
    var location: String
    var timing: String
    var sound: String
    var diagnosis: String
    var severity: Severity
    var estimatedCost: String
    var description: String
}

enum DiagnosticCategory: String, CaseIterable, Identifiable {
    case warningLight = "Warning Light"
    case strangeNoise = "Strange Noise"
    case unusualSmell = "Unusual Smell"
    case fluidLeak = "Fluid Leak"
    case drivesDifferent = "Drives Different"
    case wontStart = "Won't Start"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .warningLight: return "exclamationmark.triangle.fill"
        case .strangeNoise: return "ear.fill"
        case .unusualSmell: return "nose"
        case .fluidLeak: return "drop.triangle.fill"
        case .drivesDifferent: return "car.side.fill"
        case .wontStart: return "key.fill"
        }
    }

    var description: String {
        switch self {
        case .warningLight: return "Decode dashboard lights"
        case .strangeNoise: return "Identify unusual sounds"
        case .unusualSmell: return "What's that smell?"
        case .fluidLeak: return "Spot and identify leaks"
        case .drivesDifferent: return "Handling & performance"
        case .wontStart: return "Troubleshoot starting issues"
        }
    }
}

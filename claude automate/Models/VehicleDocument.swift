import Foundation

/// A file (photo or PDF) the user attached to one of their cars.
/// The file itself lives on disk; see `VehicleDocumentFiles`.
struct VehicleDocument: Identifiable, Hashable, Codable {
    let id: UUID
    var vehicleId: UUID
    var title: String
    var category: DocumentCategory
    var kind: Kind
    /// File name inside the documents folder (e.g. "<id>.pdf").
    var fileName: String
    var addedAt: Date

    enum Kind: String, Codable {
        case image, pdf
    }
}

enum DocumentCategory: String, Codable, CaseIterable, Identifiable {
    case receipts = "Receipts"
    case insurance = "Insurance"
    case registration = "Registration"
    case other = "Other"

    var id: String { rawValue }

    /// Singular label for a single document ("Receipt", not "Receipts").
    var singular: String {
        switch self {
        case .receipts: return "Receipt"
        case .insurance: return "Insurance"
        case .registration: return "Registration"
        case .other: return "Document"
        }
    }

    var iconName: String {
        switch self {
        case .receipts: return "doc-icon-receipts"
        case .insurance: return "doc-icon-insurance"
        case .registration: return "doc-icon-registration"
        case .other: return "doc-icon-other"
        }
    }
}

/// Reads and writes the files behind `VehicleDocument`s.
/// Files go in Documents/vehicle_documents/<user or "guest">/.
enum VehicleDocumentFiles {
    static func folder(for userId: UUID?) -> URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("vehicle_documents", isDirectory: true)
            .appendingPathComponent(userId?.uuidString ?? "guest", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    static func url(for document: VehicleDocument, userId: UUID?) -> URL {
        folder(for: userId).appendingPathComponent(document.fileName)
    }

    /// Writes `data` for a new document and returns its file name.
    static func write(_ data: Data, id: UUID, kind: VehicleDocument.Kind, userId: UUID?) throws -> String {
        let name = "\(id.uuidString).\(kind == .pdf ? "pdf" : "jpg")"
        try data.write(to: folder(for: userId).appendingPathComponent(name), options: [.atomic, .completeFileProtection])
        return name
    }

    static func delete(_ document: VehicleDocument, userId: UUID?) {
        try? FileManager.default.removeItem(at: url(for: document, userId: userId))
    }
}

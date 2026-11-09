import Supabase
import Foundation

enum SupabaseManager {
    static let client = SupabaseClient(
        supabaseURL: URL(string: "https://nlugowdxamlfrfyfygjd.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5sdWdvd2R4YW1sZnJmeWZ5Z2pkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM2MzYyMjEsImV4cCI6MjA4OTIxMjIyMX0.payarzOJvXLApDMTc34h7rZmnThixvFsOshIKnFbPjo"
    )

    // MARK: - Vehicle Sync

    /// Upserts a vehicle row for the given user. Safe to call on add or update.
    static func upsertVehicle(_ vehicle: Vehicle, userId: UUID) async {
        let iso = ISO8601DateFormatter()
        var payload: [String: AnyEncodable] = [
            "id":                   AnyEncodable(vehicle.id.uuidString),
            "user_id":              AnyEncodable(userId.uuidString),
            "year":                 AnyEncodable(vehicle.year),
            "make":                 AnyEncodable(vehicle.make),
            "model":                AnyEncodable(vehicle.model),
            "mileage":              AnyEncodable(vehicle.mileage),
            "color":                AnyEncodable(vehicle.color),
            "health_score":         AnyEncodable(vehicle.healthScore),
            "usage":                AnyEncodable(vehicle.usage),
            "conditions":           AnyEncodable(vehicle.conditions),
            "maintenance_current":  AnyEncodable(vehicle.maintenanceCurrent),
            "maintenance_total":    AnyEncodable(vehicle.maintenanceTotal),
        ]
        // Optional fields — only include if non-nil
        if let trim = vehicle.trim             { payload["trim"]            = AnyEncodable(trim) }
        if let vin  = vehicle.vin              { payload["vin"]             = AnyEncodable(vin) }
        if let am   = vehicle.annualMileage    { payload["annual_mileage"]  = AnyEncodable(am) }
        if let ls   = vehicle.lastService      { payload["last_service"]    = AnyEncodable(iso.string(from: ls)) }
        if let ns   = vehicle.nextService      { payload["next_service"]    = AnyEncodable(iso.string(from: ns)) }

        try? await client.from("vehicles").upsert(payload).execute()
    }

    /// Soft-deletes a vehicle by setting deleted_at to now.
    static func softDeleteVehicle(id: UUID) async {
        let payload: [String: AnyEncodable] = [
            "deleted_at": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
        ]
        try? await client
            .from("vehicles")
            .update(payload)
            .eq("id", value: id.uuidString)
            .execute()
    }
}

// Wrapper to make heterogeneous dictionaries encodable for Supabase
struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void
    init<T: Encodable>(_ value: T) { self.encode = { try value.encode(to: $0) } }
    func encode(to encoder: Encoder) throws { try encode(encoder) }
}

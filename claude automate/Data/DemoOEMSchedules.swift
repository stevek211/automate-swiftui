import Foundation

// Simplified OEM schedules for the demo cars, so demo mode shows a personalized
// Learn page. Both cars have timing chains (no belt), and the Camry is a hybrid
// with a sealed eCVT (no transmission fluid service).

extension DemoData {
    static let oemSchedules: [UUID: [OEMScheduleItemInput]] = [
        vehicleHondaId: hondaCRV2019,
        vehicleToyotaId: toyotaCamryHybrid2021,
    ]

    private static func item(
        _ name: String, _ action: String, _ category: String,
        type: String = "recurring", every: Int? = nil, first: Int? = nil, then: Int? = nil
    ) -> OEMScheduleItemInput {
        .make(name: name, action: action, category: category, type: type,
              intervalMiles: every, firstDueMiles: first, subsequentIntervalMiles: then)
    }

    /// 2019 Honda CR-V 1.5T (Maintenance Minder; typical intervals).
    private static let hondaCRV2019: [OEMScheduleItemInput] = [
        item("Engine oil and filter", "replace", "oil", every: 7_500),
        item("Tire rotation", "rotate", "tires", every: 7_500),
        item("Engine air filter", "replace", "filters", every: 30_000),
        item("Cabin air filter", "replace", "filters", every: 15_000),
        item("Brake fluid", "replace", "fluids", every: 45_000),
        item("CVT fluid", "replace", "transmission", every: 25_000),
        item("Engine coolant", "replace", "cooling", type: "recurring_after_first", first: 120_000, then: 60_000),
        item("Spark plugs", "replace", "ignition", every: 100_000),
        item("Drive belt", "inspect", "belts", every: 30_000),
        item("Valve clearance", "adjust", "engine", every: 105_000),
    ]

    /// 2021 Toyota Camry Hybrid 2.5L.
    private static let toyotaCamryHybrid2021: [OEMScheduleItemInput] = [
        item("Engine oil and filter", "replace", "oil", every: 10_000),
        item("Tire rotation", "rotate", "tires", every: 5_000),
        item("Cabin air filter", "replace", "filters", every: 15_000),
        item("Engine air filter", "replace", "filters", every: 30_000),
        item("Brake fluid", "replace", "fluids", every: 30_000),
        item("Hybrid battery health check", "inspect", "electrical", every: 15_000),
        item("Engine coolant", "replace", "cooling", type: "recurring_after_first", first: 100_000, then: 50_000),
        item("Inverter coolant", "replace", "cooling", type: "one_time", first: 150_000),
        item("Spark plugs", "replace", "ignition", every: 120_000),
    ]
}

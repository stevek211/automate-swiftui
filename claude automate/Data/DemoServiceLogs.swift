import Foundation

extension DemoData {
    static let serviceLogs: [ServiceLog] = [
        ServiceLog(
            id: UUID(),
            vehicleId: vehicleHondaId,
            name: "Oil Change",
            date: date("2025-12-15"),
            mileage: 44500,
            cost: 62,
            shop: "QuickLube Express",
            category: .oil
        ),
        ServiceLog(
            id: UUID(),
            vehicleId: vehicleHondaId,
            name: "Tire Rotation",
            date: date("2025-12-15"),
            mileage: 44500,
            cost: 35,
            shop: "QuickLube Express",
            category: .tires
        ),
        ServiceLog(
            id: UUID(),
            vehicleId: vehicleHondaId,
            name: "Engine Air Filter",
            date: date("2025-09-20"),
            mileage: 41200,
            cost: 22,
            shop: "DIY",
            category: .filters
        ),
        ServiceLog(
            id: UUID(),
            vehicleId: vehicleHondaId,
            name: "Brake Pads (Front)",
            date: date("2025-06-10"),
            mileage: 38000,
            cost: 285,
            shop: "Honda Dealer",
            category: .brakes
        ),
        ServiceLog(
            id: UUID(),
            vehicleId: vehicleHondaId,
            name: "Oil Change",
            date: date("2025-06-10"),
            mileage: 38000,
            cost: 58,
            shop: "Honda Dealer",
            category: .oil
        ),
        ServiceLog(
            id: UUID(),
            vehicleId: vehicleHondaId,
            name: "Cabin Air Filter",
            date: date("2025-06-10"),
            mileage: 38000,
            cost: 45,
            shop: "Honda Dealer",
            category: .filters
        ),
        ServiceLog(
            id: UUID(),
            vehicleId: vehicleHondaId,
            name: "Wiper Blades",
            date: date("2025-06-10"),
            mileage: 38000,
            cost: 38,
            shop: "Honda Dealer",
            category: .general
        ),
        ServiceLog(
            id: UUID(),
            vehicleId: vehicleHondaId,
            name: "Multi-Point Inspection",
            date: date("2025-06-10"),
            mileage: 38000,
            cost: 0,
            shop: "Honda Dealer",
            category: .inspection
        ),
        ServiceLog(
            id: UUID(),
            vehicleId: vehicleHondaId,
            name: "Battery Replacement",
            date: date("2024-11-03"),
            mileage: 33500,
            cost: 165,
            shop: "AutoZone",
            category: .battery
        ),
    ]

    private static func date(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string) ?? .now
    }
}

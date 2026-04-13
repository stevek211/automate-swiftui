import Foundation

enum DemoData {
    static let vehicleHondaId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let vehicleToyotaId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

    static let vehicles: [Vehicle] = [
        Vehicle(
            id: vehicleHondaId,
            year: 2019,
            make: "Honda",
            model: "CR-V",
            trim: "EX-L",
            mileage: 47230,
            color: "Lunar Silver Metallic",
            vin: "2HKRW2H83KH123456",
            healthScore: 82,
            lastService: date("2025-12-15"),
            nextService: date("2026-03-20"),
            maintenanceCurrent: 5,
            maintenanceTotal: 6,
            usage: ["Daily commuter", "Family car"],
            conditions: ["City / stop-and-go", "Highway / long stretches"]
        ),
        Vehicle(
            id: vehicleToyotaId,
            year: 2021,
            make: "Toyota",
            model: "Camry Hybrid",
            trim: "LE",
            mileage: 31450,
            color: "Midnight Black",
            vin: "4T1G11AK5NU123456",
            healthScore: 94,
            lastService: date("2026-03-21"),
            nextService: date("2026-06-15"),
            maintenanceCurrent: 6,
            maintenanceTotal: 6,
            usage: ["Daily commuter"],
            conditions: ["Highway / long stretches"]
        ),
    ]

    private static func date(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string) ?? .now
    }
}

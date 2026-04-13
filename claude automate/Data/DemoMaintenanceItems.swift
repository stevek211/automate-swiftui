import Foundation

extension DemoData {
    static let maintenanceItems: [MaintenanceItem] = [
        // Honda CR-V
        MaintenanceItem(
            id: UUID(), vehicleId: vehicleHondaId,
            name: "Oil Change", status: .dueSoon,
            dueDate: dfmt("2026-03-20"), dueMileage: 48000,
            description: "Full synthetic oil change with filter replacement",
            estimatedCostLow: 45, estimatedCostHigh: 75,
            category: "Fluids", diyDifficulty: 2
        ),
        MaintenanceItem(
            id: UUID(), vehicleId: vehicleHondaId,
            name: "Tire Rotation", status: .dueSoon,
            dueDate: dfmt("2026-03-20"), dueMileage: 48000,
            description: "Rotate tires for even wear",
            estimatedCostLow: 25, estimatedCostHigh: 50,
            category: "Tires", diyDifficulty: 3
        ),
        MaintenanceItem(
            id: UUID(), vehicleId: vehicleHondaId,
            name: "Brake Pad Inspection", status: .onTrack,
            dueDate: dfmt("2026-06-01"), dueMileage: 50000,
            description: "Inspect front and rear brake pads for wear",
            estimatedCostLow: 0, estimatedCostHigh: 30,
            category: "Brakes", diyDifficulty: 1
        ),
        MaintenanceItem(
            id: UUID(), vehicleId: vehicleHondaId,
            name: "Cabin Air Filter", status: .overdue,
            dueDate: dfmt("2026-01-15"), dueMileage: 45000,
            description: "Replace cabin air filter for cleaner air",
            estimatedCostLow: 15, estimatedCostHigh: 30,
            category: "Filters", diyDifficulty: 1
        ),
        MaintenanceItem(
            id: UUID(), vehicleId: vehicleHondaId,
            name: "Coolant Flush", status: .onTrack,
            dueDate: dfmt("2026-09-01"), dueMileage: 55000,
            description: "Full coolant system flush and refill",
            estimatedCostLow: 100, estimatedCostHigh: 150,
            category: "Cooling", diyDifficulty: 3
        ),
        MaintenanceItem(
            id: UUID(), vehicleId: vehicleHondaId,
            name: "Transmission Fluid", status: .onTrack,
            dueDate: dfmt("2026-12-01"), dueMileage: 60000,
            description: "Inspect and top off transmission fluid",
            estimatedCostLow: 80, estimatedCostHigh: 120,
            category: "Fluids", diyDifficulty: 4
        ),
        // Toyota Camry Hybrid
        MaintenanceItem(
            id: UUID(), vehicleId: vehicleToyotaId,
            name: "Oil Change", status: .onTrack,
            dueDate: dfmt("2026-06-15"), dueMileage: 35000,
            description: "Full synthetic oil change",
            estimatedCostLow: 45, estimatedCostHigh: 75,
            category: "Fluids", diyDifficulty: 2
        ),
        MaintenanceItem(
            id: UUID(), vehicleId: vehicleToyotaId,
            name: "Tire Rotation", status: .onTrack,
            dueDate: dfmt("2026-06-15"), dueMileage: 35000,
            description: "Rotate tires for even wear",
            estimatedCostLow: 25, estimatedCostHigh: 50,
            category: "Tires", diyDifficulty: 3
        ),
        MaintenanceItem(
            id: UUID(), vehicleId: vehicleToyotaId,
            name: "Cabin Air Filter", status: .dueSoon,
            dueDate: dfmt("2026-04-01"), dueMileage: 32000,
            description: "Replace cabin air filter",
            estimatedCostLow: 15, estimatedCostHigh: 30,
            category: "Filters", diyDifficulty: 1
        ),
        MaintenanceItem(
            id: UUID(), vehicleId: vehicleToyotaId,
            name: "Hybrid Battery Check", status: .onTrack,
            dueDate: dfmt("2026-12-01"), dueMileage: 50000,
            description: "Inspect hybrid battery health and cooling system",
            estimatedCostLow: 0, estimatedCostHigh: 50,
            category: "Electrical", diyDifficulty: 1
        ),
    ]

    private static func dfmt(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string) ?? .now
    }
}

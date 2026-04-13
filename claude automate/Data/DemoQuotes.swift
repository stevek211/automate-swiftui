import Foundation

extension DemoData {
    struct RepairPriceData {
        var name: String
        var fairPriceLow: Double
        var fairPriceHigh: Double
        var upsellWarnings: [String]
    }

    static let repairPrices: [RepairPriceData] = [
        RepairPriceData(name: "Oil Change", fairPriceLow: 35, fairPriceHigh: 80,
            upsellWarnings: ["Engine flush ($100+) — usually unnecessary", "Premium oil filter upcharge — standard filters are fine", "Fuel system cleaning — rarely needed at oil change"]),
        RepairPriceData(name: "Brake Pads", fairPriceLow: 150, fairPriceHigh: 350,
            upsellWarnings: ["Full rotor replacement when resurfacing would work", "Brake fluid flush added on — may not be due", "Lifetime brake pad warranty — read the fine print"]),
        RepairPriceData(name: "Battery Replacement", fairPriceLow: 100, fairPriceHigh: 250,
            upsellWarnings: ["Terminal cleaning upcharge — should be included", "Battery warranty extension — often not worth it"]),
        RepairPriceData(name: "Tire Rotation", fairPriceLow: 0, fairPriceHigh: 50,
            upsellWarnings: ["Wheel alignment added on — only needed if car pulls", "Tire balancing — only needed if you feel vibration"]),
        RepairPriceData(name: "Alternator Replacement", fairPriceLow: 300, fairPriceHigh: 700,
            upsellWarnings: ["New serpentine belt — check if it's actually worn", "Battery replacement — test it first, may still be good"]),
        RepairPriceData(name: "Transmission Fluid Change", fairPriceLow: 150, fairPriceHigh: 350,
            upsellWarnings: ["Full transmission flush vs. drain-and-fill — flush can damage older transmissions", "Transmission additive — rarely necessary"]),
        RepairPriceData(name: "Coolant Flush", fairPriceLow: 100, fairPriceHigh: 200,
            upsellWarnings: ["Radiator additive/sealer — can cause clogs", "Thermostat replacement — only if actually failing"]),
        RepairPriceData(name: "Spark Plugs", fairPriceLow: 80, fairPriceHigh: 250,
            upsellWarnings: ["Ignition coil replacement — only if misfiring", "Fuel injector cleaning — separate service, not always needed"]),
        RepairPriceData(name: "Wheel Alignment", fairPriceLow: 75, fairPriceHigh: 200,
            upsellWarnings: ["Tie rod replacement — only if loose/worn", "New tires — check tread depth yourself first"]),
        RepairPriceData(name: "AC Recharge", fairPriceLow: 100, fairPriceHigh: 250,
            upsellWarnings: ["Compressor replacement — only if compressor is actually failing", "Dye test — reasonable if they suspect a leak", "Cabin air filter — check if recently replaced"]),
    ]

    static func validateQuote(repairName: String, price: Double) -> QuoteResult {
        let repair = repairPrices.first { $0.name.lowercased() == repairName.lowercased() }
            ?? repairPrices.first { repairName.lowercased().contains($0.name.lowercased()) }

        guard let repair else {
            return QuoteResult(
                id: UUID(),
                repairName: repairName,
                inputPrice: price,
                trustScore: 50,
                fairPriceLow: price * 0.7,
                fairPriceHigh: price * 1.3,
                assessment: .fair,
                upsellWarnings: ["We don't have enough data for this repair. Get a second opinion."]
            )
        }

        let midpoint = (repair.fairPriceLow + repair.fairPriceHigh) / 2
        let range = repair.fairPriceHigh - repair.fairPriceLow
        let deviation = abs(price - midpoint) / range

        let assessment: PriceAssessment
        let trustScore: Int

        if price < repair.fairPriceLow * 0.8 {
            assessment = .great
            trustScore = 95
        } else if price <= repair.fairPriceHigh {
            assessment = .fair
            trustScore = max(60, 90 - Int(deviation * 30))
        } else if price <= repair.fairPriceHigh * 1.3 {
            assessment = .suspicious
            trustScore = max(30, 55 - Int(deviation * 20))
        } else {
            assessment = .overpriced
            trustScore = max(10, 30 - Int(deviation * 15))
        }

        return QuoteResult(
            id: UUID(),
            repairName: repairName,
            inputPrice: price,
            trustScore: trustScore,
            fairPriceLow: repair.fairPriceLow,
            fairPriceHigh: repair.fairPriceHigh,
            assessment: assessment,
            upsellWarnings: repair.upsellWarnings
        )
    }
}

import Foundation

struct QuoteResult: Identifiable, Codable {
    let id: UUID
    var repairName: String
    var inputPrice: Double
    var trustScore: Int // 0-100
    var fairPriceLow: Double
    var fairPriceHigh: Double
    var assessment: PriceAssessment
    var upsellWarnings: [String]

    var fairPriceDisplay: String {
        "$\(Int(fairPriceLow))–$\(Int(fairPriceHigh))"
    }
}

enum PriceAssessment: String, Codable {
    case fair = "Fair Price"
    case suspicious = "Suspicious"
    case overpriced = "Overpriced"
    case great = "Great Deal"
}

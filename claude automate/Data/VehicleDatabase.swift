import Foundation

enum VehicleDatabase {
    static let makes: [String] = [
        "Acura", "Audi", "BMW", "Buick", "Cadillac", "Chevrolet", "Chrysler",
        "Dodge", "Ford", "GMC", "Honda", "Hyundai", "Infiniti", "Jeep", "Kia",
        "Lexus", "Lincoln", "Mazda", "Mercedes-Benz", "Mitsubishi", "Nissan",
        "Ram", "Subaru", "Tesla", "Toyota", "Volkswagen", "Volvo",
    ]

    static let models: [String: [String]] = [
        "Acura": ["ILX", "Integra", "MDX", "RDX", "TLX"],
        "Audi": ["A3", "A4", "A6", "Q3", "Q5", "Q7", "e-tron"],
        "BMW": ["2 Series", "3 Series", "5 Series", "X1", "X3", "X5", "iX"],
        "Buick": ["Enclave", "Encore", "Encore GX", "Envision"],
        "Cadillac": ["CT4", "CT5", "Escalade", "XT4", "XT5", "XT6"],
        "Chevrolet": ["Silverado", "Equinox", "Traverse", "Tahoe", "Malibu", "Camaro", "Colorado", "Blazer"],
        "Chrysler": ["300", "Pacifica", "Voyager"],
        "Dodge": ["Challenger", "Charger", "Durango", "Hornet"],
        "Ford": ["F-150", "Escape", "Explorer", "Bronco", "Maverick", "Mustang", "Edge", "Expedition"],
        "GMC": ["Sierra", "Terrain", "Acadia", "Yukon", "Canyon"],
        "Honda": ["Accord", "Civic", "CR-V", "HR-V", "Odyssey", "Passport", "Pilot", "Ridgeline"],
        "Hyundai": ["Elantra", "Sonata", "Tucson", "Santa Fe", "Kona", "Palisade"],
        "Infiniti": ["Q50", "Q60", "QX50", "QX55", "QX60", "QX80"],
        "Jeep": ["Cherokee", "Compass", "Gladiator", "Grand Cherokee", "Wagoneer", "Wrangler"],
        "Kia": ["Forte", "K5", "Seltos", "Sorento", "Sportage", "Telluride"],
        "Lexus": ["ES", "IS", "NX", "RX", "TX", "UX"],
        "Lincoln": ["Aviator", "Corsair", "Nautilus", "Navigator"],
        "Mazda": ["CX-30", "CX-5", "CX-50", "CX-90", "Mazda3"],
        "Mercedes-Benz": ["A-Class", "C-Class", "E-Class", "GLA", "GLC", "GLE", "S-Class"],
        "Mitsubishi": ["Eclipse Cross", "Mirage", "Outlander", "Outlander Sport"],
        "Nissan": ["Altima", "Frontier", "Kicks", "Pathfinder", "Rogue", "Sentra"],
        "Ram": ["1500", "2500", "3500", "ProMaster"],
        "Subaru": ["Ascent", "Crosstrek", "Forester", "Impreza", "Legacy", "Outback", "WRX"],
        "Tesla": ["Model 3", "Model S", "Model X", "Model Y", "Cybertruck"],
        "Toyota": ["Camry", "Corolla", "RAV4", "Highlander", "Tacoma", "Tundra", "4Runner", "Prius", "Sienna"],
        "Volkswagen": ["Atlas", "Golf", "ID.4", "Jetta", "Taos", "Tiguan"],
        "Volvo": ["S60", "S90", "XC40", "XC60", "XC90"],
    ]

    static let trims: [String: [String]] = [
        "Honda-Accord": ["LX", "EX", "EX-L", "Sport", "Touring", "Hybrid"],
        "Honda-Civic": ["LX", "EX", "EX-L", "Sport", "Touring", "Si", "Type R"],
        "Honda-CR-V": ["LX", "EX", "EX-L", "Touring", "Hybrid"],
        "Honda-HR-V": ["LX", "EX", "EX-L"],
        "Honda-Pilot": ["LX", "EX", "EX-L", "Touring", "Elite", "TrailSport"],
        "Toyota-Camry": ["LE", "SE", "XLE", "XSE", "TRD"],
        "Toyota-Corolla": ["L", "LE", "SE", "XLE", "XSE", "Hybrid"],
        "Toyota-RAV4": ["LE", "XLE", "XSE", "Adventure", "TRD Off-Road", "Prime"],
        "Toyota-Highlander": ["L", "LE", "XLE", "XSE", "Limited", "Platinum"],
        "Toyota-Tacoma": ["SR", "SR5", "TRD Sport", "TRD Off-Road", "Limited", "TRD Pro"],
        "Ford-F-150": ["XL", "XLT", "Lariat", "King Ranch", "Platinum", "Raptor"],
        "Ford-Escape": ["S", "SE", "SEL", "Titanium", "PHEV"],
        "Ford-Explorer": ["Base", "XLT", "Limited", "ST", "Platinum"],
        "Ford-Bronco": ["Base", "Big Bend", "Black Diamond", "Outer Banks", "Badlands", "Wildtrak", "Raptor"],
        "Ford-Mustang": ["EcoBoost", "GT", "Mach 1", "Shelby GT500"],
        "Chevrolet-Silverado": ["WT", "Custom", "LT", "RST", "LTZ", "High Country"],
        "Chevrolet-Equinox": ["LS", "LT", "RS", "Premier"],
        "Chevrolet-Tahoe": ["LS", "LT", "RST", "Z71", "Premier", "High Country"],
    ]

    static let defaultTrims = ["Base", "Standard", "Premium", "Limited"]

    static func trimsFor(make: String, model: String) -> [String] {
        trims["\(make)-\(model)"] ?? defaultTrims
    }

    // MARK: - Usage Options
    struct UsageOption: Identifiable {
        let id: String
        let emoji: String
        let label: String
        let subtitle: String
    }

    static let usageOptions: [UsageOption] = [
        UsageOption(id: "commuter", emoji: "car.fill", label: "Daily commuter", subtitle: "Drive it to work most days"),
        UsageOption(id: "family", emoji: "figure.2.and.child.holdinghands", label: "Family car", subtitle: "Hauling kids, groceries, life"),
        UsageOption(id: "weekend", emoji: "mountain.2.fill", label: "Weekend / road trips", subtitle: "Longer drives, highways"),
        UsageOption(id: "work", emoji: "wrench.and.screwdriver.fill", label: "Work vehicle", subtitle: "Used for business or trades"),
        UsageOption(id: "occasional", emoji: "parkingsign", label: "Occasional use", subtitle: "Don't drive it much"),
    ]

    // MARK: - Condition Options
    struct ConditionOption: Identifiable {
        let id: String
        let emoji: String
        let label: String
    }

    static let conditionOptions: [ConditionOption] = [
        ConditionOption(id: "city", emoji: "building.2.fill", label: "City / stop-and-go"),
        ConditionOption(id: "highway", emoji: "road.lanes", label: "Highway / long stretches"),
        ConditionOption(id: "rain", emoji: "cloud.rain.fill", label: "Rain / wet roads"),
        ConditionOption(id: "snow", emoji: "snowflake", label: "Snow / ice in winter"),
        ConditionOption(id: "heat", emoji: "thermometer.sun.fill", label: "Extreme heat"),
        ConditionOption(id: "dirt", emoji: "mountain.2.fill", label: "Dirt / gravel / rough roads"),
    ]

    // MARK: - Annual Mileage Options
    struct AnnualMileageOption: Identifiable {
        let id: String
        let label: String
        let subtitle: String
    }

    static let annualMileageOptions: [AnnualMileageOption] = [
        AnnualMileageOption(id: "under5k", label: "Under 5,000", subtitle: "Light use"),
        AnnualMileageOption(id: "5k-10k", label: "5,000–10,000", subtitle: "Average"),
        AnnualMileageOption(id: "10k-15k", label: "10,000–15,000", subtitle: "Regular commuter"),
        AnnualMileageOption(id: "15k-25k", label: "15,000–25,000", subtitle: "Heavy use"),
        AnnualMileageOption(id: "25k+", label: "25,000+", subtitle: "Road warrior"),
    ]

    // MARK: - Common Services
    static let commonServices: [String] = [
        "Oil Change",
        "Tire Rotation",
        "Brake Inspection",
        "Brake Pad Replacement",
        "Air Filter Replacement",
        "Transmission Fluid",
        "Coolant Flush",
        "Spark Plugs",
        "Battery Replacement",
        "Wheel Alignment",
        "AC Service",
        "Wiper Blades",
    ]

    static let commonColors = ["Black", "White", "Silver", "Gray", "Blue", "Red", "Green", "Brown", "Beige", "Other"]

    static let years = Array((1990...2026).reversed())
}

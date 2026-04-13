import Foundation

extension DemoData {
    static let seasonalAlerts: [Season: SeasonalAlert] = [
        .winter: SeasonalAlert(
            season: .winter,
            title: "Winter Prep",
            message: "Cold weather puts extra stress on your car. Stay ahead of common winter issues.",
            checklist: ["Battery load test", "Tire pressure check", "Antifreeze level", "Wiper blades condition", "Heater function test"]
        ),
        .spring: SeasonalAlert(
            season: .spring,
            title: "Spring Recovery",
            message: "Post-winter checkup time! Salt, cold, and moisture can take a toll.",
            checklist: ["Wash undercarriage (remove salt)", "Check tire wear and pressure", "Inspect wiper blades", "Test AC system", "Check for coolant leaks"]
        ),
        .summer: SeasonalAlert(
            season: .summer,
            title: "Summer Heat Watch",
            message: "High temperatures stress your cooling system, battery, and tires.",
            checklist: ["Coolant level check", "AC performance test", "Tire pressure (hot pavement)", "Battery condition test", "Brake fluid check"]
        ),
        .fall: SeasonalAlert(
            season: .fall,
            title: "Fall Prep",
            message: "Prepare for colder weather and shorter days ahead.",
            checklist: ["Inspect belts & hoses", "Test battery", "Check tire tread depth", "Replace wiper blades", "Test heater & defroster"]
        ),
    ]

    static var currentSeasonalAlert: SeasonalAlert? {
        seasonalAlerts[Season.current]
    }
}

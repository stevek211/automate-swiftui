import Foundation

extension DemoData {
    static let diagnosticLights: [DiagnosticLight] = [
        // Warning Lights
        DiagnosticLight(
            id: UUID(), name: "Check Engine", iconName: "engine.combustion.fill",
            severity: .medium, category: .warning,
            description: "Could be anything from a loose gas cap to a serious engine issue.",
            action: "Safe to drive short distances. Schedule service within a week.",
            estimatedCost: "$0–$500+",
            causes: ["Loose gas cap", "Oxygen sensor", "Catalytic converter", "Mass airflow sensor"]
        ),
        DiagnosticLight(
            id: UUID(), name: "Oil Pressure", iconName: "oilcan.fill",
            severity: .high, category: .warning,
            description: "Engine not getting enough oil. Serious and can cause major damage.",
            action: "Pull over safely as soon as possible. Do not continue driving.",
            estimatedCost: "$50–$2,500",
            causes: ["Low oil level", "Oil pump failure", "Oil leak", "Worn engine bearings"]
        ),
        DiagnosticLight(
            id: UUID(), name: "Battery / Charging", iconName: "battery.100percent",
            severity: .medium, category: .warning,
            description: "Charging system not working properly. Running on battery power only.",
            action: "Drive to nearest service station. Avoid electrical accessories.",
            estimatedCost: "$100–$300",
            causes: ["Weak battery", "Faulty alternator", "Corroded terminals", "Worn serpentine belt"]
        ),
        DiagnosticLight(
            id: UUID(), name: "Engine Temperature", iconName: "thermometer.high",
            severity: .high, category: .warning,
            description: "Engine overheating. Continuing to drive causes severe engine damage.",
            action: "Pull over immediately. Turn off AC and turn on heater to draw heat from engine.",
            estimatedCost: "$150–$1,500",
            causes: ["Low coolant", "Failed thermostat", "Water pump failure", "Radiator leak"]
        ),
        // Safety Lights
        DiagnosticLight(
            id: UUID(), name: "Brake Warning", iconName: "exclamationmark.brakesignal",
            severity: .high, category: .safety,
            description: "Brake system issue detected. Could indicate low fluid or worn pads.",
            action: "Drive slowly to nearest service station. Avoid highway speeds.",
            estimatedCost: "$100–$800",
            causes: ["Low brake fluid", "Worn brake pads", "ABS malfunction", "Brake line leak"]
        ),
        DiagnosticLight(
            id: UUID(), name: "ABS", iconName: "abs.brakesignal",
            severity: .medium, category: .safety,
            description: "Anti-lock braking system issue. Regular brakes still work.",
            action: "Safe to drive carefully. Schedule service soon.",
            estimatedCost: "$100–$600",
            causes: ["ABS sensor dirty/faulty", "ABS module issue", "Wiring problem", "Low brake fluid"]
        ),
        DiagnosticLight(
            id: UUID(), name: "Airbag / SRS", iconName: "figure.seated.side.airbag.on",
            severity: .high, category: .safety,
            description: "Airbag system malfunction. Airbags may not deploy in a crash.",
            action: "Schedule service as soon as possible.",
            estimatedCost: "$150–$600",
            causes: ["Seat belt sensor", "Clock spring failure", "Airbag module issue", "Wiring fault"]
        ),
        DiagnosticLight(
            id: UUID(), name: "Tire Pressure (TPMS)", iconName: "exclamationmark.tirepressure",
            severity: .low, category: .safety,
            description: "One or more tires have low pressure.",
            action: "Check and inflate tires to recommended PSI.",
            estimatedCost: "$0–$30",
            causes: ["Temperature change", "Slow puncture", "Valve stem leak"]
        ),
        DiagnosticLight(
            id: UUID(), name: "Seat Belt", iconName: "figure.seated.seatbelt",
            severity: .low, category: .safety,
            description: "Seat belt not fastened.",
            action: "Fasten seat belt.",
            estimatedCost: "$0",
            causes: ["Seat belt not buckled", "Sensor malfunction"]
        ),
        DiagnosticLight(
            id: UUID(), name: "Traction Control", iconName: "car.side.rear.and.collision.and.car.side.front",
            severity: .low, category: .safety,
            description: "Traction control is active or disabled.",
            action: "If light stays on, schedule service. Normal to flash in slippery conditions.",
            estimatedCost: "$0–$200",
            causes: ["Slippery road conditions", "Wheel speed sensor", "System disabled manually"]
        ),
        DiagnosticLight(
            id: UUID(), name: "Stability Control", iconName: "car.side.fill",
            severity: .medium, category: .safety,
            description: "Electronic stability control issue.",
            action: "Drive cautiously, especially in curves. Schedule service.",
            estimatedCost: "$100–$400",
            causes: ["Steering angle sensor", "Wheel speed sensor", "Control module issue"]
        ),
        // Lighting
        DiagnosticLight(
            id: UUID(), name: "Headlight Out", iconName: "headlight.low.beam.fill",
            severity: .low, category: .lighting,
            description: "A headlight bulb has burned out.",
            action: "Replace bulb as soon as possible for safety.",
            estimatedCost: "$15–$100",
            causes: ["Burned out bulb", "Fuse blown", "Wiring issue"]
        ),
        DiagnosticLight(
            id: UUID(), name: "High Beam Indicator", iconName: "headlight.high.beam.fill",
            severity: .low, category: .lighting,
            description: "High beams are currently on.",
            action: "Switch to low beams when other vehicles are present.",
            estimatedCost: "$0",
            causes: ["High beams activated"]
        ),
        DiagnosticLight(
            id: UUID(), name: "Turn Signal Issue", iconName: "arrow.left.arrow.right",
            severity: .low, category: .lighting,
            description: "A turn signal bulb may be out or flashing rapidly.",
            action: "Check and replace bulb.",
            estimatedCost: "$5–$30",
            causes: ["Burned out bulb", "Fuse issue", "Flasher relay"]
        ),
    ]

    static let noiseDiagnoses: [NoiseDiagnosis] = [
        NoiseDiagnosis(
            id: UUID(), location: "Front", timing: "Braking", sound: "Squealing",
            diagnosis: "Worn Brake Pads", severity: .medium,
            estimatedCost: "$150–$350",
            description: "Brake pad wear indicators are making contact with the rotors, signaling it's time for replacement."
        ),
        NoiseDiagnosis(
            id: UUID(), location: "Front", timing: "Braking", sound: "Grinding",
            diagnosis: "Severely Worn Brakes", severity: .high,
            estimatedCost: "$300–$800",
            description: "Metal-on-metal contact. Brake pads are completely worn and rotors are being damaged."
        ),
        NoiseDiagnosis(
            id: UUID(), location: "Front", timing: "Turning", sound: "Clicking",
            diagnosis: "CV Joint Issue", severity: .medium,
            estimatedCost: "$200–$400",
            description: "CV joint boot may be torn, causing the joint to lose lubrication and click during turns."
        ),
        NoiseDiagnosis(
            id: UUID(), location: "Under hood", timing: "At idle", sound: "Hissing",
            diagnosis: "Vacuum Leak", severity: .medium,
            estimatedCost: "$100–$300",
            description: "A vacuum hose may be cracked or disconnected, causing a hissing sound and potential performance issues."
        ),
        NoiseDiagnosis(
            id: UUID(), location: "Wheel", timing: "All the time", sound: "Rumbling",
            diagnosis: "Wheel Bearing Failure", severity: .high,
            estimatedCost: "$300–$600",
            description: "A worn wheel bearing creates a rumbling that increases with speed. Needs prompt replacement."
        ),
    ]

    static let noiseLocations = ["Front", "Rear", "Under hood", "Inside cabin", "Wheel"]
    static let noiseTimings = ["Braking", "Accelerating", "Turning", "At idle", "All the time", "High speed"]
    static let noiseSounds = ["Squealing", "Grinding", "Clicking", "Rumbling", "Rattling", "Hissing"]
}

import Foundation

extension DemoData {
    static let carSystems: [CarSystem] = [
        CarSystem(
            id: UUID(), name: "Engine", category: .basics,
            description: "The heart of your car — converts fuel into motion.",
            iconName: "engine.combustion.fill",
            overview: "Your engine is an internal combustion machine that converts fuel into mechanical energy through controlled explosions.",
            components: [
                SystemComponent(name: "Pistons", description: "Move up and down in cylinders to create power"),
                SystemComponent(name: "Spark Plugs", description: "Ignite the fuel-air mixture at precisely the right moment"),
                SystemComponent(name: "Camshaft", description: "Opens and closes valves in sync with pistons"),
                SystemComponent(name: "Oil Pump", description: "Circulates oil to keep everything lubricated"),
                SystemComponent(name: "Timing Belt/Chain", description: "Synchronizes the crankshaft and camshaft rotation"),
            ],
            howItWorks: [
                "Intake: Air and fuel are drawn into the cylinder",
                "Compression: The piston compresses the mixture",
                "Power: Spark plug ignites the mixture, forcing the piston down",
                "Exhaust: Burned gases are pushed out through the exhaust valve",
            ],
            commonIssues: [
                CommonIssue(name: "Check Engine Light", symptoms: ["Dashboard warning light", "Rough idle", "Reduced power"], causes: ["Loose gas cap", "O2 sensor", "Catalytic converter"], estimatedCost: "$0–$500+"),
                CommonIssue(name: "Misfiring", symptoms: ["Rough idle", "Hesitation on acceleration", "Poor fuel economy"], causes: ["Worn spark plugs", "Faulty ignition coil", "Fuel injector issue"], estimatedCost: "$80–$400"),
                CommonIssue(name: "Knocking/Pinging", symptoms: ["Metallic knocking sound", "Loss of power"], causes: ["Wrong fuel octane", "Carbon buildup", "Timing issue"], estimatedCost: "$50–$500"),
            ],
            serviceSchedule: ["Oil change every 5,000–7,500 miles", "Spark plugs every 30,000–100,000 miles", "Timing belt every 60,000–100,000 miles"]
        ),
        CarSystem(
            id: UUID(), name: "Brakes", category: .basics,
            description: "Your most important safety system — stops your car reliably.",
            iconName: "brake.signal",
            overview: "Brakes use hydraulic pressure to squeeze friction material against rotating discs or drums, converting motion into heat to slow your vehicle.",
            components: [
                SystemComponent(name: "Brake Pads", description: "Friction material that presses against rotors"),
                SystemComponent(name: "Rotors", description: "Metal discs that spin with the wheels"),
                SystemComponent(name: "Calipers", description: "Squeeze the pads against the rotors"),
                SystemComponent(name: "Brake Lines", description: "Carry hydraulic fluid from master cylinder to calipers"),
                SystemComponent(name: "Master Cylinder", description: "Converts pedal pressure into hydraulic force"),
            ],
            howItWorks: [
                "You press the brake pedal",
                "The master cylinder pressurizes brake fluid",
                "Fluid travels through lines to each caliper",
                "Calipers squeeze brake pads against the rotors, creating friction that slows the wheels",
            ],
            commonIssues: [
                CommonIssue(name: "Squealing", symptoms: ["High-pitched noise when braking"], causes: ["Worn brake pads", "Dust/debris", "Glazed pads"], estimatedCost: "$150–$300"),
                CommonIssue(name: "Spongy Pedal", symptoms: ["Brake pedal feels soft", "Pedal goes further than usual"], causes: ["Air in brake lines", "Low brake fluid", "Master cylinder issue"], estimatedCost: "$100–$500"),
                CommonIssue(name: "Grinding", symptoms: ["Metal-on-metal sound", "Vibration when braking"], causes: ["Completely worn pads", "Damaged rotors"], estimatedCost: "$300–$800"),
            ],
            serviceSchedule: ["Pad inspection every 12,000 miles", "Brake fluid flush every 30,000 miles or 2 years", "Rotor replacement every 50,000–70,000 miles"]
        ),
        CarSystem(
            id: UUID(), name: "Battery", category: .basics,
            description: "Powers your car's electrical system and starts the engine.",
            iconName: "battery.100percent",
            overview: "Your car battery stores electrical energy to start the engine and power accessories when the engine is off.",
            components: [
                SystemComponent(name: "Battery Cells", description: "Store and release electrical energy through chemical reactions"),
                SystemComponent(name: "Terminals", description: "Connect the battery to the car's electrical system"),
                SystemComponent(name: "Alternator", description: "Recharges the battery while the engine runs"),
                SystemComponent(name: "Starter Motor", description: "Uses battery power to crank the engine"),
            ],
            howItWorks: [
                "Chemical reactions in the battery produce electricity",
                "The starter motor uses this electricity to crank the engine",
                "Once running, the alternator recharges the battery",
                "The battery also powers accessories when the engine is off",
            ],
            commonIssues: [
                CommonIssue(name: "Slow Cranking", symptoms: ["Engine turns over slowly", "Dim lights when starting"], causes: ["Weak battery", "Corroded terminals", "Cold weather"], estimatedCost: "$100–$200"),
                CommonIssue(name: "Won't Start", symptoms: ["Clicking sound", "No response from ignition"], causes: ["Dead battery", "Failed starter", "Loose connection"], estimatedCost: "$100–$400"),
                CommonIssue(name: "Flickering Accessories", symptoms: ["Dimming headlights", "Radio cuts out"], causes: ["Failing alternator", "Loose belt", "Battery nearing end of life"], estimatedCost: "$150–$500"),
            ],
            serviceSchedule: ["Battery test every 12 months", "Terminal cleaning every 6–12 months", "Replacement every 3–5 years"]
        ),
        CarSystem(
            id: UUID(), name: "Tires & Wheels", category: .care,
            description: "Your only contact with the road — critical for safety and handling.",
            iconName: "tire",
            overview: "Tires provide grip, absorb road imperfections, and support the vehicle's weight. Proper maintenance extends their life significantly.",
            components: [
                SystemComponent(name: "Tire Tread", description: "Channels water and provides grip on the road surface"),
                SystemComponent(name: "Sidewall", description: "Flexible wall that absorbs impacts and contains air pressure info"),
                SystemComponent(name: "Valve Stem", description: "Allows inflation and deflation of the tire"),
                SystemComponent(name: "Wheel Rim", description: "Metal wheel that the tire mounts onto"),
            ],
            howItWorks: [
                "Air pressure inside the tire supports the vehicle's weight",
                "Tread patterns channel water and provide grip",
                "Rubber compound flexibility adapts to road surface",
                "Sidewalls flex to absorb bumps and maintain contact",
            ],
            commonIssues: [
                CommonIssue(name: "Uneven Wear", symptoms: ["Car pulls to one side", "Vibration at highway speed"], causes: ["Improper alignment", "Skipped rotations", "Incorrect pressure"], estimatedCost: "$75–$200"),
                CommonIssue(name: "Slow Leak", symptoms: ["Tire pressure drops over days", "TPMS warning light"], causes: ["Nail/screw puncture", "Valve stem leak", "Rim damage"], estimatedCost: "$0–$30"),
                CommonIssue(name: "Sidewall Bulge", symptoms: ["Visible bubble on tire side"], causes: ["Impact damage (pothole/curb)", "Manufacturing defect"], estimatedCost: "$100–$300 (tire replacement)"),
            ],
            serviceSchedule: ["Check pressure monthly", "Rotation every 5,000–7,500 miles", "Replacement every 40,000–60,000 miles"]
        ),
        CarSystem(
            id: UUID(), name: "Transmission", category: .service,
            description: "Transfers engine power to the wheels at the right speed.",
            iconName: "gearshape.2.fill",
            overview: "The transmission uses gears to match engine speed to wheel speed, allowing your car to accelerate smoothly and maintain speed efficiently.",
            components: [
                SystemComponent(name: "Gears", description: "Different-sized gears provide various speed ratios"),
                SystemComponent(name: "Torque Converter", description: "Transfers engine power to the transmission (automatic)"),
                SystemComponent(name: "Clutch", description: "Engages and disengages the engine from the transmission (manual)"),
                SystemComponent(name: "Transmission Fluid", description: "Lubricates and cools internal components"),
            ],
            howItWorks: [
                "Engine power enters through the torque converter or clutch",
                "Gears multiply torque for acceleration or reduce it for cruising",
                "The transmission controller selects the optimal gear",
                "Power exits to the driveshaft and wheels",
            ],
            commonIssues: [
                CommonIssue(name: "Slipping", symptoms: ["RPMs rise without acceleration", "Delayed response"], causes: ["Low fluid", "Worn clutch bands", "Solenoid issue"], estimatedCost: "$150–$1,500"),
                CommonIssue(name: "Delayed Engagement", symptoms: ["Pause before car moves when shifting to Drive"], causes: ["Low fluid", "Worn valve body", "Internal wear"], estimatedCost: "$200–$2,000"),
                CommonIssue(name: "Grinding Noise", symptoms: ["Grinding when shifting", "Difficulty getting into gear"], causes: ["Low fluid", "Worn synchronizers", "Clutch issue (manual)"], estimatedCost: "$100–$800"),
            ],
            serviceSchedule: ["Fluid change every 30,000–60,000 miles", "Inspection every 30,000 miles"]
        ),
        CarSystem(
            id: UUID(), name: "HVAC", category: .care,
            description: "Keeps you comfortable with heating, ventilation, and air conditioning.",
            iconName: "fan.fill",
            overview: "Your HVAC system controls cabin temperature and air quality using a combination of a compressor-based AC system and engine-heated coolant.",
            components: [
                SystemComponent(name: "Compressor", description: "Compresses refrigerant for the AC system"),
                SystemComponent(name: "Evaporator", description: "Cools air before it enters the cabin"),
                SystemComponent(name: "Heater Core", description: "Uses engine coolant to heat cabin air"),
                SystemComponent(name: "Cabin Air Filter", description: "Filters dust, pollen, and pollutants from incoming air"),
            ],
            howItWorks: [
                "AC: Compressor pressurizes refrigerant, which absorbs heat from cabin air",
                "Heat: Engine coolant flows through the heater core, warming air blown over it",
                "The blend door mixes hot and cool air to reach your set temperature",
                "The cabin air filter cleans all incoming air",
            ],
            commonIssues: [
                CommonIssue(name: "AC Blows Warm", symptoms: ["No cold air", "Warm air from vents"], causes: ["Low refrigerant", "Compressor failure", "Leak in system"], estimatedCost: "$100–$800"),
                CommonIssue(name: "Musty Smell", symptoms: ["Bad odor from vents", "Allergies when driving"], causes: ["Dirty cabin filter", "Mold on evaporator", "Clogged drain"], estimatedCost: "$15–$150"),
                CommonIssue(name: "Heat Doesn't Work", symptoms: ["Only cool air when heat is on"], causes: ["Low coolant", "Failed thermostat", "Heater core clog"], estimatedCost: "$50–$1,000"),
            ],
            serviceSchedule: ["Cabin air filter every 15,000–20,000 miles", "AC inspection every 24 months", "Refrigerant recharge as needed"]
        ),
        CarSystem(
            id: UUID(), name: "Fluids", category: .care,
            description: "The lifeblood of your car — multiple fluids keep systems running smoothly.",
            iconName: "drop.fill",
            overview: "Your car relies on several different fluids for lubrication, cooling, hydraulic power, and cleaning.",
            components: [
                SystemComponent(name: "Engine Oil", description: "Lubricates and cools the engine"),
                SystemComponent(name: "Coolant", description: "Regulates engine temperature"),
                SystemComponent(name: "Brake Fluid", description: "Transfers force in the braking system"),
                SystemComponent(name: "Transmission Fluid", description: "Lubricates transmission gears"),
                SystemComponent(name: "Power Steering Fluid", description: "Provides hydraulic assist for steering"),
            ],
            howItWorks: [
                "Each fluid serves a specific system in your vehicle",
                "Fluids degrade over time through heat, contamination, and chemical breakdown",
                "Regular replacement prevents costly damage to the systems they protect",
                "Most fluid levels can be checked at home with dipsticks or reservoir markings",
            ],
            commonIssues: [
                CommonIssue(name: "Puddles Under Car", symptoms: ["Colored spots on garage floor"], causes: ["Oil leak (brown/black)", "Coolant leak (green/orange)", "Trans fluid leak (red/pink)"], estimatedCost: "$50–$500"),
                CommonIssue(name: "Overheating", symptoms: ["Temperature gauge in red", "Steam from hood"], causes: ["Low coolant", "Leak in cooling system", "Failed water pump"], estimatedCost: "$100–$800"),
                CommonIssue(name: "Hard Steering", symptoms: ["Difficulty turning wheel", "Whining when turning"], causes: ["Low power steering fluid", "Pump failure", "Leak in system"], estimatedCost: "$50–$500"),
            ],
            serviceSchedule: ["Oil change every 5,000–7,500 miles", "Coolant flush every 30,000 miles or 3 years", "Brake fluid every 30,000 miles or 2 years", "Transmission fluid every 30,000–60,000 miles"]
        ),
        CarSystem(
            id: UUID(), name: "Electrical", category: .service,
            description: "Powers everything from headlights to engine management.",
            iconName: "bolt.fill",
            overview: "Modern cars are rolling computers with extensive electrical systems controlling everything from engine timing to entertainment.",
            components: [
                SystemComponent(name: "Alternator", description: "Generates electricity while the engine runs"),
                SystemComponent(name: "Fuses", description: "Protect circuits from overload"),
                SystemComponent(name: "Wiring Harness", description: "Carries electricity throughout the vehicle"),
                SystemComponent(name: "ECU", description: "The car's main computer controlling engine and emissions"),
            ],
            howItWorks: [
                "The battery provides initial power to start the engine",
                "The alternator generates electricity once the engine is running",
                "The ECU monitors sensors and adjusts engine parameters in real time",
                "Fuses and relays protect and control individual circuits",
            ],
            commonIssues: [
                CommonIssue(name: "Dimming Headlights", symptoms: ["Lights dim when idling", "Flickering at speed"], causes: ["Failing alternator", "Loose belt", "Poor ground connection"], estimatedCost: "$100–$500"),
                CommonIssue(name: "Blown Fuses", symptoms: ["Specific system stops working", "Repeated fuse failures"], causes: ["Short circuit", "Overloaded circuit", "Damaged wiring"], estimatedCost: "$1–$200"),
            ],
            serviceSchedule: ["Battery test every 12 months", "Alternator inspection every 30,000 miles", "Electrical system check every 24 months"]
        ),
    ]
}

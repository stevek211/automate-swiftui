import Foundation

extension DemoData {
    static let articles: [LearningArticle] = [
        LearningArticle(
            id: UUID(),
            title: "What does my engine oil actually do?",
            description: "Learn why oil is your engine's lifeblood and what happens when you skip changes.",
            readTimeMinutes: 2,
            difficulty: .beginner,
            category: .carBasics,
            sections: [
                ArticleSection(heading: "Lubrication", body: "Engine oil creates a thin film between moving metal parts, preventing them from grinding against each other. Without it, your engine would seize within minutes."),
                ArticleSection(heading: "Cooling", body: "Oil carries heat away from the combustion chamber and other hot spots, helping your cooling system keep the engine at the right temperature."),
                ArticleSection(heading: "Cleaning", body: "Modern oils contain detergents that pick up tiny metal particles, carbon deposits, and other contaminants, keeping your engine clean inside."),
                ArticleSection(heading: "Why Oil Breaks Down", body: "Over time, oil loses its viscosity and its additives get used up. Heat, contaminants, and chemical breakdown all reduce its effectiveness — which is why regular changes matter."),
            ],
            relatedSystemNames: ["Engine", "Fluids"]
        ),
        LearningArticle(
            id: UUID(),
            title: "How brakes work (in plain English)",
            description: "From pedal to rotor — understand the system that keeps you safe.",
            readTimeMinutes: 3,
            difficulty: .beginner,
            category: .carBasics,
            sections: [
                ArticleSection(heading: "The Basics", body: "When you press the brake pedal, hydraulic fluid pushes pistons in the calipers, which squeeze brake pads against the rotors (metal discs attached to your wheels). This friction slows you down."),
                ArticleSection(heading: "Brake Pads Are Sacrificial", body: "Pads are designed to wear down over time. They're much cheaper to replace than rotors or calipers, so they take the brunt of the friction."),
                ArticleSection(heading: "Warning Signs", body: "Squealing means wear indicators are touching the rotor — time for new pads ($150–$300 per axle). Grinding means you've gone too far and rotors may be damaged ($300–$600 per axle)."),
            ],
            relatedSystemNames: ["Brakes"]
        ),
        LearningArticle(
            id: UUID(),
            title: "Tires 101: Pressure, tread, and rotation",
            description: "Everything you need to know about your car's only contact with the road.",
            readTimeMinutes: 3,
            difficulty: .beginner,
            category: .carBasics,
            sections: [
                ArticleSection(heading: "Tire Pressure (PSI)", body: "Check your tire pressure monthly. The correct PSI is on a sticker inside the driver's door jamb, NOT on the tire itself. Under-inflation wastes fuel and causes uneven wear."),
                ArticleSection(heading: "The Penny Test", body: "Insert a penny head-first into the tread. If you can see all of Lincoln's head, your tread is too shallow (below 2/32\") and tires need replacing."),
                ArticleSection(heading: "Why Rotate?", body: "Front tires wear faster (especially on FWD cars). Rotating every 5,000–7,500 miles evens out wear and can double tire life — saving hundreds of dollars."),
            ],
            relatedSystemNames: ["Tires & Wheels"]
        ),
        LearningArticle(
            id: UUID(),
            title: "What's under my hood? A visual guide",
            description: "Identify the key components you can check yourself in 5 minutes.",
            readTimeMinutes: 3,
            difficulty: .beginner,
            category: .carBasics,
            sections: [
                ArticleSection(heading: "Oil Dipstick", body: "Usually has a yellow or orange handle. Pull it out, wipe it clean, reinsert, and pull again to check the oil level and color. Dark black oil needs changing."),
                ArticleSection(heading: "Coolant Reservoir", body: "A translucent plastic tank with min/max lines. Check when the engine is COOL. If it's frequently low, you may have a leak."),
                ArticleSection(heading: "Brake Fluid", body: "Usually near the back of the engine bay. Should be clear to light amber. Dark fluid means it needs flushing."),
                ArticleSection(heading: "Battery", body: "Look for white or green crusty buildup on the terminals — that's corrosion and it can cause starting problems. Clean with baking soda and water."),
            ],
            relatedSystemNames: ["Engine", "Fluids", "Battery"]
        ),
        LearningArticle(
            id: UUID(),
            title: "Spring recovery: Post-winter checkup",
            description: "5 things to check after winter to protect your car from salt and cold damage.",
            readTimeMinutes: 2,
            difficulty: .beginner,
            category: .seasonalPrep,
            sections: [
                ArticleSection(heading: "Wash the Undercarriage", body: "Road salt causes rust. Get an undercarriage wash at a car wash or use a pressure washer to blast off salt buildup."),
                ArticleSection(heading: "Check Tire Pressure", body: "Cold weather deflates tires. As temps rise, check and adjust to the recommended PSI."),
                ArticleSection(heading: "Inspect Wiper Blades", body: "Winter is hard on wipers. If they streak or chatter, replace them ($20–$40 for a pair)."),
                ArticleSection(heading: "Test the AC", body: "Turn it on before summer hits. If it blows warm, you may need a refrigerant recharge ($100–$200)."),
            ],
            relatedSystemNames: ["Tires & Wheels", "HVAC"]
        ),
        LearningArticle(
            id: UUID(),
            title: "Summer heat: What to watch for",
            description: "How extreme heat affects your car and what to monitor.",
            readTimeMinutes: 2,
            difficulty: .beginner,
            category: .seasonalPrep,
            sections: [
                ArticleSection(heading: "Overheating Risk", body: "Heat stresses your cooling system. Watch the temperature gauge — if it climbs toward the red, pull over and let the engine cool. Never open the radiator cap when hot."),
                ArticleSection(heading: "Battery Strain", body: "Heat actually kills batteries faster than cold. Have yours tested if it's over 3 years old."),
                ArticleSection(heading: "Tire Blowout Risk", body: "Hot pavement + underinflated tires = blowout risk. Check pressure in the morning before driving when tires are cool."),
            ],
            relatedSystemNames: ["Battery", "Tires & Wheels", "HVAC"]
        ),
        LearningArticle(
            id: UUID(),
            title: "Oil change: What happens and why it matters",
            description: "Understand the process and avoid getting oversold at the shop.",
            readTimeMinutes: 2,
            difficulty: .beginner,
            category: .understandingRepairs,
            sections: [
                ArticleSection(heading: "The Process", body: "Old oil is drained, the filter is replaced, and fresh oil is added. Takes 20–30 minutes at a shop."),
                ArticleSection(heading: "Conventional vs Synthetic", body: "Conventional: $30–$50, lasts 3,000–5,000 miles. Full synthetic: $45–$80, lasts 5,000–10,000 miles. Synthetic is worth it for most modern cars."),
                ArticleSection(heading: "Common Upsells", body: "Watch out for: engine flush ($100+ and usually unnecessary), premium oil filter ($20+ over standard), fuel system cleaning (rarely needed at oil change time)."),
            ],
            relatedSystemNames: ["Engine", "Fluids"]
        ),
        LearningArticle(
            id: UUID(),
            title: "Brake job breakdown: Pads vs. rotors",
            description: "Know what you actually need and avoid paying for unnecessary rotor replacement.",
            readTimeMinutes: 3,
            difficulty: .intermediate,
            category: .understandingRepairs,
            sections: [
                ArticleSection(heading: "Pads Only", body: "If caught early (squealing stage), you usually just need new pads: $150–$300 per axle. This is the most common brake service."),
                ArticleSection(heading: "Pads + Rotors", body: "If pads are worn to metal (grinding), rotors are likely damaged too: $300–$600 per axle. Some shops push rotor replacement when pads alone would suffice."),
                ArticleSection(heading: "How to Spot Overselling", body: "Ask for rotor thickness measurements. Rotors have a minimum thickness stamped on them — if they're above it, they can be resurfaced ($20–$40 each) instead of replaced ($50–$120 each)."),
            ],
            relatedSystemNames: ["Brakes"]
        ),
    ]
}

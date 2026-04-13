import Foundation

/// Two-phase vehicle maintenance analyzer using Perplexity Sonar (web search built in).
/// Phase 1: Research OEM schedule (cached locally per vehicle model).
/// Phase 2: Personalize based on user's mileage + service history.
enum AIMaintenanceAnalyzer {

    // MARK: - Configuration

    private static let apiKey = Secrets.perplexityAPIKey
    private static let endpoint = URL(string: "https://api.perplexity.ai/chat/completions")!

    // MARK: - OEM Schedule Response Models

    private struct OEMSource: Codable {
        let name: String
        let url: String?
        let reliability: String
    }

    private struct OEMMaintenanceItem: Codable {
        let item: String
        let action: String
        let interval_miles: Int?
        let interval_months: Int?
        let first_due_miles: Int?
        let first_due_months: Int?
        let subsequent_interval_miles: Int?
        let subsequent_interval_months: Int?
        let severe_conditions_interval_miles: Int?
        let severe_conditions_interval_months: Int?
        let category: String
        let confidence: String
        let notes: String
        let estimated_cost_low: Double
        let estimated_cost_high: Double
        let diy_difficulty: Int
    }

    private struct OEMBaseInterval: Codable {
        let miles: Int?
        let months: Int?
        let notes: String
    }

    private struct OEMVehicleInfo: Codable {
        let year: Int
        let make: String
        let model: String
        let trim: String?
    }

    private struct OEMScheduleResponse: Codable {
        let vehicle: OEMVehicleInfo
        let sources_consulted: [OEMSource]
        let base_service_interval: OEMBaseInterval
        let maintenance_items: [OEMMaintenanceItem]
    }

    // MARK: - Perplexity Response (OpenAI-compatible)

    private struct ChatCompletionResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable {
                let content: String
            }
            let message: Message
        }
        let choices: [Choice]
    }

    // MARK: - Cache

    private struct CachedSchedule: Codable {
        let schedule: OEMScheduleResponse
        let generated_at: Date
    }

    private static var cacheDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("oem_schedules")
    }

    private static func vehicleKey(for vehicle: Vehicle) -> String {
        let parts = ["\(vehicle.year)", vehicle.make, vehicle.model, vehicle.trim ?? ""]
        return parts
            .map { $0.lowercased().replacingOccurrences(of: " ", with: "-") }
            .map { $0.replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression) }
            .joined(separator: "_")
    }

    private static func loadCachedSchedule(key: String) -> OEMScheduleResponse? {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")
        guard let data = try? Data(contentsOf: fileURL),
              let cached = try? JSONDecoder.withISO8601.decode(CachedSchedule.self, from: data) else {
            return nil
        }
        let sixMonths: TimeInterval = 6 * 30 * 24 * 60 * 60
        guard Date().timeIntervalSince(cached.generated_at) < sixMonths else {
            print("🔧 [AIAnalyzer] Cache expired for \(key)")
            return nil
        }
        print("🔧 [AIAnalyzer] Cache hit for \(key)")
        return cached.schedule
    }

    private static func saveScheduleToCache(key: String, schedule: OEMScheduleResponse) {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        let cached = CachedSchedule(schedule: schedule, generated_at: Date())
        if let data = try? JSONEncoder.withISO8601.encode(cached) {
            try? data.write(to: fileURL)
            print("🔧 [AIAnalyzer] Cached schedule for \(key)")
        }
    }

    // MARK: - Public API

    static func analyze(
        vehicle: Vehicle,
        answers: [String: String],
        oilMileage: String,
        brakeMileage: String
    ) async throws -> [MaintenanceItem] {

        // Phase 1: Get OEM schedule (from cache or Perplexity web search)
        let key = vehicleKey(for: vehicle)
        let oemSchedule: OEMScheduleResponse

        if let cached = loadCachedSchedule(key: key) {
            oemSchedule = cached
        } else {
            print("🔧 [AIAnalyzer] Phase 1: Researching OEM schedule via Perplexity...")
            oemSchedule = try await fetchOEMSchedule(vehicle: vehicle)
            saveScheduleToCache(key: key, schedule: oemSchedule)

            // Log parsed OEM items
            print("🔧 [AIAnalyzer] ═══════════ PARSED OEM ITEMS ═══════════")
            for (i, item) in oemSchedule.maintenance_items.enumerated() {
                print("  [\(i+1)] \(item.item) | interval: \(item.interval_miles ?? 0)mi / \(item.interval_months ?? 0)mo | cat: \(item.category) | confidence: \(item.confidence) | cost: $\(item.estimated_cost_low)-$\(item.estimated_cost_high)")
            }
            print("🔧 [AIAnalyzer] ═══════════ END OEM ITEMS ═══════════")
        }

        print("🔧 [AIAnalyzer] OEM schedule has \(oemSchedule.maintenance_items.count) items")
        print("🔧 [AIAnalyzer] Sources: \(oemSchedule.sources_consulted.map { $0.name }.joined(separator: ", "))")

        // Phase 2: Deterministic local personalization (no API call)
        print("🔧 [AIAnalyzer] Phase 2: Personalizing locally with deterministic math...")
        let items = personalizeLocally(
            oemSchedule: oemSchedule,
            vehicle: vehicle,
            answers: answers,
            oilMileage: oilMileage,
            brakeMileage: brakeMileage
        )

        print("🔧 [AIAnalyzer] ✅ Mapped \(items.count) personalized maintenance items")
        for item in items {
            print("  [\(item.status.rawValue)] \(item.name) — due: \(item.dueMileage.map { "\($0) mi" } ?? "n/a")")
        }
        return items
    }

    // MARK: - Phase 1: OEM Schedule Research (Perplexity sonar-pro with web search)

    private static func fetchOEMSchedule(vehicle: Vehicle) async throws -> OEMScheduleResponse {
        let requestBody: [String: Any] = [
            "model": "sonar-pro",
            "messages": [
                ["role": "system", "content": oemSystemPrompt],
                ["role": "user", "content": buildOEMUserPrompt(vehicle: vehicle)]
            ],
            "temperature": 0.1,
            "max_tokens": 4096
        ]

        let content = try await callPerplexityAPI(body: requestBody, timeout: 90)
        let jsonString = extractJSON(from: content)

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw AnalyzerError.invalidResponse
        }

        // Reject error responses from Perplexity (e.g. "Insufficient data")
        if jsonString.contains("\"error\"") && jsonString.contains("Insufficient") {
            print("🔧 [AIAnalyzer] ⚠️ Perplexity returned an error response instead of schedule — retrying won't help, using fallback")
            throw AnalyzerError.invalidResponse
        }

        let schedule = try JSONDecoder().decode(OEMScheduleResponse.self, from: jsonData)

        // Don't accept empty results — treat as a failure so we don't cache garbage
        guard !schedule.maintenance_items.isEmpty else {
            print("🔧 [AIAnalyzer] ⚠️ Perplexity returned 0 maintenance items — treating as failure")
            throw AnalyzerError.invalidResponse
        }

        return schedule
    }

    // MARK: - Phase 2: Deterministic Local Personalization

    private static func personalizeLocally(
        oemSchedule: OEMScheduleResponse,
        vehicle: Vehicle,
        answers: [String: String],
        oilMileage: String,
        brakeMileage: String
    ) -> [MaintenanceItem] {
        let currentMileage = vehicle.mileage

        // Parse mileage inputs
        let lastOilMileage = Int(oilMileage.replacingOccurrences(of: ",", with: ""))
        let lastBrakeMileage = Int(brakeMileage.replacingOccurrences(of: ",", with: ""))

        // Map category → (answer key, last service mileage if available)
        let categoryToHistory: [String: (answerKey: String, lastMileage: Int?)] = [
            "oil": ("oil", lastOilMileage),
            "tires": ("tire", nil),
            "brakes": ("brake", lastBrakeMileage),
            "filters": ("air", nil),
            "battery": ("battery", nil),
        ]

        // Use severe intervals if applicable
        let severeConditions = ["Snow", "Dust", "Delivery/Rideshare", "City driving"]
        let hasSevere = vehicle.conditions.contains(where: { severeConditions.contains($0) }) ||
                        vehicle.usage.contains("Delivery/Rideshare")

        var items: [MaintenanceItem] = []

        for oemItem in oemSchedule.maintenance_items {
            let interval = effectiveInterval(for: oemItem, severe: hasSevere)
            guard interval > 0 else {
                // No mileage interval — default to overdue with generic description
                items.append(makeItem(
                    oemItem: oemItem, vehicle: vehicle, status: .overdue, dueMileage: nil,
                    description: "\(oemItem.item) — no mileage interval found. Recommend inspection."
                ))
                continue
            }

            let history = categoryToHistory[oemItem.category]
            let answer = history.flatMap { answers[$0.answerKey] }
            let lastMileage = history?.lastMileage

            if let lastMileage {
                // We have exact mileage — do precise math
                let nextDue = lastMileage + interval
                let remaining = nextDue - currentMileage
                let threshold = Int(Double(interval) * 0.15)

                let status: MaintenanceStatus
                let description: String

                if currentMileage > nextDue {
                    let overdueBy = currentMileage - nextDue
                    status = .overdue
                    description = "Last serviced at \(lastMileage.formatted()) miles. Was due at ~\(nextDue.formatted()) miles — overdue by ~\(overdueBy.formatted()) miles."
                } else if remaining <= threshold {
                    status = .dueSoon
                    description = "Last serviced at \(lastMileage.formatted()) miles. Due at ~\(nextDue.formatted()) miles — only \(remaining.formatted()) miles remaining."
                } else {
                    status = .onTrack
                    description = "Last serviced at \(lastMileage.formatted()) miles. Next due at ~\(nextDue.formatted()) miles (\(remaining.formatted()) miles remaining)."
                }

                items.append(makeItem(
                    oemItem: oemItem, vehicle: vehicle, status: status, dueMileage: nextDue,
                    description: description
                ))
            } else if let answer, answer != "unknown" {
                // Time-based answer only — estimate status from the bucket
                let (status, description) = statusFromTimeBucket(
                    answer: answer, category: oemItem.category, itemName: oemItem.item,
                    intervalMiles: interval, intervalMonths: oemItem.interval_months
                )
                // Estimate next due mileage from current position
                let estimatedDue = status == .onTrack ? currentMileage + interval : currentMileage
                items.append(makeItem(
                    oemItem: oemItem, vehicle: vehicle, status: status, dueMileage: estimatedDue,
                    description: description
                ))
            } else {
                // Unknown or no matching history
                items.append(makeItem(
                    oemItem: oemItem, vehicle: vehicle, status: .overdue, dueMileage: nil,
                    description: "No service history recorded. \(interval.formatted())-mile interval — recommend inspection."
                ))
            }
        }

        return items
    }

    /// Returns the effective interval in miles, using severe interval if applicable.
    private static func effectiveInterval(for item: OEMMaintenanceItem, severe: Bool) -> Int {
        if severe, let severeInterval = item.severe_conditions_interval_miles {
            return severeInterval
        }
        return item.subsequent_interval_miles ?? item.interval_miles ?? 0
    }

    /// Maps a time-bucket answer to a status and description string.
    private static func statusFromTimeBucket(
        answer: String, category: String, itemName: String,
        intervalMiles: Int, intervalMonths: Int?
    ) -> (MaintenanceStatus, String) {
        // Estimate how "stale" the service is based on the answer bucket
        let monthsSinceService: Int
        switch answer {
        // Oil buckets
        case "within-3m": monthsSinceService = 2
        case "3-6m": monthsSinceService = 5
        case "6-12m": monthsSinceService = 9
        case "over-1y": monthsSinceService = 15
        // Tire buckets
        case "within-6m", "with-oil": monthsSinceService = 3
        // Brake buckets
        case "within-1y": monthsSinceService = 6
        case "1-2y": monthsSinceService = 18
        case "2-3y": monthsSinceService = 30
        case "over-3y": monthsSinceService = 42
        // Air filter buckets
        case "within-2y": monthsSinceService = 12
        case "at-service": monthsSinceService = 6
        // Battery buckets
        case "recent": monthsSinceService = 6
        case "2023-2024": monthsSinceService = 24
        case "before-2023": monthsSinceService = 36
        case "original": monthsSinceService = 60
        default: monthsSinceService = 24
        }

        let intervalMo = intervalMonths ?? 12
        let bucketLabel = answer.replacingOccurrences(of: "-", with: " ")

        if monthsSinceService > intervalMo + 3 {
            return (.overdue,
                    "Last serviced approximately \(bucketLabel) ago. \(intervalMiles.formatted())-mile / \(intervalMo)-month interval — likely overdue. Recommend service soon.")
        } else if monthsSinceService >= intervalMo - 2 {
            return (.dueSoon,
                    "Last serviced approximately \(bucketLabel) ago. \(intervalMiles.formatted())-mile / \(intervalMo)-month interval — coming due soon.")
        } else {
            return (.onTrack,
                    "Last serviced approximately \(bucketLabel) ago. \(intervalMiles.formatted())-mile / \(intervalMo)-month interval — on track.")
        }
    }

    /// Helper to construct a MaintenanceItem from an OEM item.
    private static func makeItem(
        oemItem: OEMMaintenanceItem, vehicle: Vehicle,
        status: MaintenanceStatus, dueMileage: Int?, description: String
    ) -> MaintenanceItem {
        MaintenanceItem(
            id: UUID(),
            vehicleId: vehicle.id,
            name: oemItem.item,
            status: status,
            dueDate: nil,
            dueMileage: dueMileage,
            description: description,
            estimatedCostLow: oemItem.estimated_cost_low,
            estimatedCostHigh: oemItem.estimated_cost_high,
            category: "ai-\(oemItem.category)",
            diyDifficulty: oemItem.diy_difficulty
        )
    }

    // MARK: - Perplexity API Call (OpenAI-compatible)

    private static func callPerplexityAPI(body: [String: Any], timeout: TimeInterval) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeout
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        print("🔧 [AIAnalyzer] Calling Perplexity API...")
        let (data, response) = try await URLSession.shared.data(for: request)

        let httpResponse = response as? HTTPURLResponse
        print("🔧 [AIAnalyzer] Response status: \(httpResponse?.statusCode ?? -1)")

        // Log the FULL raw JSON response
        if let rawJSON = String(data: data, encoding: .utf8) {
            print("🔧 [AIAnalyzer] ═══════════ RAW PERPLEXITY RESPONSE ═══════════")
            print(rawJSON)
            print("🔧 [AIAnalyzer] ═══════════ END RAW RESPONSE ═══════════")
        }

        if let statusCode = httpResponse?.statusCode, statusCode != 200 {
            throw AnalyzerError.apiError
        }

        let completion = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let content = completion.choices.first?.message.content else {
            print("🔧 [AIAnalyzer] No content in response")
            throw AnalyzerError.invalidResponse
        }

        // Log the extracted content (the actual AI answer)
        print("🔧 [AIAnalyzer] ═══════════ EXTRACTED CONTENT ═══════════")
        print(content)
        print("🔧 [AIAnalyzer] ═══════════ END CONTENT ═══════════")
        return content
    }

    /// Extracts JSON object from a string that may contain markdown, code fences, or surrounding text.
    private static func extractJSON(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Direct JSON
        if trimmed.hasPrefix("{"), let _ = try? JSONSerialization.jsonObject(with: Data(trimmed.utf8)) {
            return trimmed
        }

        // Code fence extraction
        if let match = trimmed.range(of: "```(?:json)?\\s*([\\s\\S]*?)```", options: .regularExpression) {
            let fenceContent = String(trimmed[match])
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return fenceContent
        }

        // Outermost braces
        if let start = trimmed.firstIndex(of: "{"), let end = trimmed.lastIndex(of: "}") {
            return String(trimmed[start...end])
        }

        return trimmed
    }

    // MARK: - System Prompts

    private static let oemSystemPrompt = """
    You are a vehicle maintenance research assistant. \
    Return ONLY valid JSON matching the requested schema. \
    No markdown, no code fences, no explanation text before or after the JSON. \
    NEVER return an error object — always return the maintenance schedule. \
    If you cannot access a PDF, use dealer websites, KBB, Youtube, Edmunds, RepairPal, \
    manufacturer service bulletins, and enthusiast forums to compile the schedule. \
    The maintenance intervals for popular vehicles are widely published across \
    many sources — you do not need the PDF to answer this.
    """

    // MARK: - User Prompts

    private static func buildOEMUserPrompt(vehicle: Vehicle) -> String {
        return """
        Research and return the complete OEM maintenance schedule for:
        Vehicle: \(vehicle.year) \(vehicle.make) \(vehicle.model) \(vehicle.trim ?? "Base")
        Transmission: automatic

        Find the official manufacturer maintenance guide for this exact vehicle. \
        Prioritize the warranty & maintenance guide PDF, official dealer maintenance \
        schedule pages, and enthusiast forums that reference the actual owner's manual \
        intervals. Cross-reference at least 2-3 sources.

        For each maintenance item, provide:
        - The exact OEM interval in miles AND months/years (whichever comes first)
        - When it FIRST comes due on a brand new vehicle (first_due_miles)
        - The repeat interval after the first service (if different from the standard interval)
        - A shorter interval for severe/special operating conditions if the manufacturer \
          specifies one (severe conditions = towing, stop-and-go city driving, dusty/muddy \
          roads, extreme temperatures)
        - Estimated cost range (USD, typical shop price)
        - DIY difficulty (1=no tools needed, 2=basic hand tools, 3=jack/stands needed, \
          4=specialized tools, 5=professional equipment required)
        - Confidence level: high if from official OEM manual/PDF, medium if from dealer \
          sites, low if inferred

        CRITICAL RULES:
        - Use OEM intervals ONLY — do not fall back on generic/universal intervals
        - first_due_miles means when this item first comes due on a BRAND NEW vehicle
        - Include ALL items from the OEM schedule: oil, filters, tire rotation, brake \
          inspection, brake fluid, transmission fluid, differential fluid, transfer case \
          fluid, coolant, spark plugs, timing belt/chain, drive belts, cabin air filter, \
          engine air filter, valve adjustment, wiper blades, battery inspection, suspension \
          inspection, exhaust inspection, and any other items specific to this vehicle
        - Do NOT omit items. If the OEM maintenance schedule lists it, include it.
        - Populate first_due_miles and first_due_months for EVERY item.

        Return as JSON:
        {
          "vehicle": { "year": number, "make": "string", "model": "string", "trim": "string", \
        "transmission": "string", "engine": "string or null" },
          "sources_consulted": [{ "name": "string", "url": "string", \
        "reliability": "official|dealer|specialist|forum" }],
          "base_service_interval": { "miles": number|null, "months": number|null, "notes": "string" },
          "maintenance_items": [{
            "item": "string", "action": "replace|inspect|clean|perform",
            "interval_miles": number|null, "interval_months": number|null,
            "first_due_miles": number|null, "first_due_months": number|null,
            "subsequent_interval_miles": number|null, "subsequent_interval_months": number|null,
            "severe_conditions_interval_miles": number|null, "severe_conditions_interval_months": number|null,
            "category": "oil|tires|brakes|filters|battery|transmission|cooling|fluids|belts|ignition|suspension|general",
            "confidence": "high|medium|low",
            "notes": "string",
            "estimated_cost_low": number, "estimated_cost_high": number,
            "diy_difficulty": 1-5
          }]
        }
        """
    }

    // MARK: - Errors

    enum AnalyzerError: LocalizedError {
        case apiError
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .apiError: return "AI analysis service returned an error"
            case .invalidResponse: return "Could not parse AI analysis response"
            }
        }
    }
}

// MARK: - JSON Encoder/Decoder with ISO8601

private extension JSONEncoder {
    static let withISO8601: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}

private extension JSONDecoder {
    static let withISO8601: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

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
        let type: String // "official" | "dealer" | "specialist" | "forum"
        let name: String
        let url: String?
    }

    private struct OEMMaintenanceItem: Codable {
        let name: String
        let action: String
        let type: String // "recurring" | "one_time" | "recurring_after_first"
        let interval_miles: Int?
        let interval_months: Int?
        let first_due_miles: Int?
        let first_due_months: Int?
        let subsequent_interval_miles: Int?
        let subsequent_interval_months: Int?
        let severe_only: Bool?
        let severe_condition: String?
        let category: String
        let notes: String?
    }

    private struct OEMBaseInterval: Codable {
        let miles: Int?
        let months: Int?
        let notes: String?
    }

    private struct OEMVehicleInfo: Codable {
        let year: Int?
        let make: String?
        let model: String?
        let trim: String?
        let engine: String?
    }

    // NOTE: Schema bumped — old cached schedules at {Documents}/oem_schedules/*.json
    // will fail to decode (handled silently by `try?` in loadCachedSchedule) and
    // be refetched on next analysis.
    // Only `maintenance_items` is truly required for Phase 2; the rest are optional
    // so a partial Perplexity response still parses.
    private struct OEMScheduleResponse: Codable {
        let vehicle: OEMVehicleInfo?
        let sources: [OEMSource]?
        let base_interval: OEMBaseInterval?
        let maintenance_items: [OEMMaintenanceItem]
        let footnotes: [String]?
    }

    // MARK: - Perplexity Response (OpenAI-compatible)

    private struct ChatCompletionResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable {
                let content: String
            }
            let message: Message
        }
        struct SearchResult: Decodable {
            let title: String?
            let url: String
        }
        let choices: [Choice]
        /// URLs Perplexity actually searched (top-level, outside the message).
        let citations: [String]?
        /// Richer form of `citations` with page titles, when returned.
        let search_results: [SearchResult]?
    }

    /// The model's answer plus the web pages Perplexity grounded it on.
    private struct PerplexityReply {
        let content: String
        let citations: [OEMSource]
    }

    /// Converts Perplexity's top-level citations into footer sources. Used when
    /// the model omits the `sources` array from its JSON, so the Service Plan
    /// can still show where the schedule came from.
    private static func sourcesFromCitations(_ completion: ChatCompletionResponse) -> [OEMSource] {
        var seen = Set<String>()
        var result: [OEMSource] = []
        let pairs: [(String?, String)] = completion.search_results?.map { ($0.title, $0.url) }
            ?? (completion.citations ?? []).map { (nil, $0) }
        for (title, url) in pairs where seen.insert(url).inserted {
            let host = URL(string: url)?.host?.replacingOccurrences(of: "www.", with: "")
            let trimmed = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let name = !trimmed.isEmpty ? trimmed : (host ?? url)
            result.append(OEMSource(type: "web", name: name, url: url))
        }
        return result
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
        // Schedules cached before sources were captured can't show provenance;
        // refetch so the Service Plan footer can link to where it came from.
        guard !(cached.schedule.sources ?? []).isEmpty else {
            print("🔧 [AIAnalyzer] Cached schedule for \(key) has no sources — refetching")
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

    // MARK: - Debug

    static func clearCache() -> Int {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else {
            return 0
        }
        var count = 0
        for file in files where file.pathExtension == "json" {
            if (try? fm.removeItem(at: file)) != nil { count += 1 }
        }
        print("🔧 [AIAnalyzer] Cleared \(count) cached OEM schedule(s)")
        return count
    }

    // MARK: - Public API

    /// Bundled analyzer result: personalized maintenance items (status/due
    /// math) + the raw OEM schedule in the flat-list-with-recurrence shape
    /// that the Service Plan timeline renders from.
    struct AnalyzerResult {
        let items: [MaintenanceItem]
        let schedule: [OEMScheduleItemInput]
        let sources: [OEMScheduleSource]
    }

    static func analyze(
        vehicle: Vehicle,
        answers: [String: String],
        oilMileage: String,
        brakeMileage: String
    ) async throws -> AnalyzerResult {

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
                let firstDue = item.first_due_miles ?? 0
                let every = item.interval_miles ?? item.subsequent_interval_miles ?? 0
                print("  [\(i+1)] \(item.name) | type: \(item.type) | first: \(firstDue)mi / \(item.first_due_months ?? 0)mo | every: \(every)mi / \(item.interval_months ?? 0)mo | cat: \(item.category) | severe_only: \(item.severe_only ?? false)")
            }
            print("🔧 [AIAnalyzer] ═══════════ END OEM ITEMS ═══════════")
        }

        print("🔧 [AIAnalyzer] OEM schedule has \(oemSchedule.maintenance_items.count) items")
        print("🔧 [AIAnalyzer] Sources: \((oemSchedule.sources ?? []).map { $0.name }.joined(separator: ", "))")

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

        let schedule = oemSchedule.maintenance_items.map(oemItemToScheduleInput)
        let sources = (oemSchedule.sources ?? []).map {
            OEMScheduleSource(type: $0.type, name: $0.name, url: $0.url)
        }
        return AnalyzerResult(items: items, schedule: schedule, sources: sources)
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

        let reply = try await callPerplexityAPI(body: requestBody, timeout: 90)
        let content = reply.content
        let jsonString = extractJSON(from: content)

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw AnalyzerError.invalidResponse
        }

        // Reject error responses from Perplexity (e.g. "Insufficient data")
        if jsonString.contains("\"error\"") && jsonString.contains("Insufficient") {
            print("🔧 [AIAnalyzer] ⚠️ Perplexity returned an error response instead of schedule — retrying won't help, using fallback")
            throw AnalyzerError.invalidResponse
        }

        let schedule: OEMScheduleResponse
        do {
            schedule = try JSONDecoder().decode(OEMScheduleResponse.self, from: jsonData)
        } catch let DecodingError.keyNotFound(key, context) {
            let path = context.codingPath.map { $0.stringValue }.joined(separator: ".")
            let fullPath = path.isEmpty ? key.stringValue : "\(path).\(key.stringValue)"
            print("🔧 [AIAnalyzer] ❌ DECODE FAILED — missing key '\(key.stringValue)' at \(fullPath)")
            print("    debug: \(context.debugDescription)")
            print("    JSON snippet: \(jsonString.prefix(500))")
            AnalyticsService.shared.track(.oemScheduleDecodeFailed(
                errorType: "keyNotFound",
                path: fullPath,
                details: context.debugDescription,
                vehicleKey: vehicleKey(for: vehicle),
                jsonSample: String(jsonString.prefix(500))
            ))
            throw AnalyzerError.invalidResponse
        } catch let DecodingError.typeMismatch(type, context) {
            let path = context.codingPath.map { $0.stringValue }.joined(separator: ".")
            print("🔧 [AIAnalyzer] ❌ DECODE FAILED — type mismatch, expected \(type) at \(path)")
            print("    debug: \(context.debugDescription)")
            print("    JSON snippet: \(jsonString.prefix(500))")
            AnalyticsService.shared.track(.oemScheduleDecodeFailed(
                errorType: "typeMismatch",
                path: path,
                details: "expected \(type): \(context.debugDescription)",
                vehicleKey: vehicleKey(for: vehicle),
                jsonSample: String(jsonString.prefix(500))
            ))
            throw AnalyzerError.invalidResponse
        } catch let DecodingError.valueNotFound(type, context) {
            let path = context.codingPath.map { $0.stringValue }.joined(separator: ".")
            print("🔧 [AIAnalyzer] ❌ DECODE FAILED — null where \(type) expected at \(path)")
            print("    debug: \(context.debugDescription)")
            print("    JSON snippet: \(jsonString.prefix(500))")
            AnalyticsService.shared.track(.oemScheduleDecodeFailed(
                errorType: "valueNotFound",
                path: path,
                details: "expected \(type): \(context.debugDescription)",
                vehicleKey: vehicleKey(for: vehicle),
                jsonSample: String(jsonString.prefix(500))
            ))
            throw AnalyzerError.invalidResponse
        } catch let DecodingError.dataCorrupted(context) {
            let path = context.codingPath.map { $0.stringValue }.joined(separator: ".")
            print("🔧 [AIAnalyzer] ❌ DECODE FAILED — data corrupted at \(path)")
            print("    debug: \(context.debugDescription)")
            print("    JSON snippet (first 1000 chars):")
            print(String(jsonString.prefix(1000)))
            AnalyticsService.shared.track(.oemScheduleDecodeFailed(
                errorType: "dataCorrupted",
                path: path,
                details: context.debugDescription,
                vehicleKey: vehicleKey(for: vehicle),
                jsonSample: String(jsonString.prefix(500))
            ))
            throw AnalyzerError.invalidResponse
        } catch {
            print("🔧 [AIAnalyzer] ❌ DECODE FAILED — \(error.localizedDescription)")
            print("    error: \(error)")
            print("    JSON snippet: \(jsonString.prefix(500))")
            AnalyticsService.shared.track(.oemScheduleDecodeFailed(
                errorType: "unknown",
                path: "",
                details: String(describing: error),
                vehicleKey: vehicleKey(for: vehicle),
                jsonSample: String(jsonString.prefix(500))
            ))
            throw AnalyzerError.invalidResponse
        }

        // Don't accept empty results — treat as a failure so we don't cache garbage
        guard !schedule.maintenance_items.isEmpty else {
            print("🔧 [AIAnalyzer] ⚠️ Perplexity returned 0 maintenance items — treating as failure")
            throw AnalyzerError.invalidResponse
        }

        // Fall back to Perplexity's own citations when the model left `sources` out.
        if (schedule.sources ?? []).isEmpty, !reply.citations.isEmpty {
            print("🔧 [AIAnalyzer] Model omitted sources — using \(reply.citations.count) Perplexity citations")
            return OEMScheduleResponse(
                vehicle: schedule.vehicle,
                sources: reply.citations,
                base_interval: schedule.base_interval,
                maintenance_items: schedule.maintenance_items,
                footnotes: schedule.footnotes
            )
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
            "oil": ("oilRecency", lastOilMileage),
            "tires": ("tire", nil),
            "brakes": ("brake", lastBrakeMileage),
            "filters": ("air", nil),
            "battery": ("battery", nil),
            "transmission": ("transmission", nil),
        ]

        // Use severe intervals if applicable
        let severeConditions = ["Snow", "Dust", "Delivery/Rideshare", "City driving"]
        let hasSevere = vehicle.conditions.contains(where: { severeConditions.contains($0) }) ||
                        vehicle.usage.contains("Delivery/Rideshare")

        var items: [MaintenanceItem] = []

        for oemItem in oemSchedule.maintenance_items {
            // Skip items that only apply under severe conditions if user isn't severe.
            if (oemItem.severe_only ?? false) && !hasSevere {
                continue
            }

            let interval = effectiveInterval(for: oemItem, severe: hasSevere)
            guard interval > 0 else {
                // No mileage interval — default to overdue with generic description
                items.append(makeItem(
                    oemItem: oemItem, vehicle: vehicle, status: .overdue, dueMileage: nil,
                    description: "\(oemItem.name) — no mileage interval found. Recommend inspection."
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
                    answer: answer, category: oemItem.category, itemName: oemItem.name,
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

    /// Returns the effective interval in miles.
    /// New schema no longer has per-item severe intervals — `severe_only` is a binary
    /// flag indicating an item only applies under severe conditions (handled upstream
    /// by skipping the item entirely). The `severe` parameter is kept for API stability.
    private static func effectiveInterval(for item: OEMMaintenanceItem, severe: Bool) -> Int {
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
        case "2-3y", "over-2y": monthsSinceService = 30
        case "over-3y": monthsSinceService = 42
        // Air filter buckets
        case "within-2y": monthsSinceService = 12
        case "at-service": monthsSinceService = 6
        // Battery buckets
        case "recent": monthsSinceService = 6
        case "not-recent": monthsSinceService = 36
        case "no": monthsSinceService = 60
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
        // TODO: New Perplexity prompt no longer returns cost/DIY estimates.
        // The Service Maintenance Timeline task will decide whether to remove these
        // fields from MaintenanceItem or backfill them from another source.
        MaintenanceItem(
            id: UUID(),
            vehicleId: vehicle.id,
            name: oemItem.name,
            status: status,
            dueDate: nil,
            dueMileage: dueMileage,
            description: description,
            estimatedCostLow: 0,
            estimatedCostHigh: 0,
            category: "ai-\(oemItem.category)",
            diyDifficulty: 3
        )
    }

    // MARK: - Perplexity API Call (OpenAI-compatible)

    private static func callPerplexityAPI(body: [String: Any], timeout: TimeInterval) async throws -> PerplexityReply {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeout
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        print("🔧 [AIAnalyzer] Calling Perplexity API...")
        let callStart = Date()
        let (data, response) = try await URLSession.shared.data(for: request)
        let durationMs = Int(Date().timeIntervalSince(callStart) * 1000)

        let httpResponse = response as? HTTPURLResponse
        print("🔧 [AIAnalyzer] Response status: \(httpResponse?.statusCode ?? -1)")

        // Log the FULL raw JSON response
        if let rawJSON = String(data: data, encoding: .utf8) {
            print("🔧 [AIAnalyzer] ═══════════ RAW PERPLEXITY RESPONSE ═══════════")
            print(rawJSON)
            print("🔧 [AIAnalyzer] ═══════════ END RAW RESPONSE ═══════════")
        }

        if let statusCode = httpResponse?.statusCode, statusCode != 200 {
            AnalyticsService.shared.track(.perplexityCallFailed(reason: "HTTP \(statusCode)"))
            throw AnalyzerError.apiError
        }

        let completion = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let content = completion.choices.first?.message.content else {
            print("🔧 [AIAnalyzer] No content in response")
            AnalyticsService.shared.track(.perplexityCallFailed(reason: "no content in response"))
            throw AnalyzerError.invalidResponse
        }

        AnalyticsService.shared.track(.perplexityCallSucceeded(durationMs: durationMs))

        // Log the extracted content (the actual AI answer)
        print("🔧 [AIAnalyzer] ═══════════ EXTRACTED CONTENT ═══════════")
        print(content)
        print("🔧 [AIAnalyzer] ═══════════ END CONTENT ═══════════")
        return PerplexityReply(content: content, citations: sourcesFromCitations(completion))
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
        let year = vehicle.year
        let make = vehicle.make
        let model = vehicle.model
        let trim = vehicle.trim ?? ""
        let vinLine: String = {
            if let vin = vehicle.vin, !vin.isEmpty {
                return "VIN: \(vin)"
            }
            return ""
        }()

        return """
        Research the complete OEM maintenance schedule for:
        Vehicle: \(year) \(make) \(model) \(trim)
        \(vinLine)

        Find the official manufacturer warranty & maintenance guide for this exact vehicle.
        Cross-reference at least 2-3 sources. Prioritize in this order:
        1. Official OEM owner's manual or warranty & maintenance guide PDF
        2. Official dealer maintenance schedule pages
        3. Specialist repair sites (e.g. Firestone, RepairPal)
        4. Enthusiast forums that reference the actual owner's manual intervals

        Use the actual OEM schedule — do NOT invent generic intervals. If sources conflict,
        prefer the official OEM manual over dealer pages, and dealer pages over forums.

        IMPORTANT: Return the schedule as a FLAT LIST OF MAINTENANCE ITEMS, each with its own
        interval data. Do NOT return milestone snapshots (e.g. "at 10,000 miles do X, Y, Z").
        Instead, return each item ONCE with its recurrence pattern.

        For each item, classify it as either:
        - "recurring": repeats on a fixed cycle (e.g. oil change every 10,000 miles)
        - "one_time": happens once at a specific mileage (e.g. PCV valve inspect at 100,000 miles)
        - "recurring_after_first": has a different first-due mileage, then repeats on a fixed cycle
          (e.g. coolant at 100,000 then every 50,000 after)

        Rules:
        - Include ALL items the OEM lists — oil, filters, inspections, fluid changes, belt
          replacements, spark plugs, everything
        - Use the exact item names from the OEM guide when possible (e.g. "Brake Linings/Drums
          and Brake Pads/Discs" not just "Brakes")
        - Each item needs an action: replace, inspect, clean, adjust, or perform
        - If an item only applies under severe/special conditions (dusty roads, towing, off-road,
          extreme temps), set "severe_only" to true and note the condition
        - If an item only applies to certain configurations (AWD only, hybrid only, turbo only,
          etc.), note that in the item name in parentheses
        - Do NOT combine separate items into one (e.g. "Engine Oil" and "Oil Filter" should be
          separate entries if the OEM lists them separately)
        - Do NOT include cost estimates or DIY difficulty
        - Do NOT include administrative items like "Reset Maintenance Reminder" or "Inspect Floor
          Mat Installation"
        - Do NOT include windshield wiper blade replacement — this is a wear item that varies entirely by climate and usage, not a mileage-based OEM service item

        Return ONLY valid JSON in this exact structure:
        {
          "vehicle": {
            "year": \(year),
            "make": "\(make)",
            "model": "\(model)",
            "trim": "\(trim)",
            "engine": "engine type if identified, or null"
          },
          "sources": [
            {
              "type": "official",
              "name": "2025 Jeep Wrangler 4xe Owner's Manual",
              "url": "https://example.com/owners-manual.pdf"
            },
            {
              "type": "dealer",
              "name": "Rockland CDJR Wrangler 4xe Maintenance Schedule",
              "url": "https://example.com/schedule"
            }
          ],
          "base_interval": {
            "miles": 10000,
            "months": 12,
            "notes": "e.g. Oil change when indicator activates, not to exceed 10,000 miles or 12 months"
          },
          "maintenance_items": [
            {
              "name": "Engine Oil",
              "action": "replace",
              "type": "recurring",
              "interval_miles": 10000,
              "interval_months": 12,
              "first_due_miles": 10000,
              "first_due_months": 12,
              "subsequent_interval_miles": null,
              "subsequent_interval_months": null,
              "severe_only": false,
              "severe_condition": null,
              "category": "oil",
              "notes": null
            },
            {
              "name": "Cabin Air Filter",
              "action": "replace",
              "type": "recurring",
              "interval_miles": 20000,
              "interval_months": 24,
              "first_due_miles": 20000,
              "first_due_months": 24,
              "subsequent_interval_miles": null,
              "subsequent_interval_months": null,
              "severe_only": false,
              "severe_condition": null,
              "category": "filters",
              "notes": null
            },
            {
              "name": "Engine Coolant",
              "action": "replace",
              "type": "recurring_after_first",
              "interval_miles": null,
              "interval_months": null,
              "first_due_miles": 100000,
              "first_due_months": 120,
              "subsequent_interval_miles": 50000,
              "subsequent_interval_months": 60,
              "severe_only": false,
              "severe_condition": null,
              "category": "cooling",
              "notes": "Initial replacement at 100,000 miles, then every 50,000 miles thereafter"
            },
            {
              "name": "PCV Valve",
              "action": "inspect and replace if necessary",
              "type": "one_time",
              "interval_miles": null,
              "interval_months": null,
              "first_due_miles": 100000,
              "first_due_months": 120,
              "subsequent_interval_miles": null,
              "subsequent_interval_months": null,
              "severe_only": false,
              "severe_condition": null,
              "category": "engine",
              "notes": null
            },
            {
              "name": "Engine Air Cleaner Filter",
              "action": "inspect",
              "type": "recurring",
              "interval_miles": 10000,
              "interval_months": 12,
              "first_due_miles": 10000,
              "first_due_months": 12,
              "subsequent_interval_miles": null,
              "subsequent_interval_months": null,
              "severe_only": true,
              "severe_condition": "dusty or off-road conditions",
              "category": "filters",
              "notes": "Only required under dusty or off-road driving conditions"
            }
          ],
          "footnotes": [
            "Any important OEM notes about severe duty definitions, special intervals, or vehicle-specific caveats"
          ]
        }

        List ALL sources consulted in the "sources" array, ranked by reliability
        (official > dealer > specialist > forum). Use these exact type values:
        "official", "dealer", "specialist", "forum".

        Valid category values: oil, tires, brakes, filters, battery, transmission,
        cooling, fluids, belts, ignition, suspension, engine, exhaust, electrical, general

        Return ONLY the JSON. No markdown fences. No explanation.
        """
    }

    // MARK: - Errors

    // MARK: - OEM → ServicePlan bridge

    private static func oemItemToScheduleInput(_ item: OEMMaintenanceItem) -> OEMScheduleItemInput {
        OEMScheduleItemInput.make(
            name: item.name,
            action: item.action,
            category: item.category,
            type: item.type,
            intervalMiles: item.interval_miles,
            firstDueMiles: item.first_due_miles,
            subsequentIntervalMiles: item.subsequent_interval_miles,
            severeOnly: item.severe_only ?? false
        )
    }

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

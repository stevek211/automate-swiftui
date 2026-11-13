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

    /// One server-sent event of a streamed reply. Content arrives in pieces in `delta`;
    /// citations repeat on every chunk.
    private struct StreamChunk: Decodable {
        struct Choice: Decodable {
            struct Delta: Decodable { let content: String? }
            let delta: Delta?
        }
        let choices: [Choice]?
        let citations: [String]?
        let search_results: [ChatCompletionResponse.SearchResult]?
    }

    /// The model's answer plus the web pages Perplexity grounded it on.
    private struct PerplexityReply {
        let content: String
        let citations: [OEMSource]
    }

    /// Converts Perplexity's top-level citations into footer sources. Used when
    /// the model omits the `sources` array from its JSON, so the Service Plan
    /// can still show where the schedule came from.
    private static func sourcesFromCitations(
        searchResults: [ChatCompletionResponse.SearchResult]?,
        citations: [String]?
    ) -> [OEMSource] {
        var seen = Set<String>()
        var result: [OEMSource] = []
        let pairs: [(String?, String)] = searchResults?.map { ($0.title, $0.url) }
            ?? (citations ?? []).map { (nil, $0) }
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

        let schedule = oemSchedule.maintenance_items.map { oemItemToScheduleInput($0, vehicle: vehicle) }
        let sources = (oemSchedule.sources ?? []).map {
            OEMScheduleSource(type: $0.type, name: $0.name, url: $0.url)
        }
        return AnalyzerResult(items: items, schedule: schedule, sources: sources)
    }

    // MARK: - Phase 1: OEM Schedule Research (Perplexity sonar-pro with web search)

    /// Step 1 of 2: a short, focused web search for the schedule in plain language.
    ///
    /// Asking for the whole JSON structure in one request makes the model rely on the first
    /// source it finds (the owner's manual, which for Maintenance Minder / oil-life cars has
    /// dashboard codes but no mileages) and skip dealer pages that list mileage milestones.
    /// A narrow question finds those pages. Returns nil on any failure so we fall back to the
    /// single-request behaviour.
    private static func researchSchedule(vehicle: Vehicle) async -> String? {
        let name = "\(vehicle.year) \(vehicle.make) \(vehicle.model) \(vehicle.trim ?? "")"
            .trimmingCharacters(in: .whitespaces)
        let vin = (vehicle.vin?.isEmpty == false) ? " (VIN \(vehicle.vin!))" : ""
        let question = """
        Find the maintenance schedule for a \(name)\(vin).

        Check, in order: (1) the official owner's manual or warranty & maintenance guide, \
        (2) dealer service pages — especially ones that list MILEAGE MILESTONES such as \
        7,500 / 15,000 / 30,000 / 45,000 / 60,000 miles and what is done at each, \
        (3) specialist maintenance-schedule sites.

        For every service item (oil and filter, tire rotation, air and cabin filters, brake \
        fluid, transmission / transfer case / differential fluid, coolant, spark plugs, \
        timing belt, belts, brake / suspension / steering / exhaust inspections, etc.) give: \
        the mileage(s) it is due, whether and how often it repeats, and the page it came from.

        If the owner's manual only gives dashboard codes (Maintenance Minder, oil-life \
        monitor), say which codes AND give the mileage milestones from the dealer pages. \
        Where sources disagree, list each value and say which source is official. \
        Quote mileages exactly. Do not guess.
        """

        let body: [String: Any] = [
            "model": "sonar-pro",
            "messages": [
                ["role": "system", "content": "You are a vehicle maintenance researcher. Answer only from pages you find. Quote mileages exactly. Do not guess."],
                ["role": "user", "content": question]
            ],
            "temperature": 0.1,
            "max_tokens": 3000
        ]
        // Runs alongside the research: step 1's citations vary between runs and often
        // leave out the dealer pages that carry the milestone table.
        async let dealerSearch = searchDealerPages(vehicle: vehicle)
        do {
            let reply = try await callPerplexityAPI(body: body, timeout: 90)
            let pages = reply.citations
                .compactMap { source in source.url.map { "- \(source.name): \($0)" } }
                .joined(separator: "\n")
            print("🔧 [AIAnalyzer] Step 1 research found \(reply.citations.count) pages")
            var notes = reply.content + (pages.isEmpty ? "" : "\n\nPAGES CONSULTED:\n" + pages)
            let extracts = await readDealerPages(vehicle: vehicle, candidates: reply.citations + dealerSearch)
            if !extracts.isEmpty {
                notes += "\n\nDEALER PAGE EXTRACTS (read directly from the page — these are the authoritative mileages):\n\n"
                    + extracts.joined(separator: "\n\n")
            }
            return notes
        } catch {
            print("🔧 [AIAnalyzer] Step 1 research failed (\(error.localizedDescription)) — using single-request lookup")
            return nil
        }
    }

    /// A short search whose only job is to surface dealer pages listing the
    /// mileage-by-mileage schedule. Only the citations are used.
    private static func searchDealerPages(vehicle: Vehicle) async -> [OEMSource] {
        let make = vehicle.make.lowercased().replacingOccurrences(of: " ", with: "")
        // Leave out the manufacturer, manual and aggregator sites that otherwise fill every
        // result slot, so the search returns dealer pages. (Perplexity allows 20 entries.)
        let excluded = ["\(make).com", "\(make).ca", "\(make)infocenter.com", "kbb.com", "edmunds.com",
                        "yourmechanic.com", "garagedex.com", "maintenance-schedule.com", "manualslib.com",
                        "manuals.plus", "ifixit.com", "carmanualsonline.info", "reddit.com", "youtube.com",
                        "cars.com", "repairpal.com", "carwhere.com", "carcomplaints.com"]
        let body: [String: Any] = [
            "model": "sonar",
            "temperature": 0.1,
            "max_tokens": 300,
            "search_domain_filter": excluded.map { "-" + $0 },
            "messages": [
                ["role": "user", "content": "Which \(vehicle.make) dealership service pages publish the \(vehicle.make) \(vehicle.model) maintenance schedule by mileage (7,500 / 15,000 / 30,000 / 60,000 miles)? List the pages."]
            ]
        ]
        return (try? await callPerplexityAPI(body: body, timeout: 60))?.citations ?? []
    }

    /// Dealer service pages for this exact model that publish a mileage-milestone table.
    /// The host must name the make (e.g. "autonationacura…") and the URL must name the
    /// model and "maintenance", so generic schedule sites and other models are skipped.
    private static func dealerPages(for vehicle: Vehicle, in sources: [OEMSource]) -> [URL] {
        let make = vehicle.make.lowercased().replacingOccurrences(of: " ", with: "")
        let model = vehicle.model.lowercased()
            .replacingOccurrences(of: " ", with: "-")
        var seenHosts = Set<String>()
        return sources.compactMap { source -> URL? in
            guard let raw = source.url, let url = URL(string: raw), let host = url.host?.lowercased() else { return nil }
            let path = url.path.lowercased()
            // Skip pages for a different model year (e.g. ".../2026-acura-mdx-maintenance...").
            let years = path.matches(of: /(?:19|20)\d{2}/).map { String($0.output) }
            guard host.contains(make),
                  path.contains(model) || path.contains(model.replacingOccurrences(of: "-", with: "")),
                  path.contains("maintenance"),
                  years.allSatisfy({ $0 == String(vehicle.year) }),
                  seenHosts.insert(host).inserted
            else { return nil }
            return url
        }
    }

    /// True when an extract is a mileage-milestone table: at least four headings that name
    /// a mileage (e.g. "## 15,000 Mile Service"), none of them "Every …" style. Generic
    /// "every 6 months or 7,500 miles" guides don't qualify.
    private static func isMilestoneTable(_ text: String) -> Bool {
        let headings = text.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.hasPrefix("#") || ($0.hasPrefix("**") && $0.hasSuffix("**")) }
        if headings.contains(where: { $0.lowercased().contains("every") }) { return false }
        let milestones = Set(headings.compactMap { heading -> String? in
            heading.firstMatch(of: /\d{1,3},\d{3}/).map { String($0.output) }
        })
        return milestones.count >= 4
    }

    /// Reads dealer pages through Perplexity restricted to that one site, asking for the
    /// milestone table exactly as written. Page retrieval is flaky ("could not access the
    /// page"), so each page gets a second try, and we move down the list until one page
    /// yields a real milestone table. Only one table is used: dealer pages disagree with
    /// each other, and merging two of them muddles the schedule.
    private static func readDealerPages(vehicle: Vehicle, candidates: [OEMSource]) async -> [String] {
        // Structured dealer service pages before blog posts.
        let pages = dealerPages(for: vehicle, in: candidates)
            .sorted { ($0.path.contains("/service/") ? 0 : 1) < ($1.path.contains("/service/") ? 0 : 1) }
        print("🔧 [AIAnalyzer] Dealer pages to read: \(pages.map(\.absoluteString))")
        let modelName = "\(vehicle.make) \(vehicle.model)"
        var attempts = 0

        for url in pages {
            let host = url.host?.replacingOccurrences(of: "www.", with: "") ?? ""
            for _ in 0..<2 where attempts < 4 {
                attempts += 1
                let body: [String: Any] = [
                    "model": "sonar-pro",
                    "temperature": 0.1,
                    "max_tokens": 3000,
                    "search_domain_filter": [host],
                    // The milestone tables are long; the default context drops the later rows.
                    "web_search_options": ["search_context_size": "high"],
                    "messages": [
                        ["role": "system", "content": "You extract maintenance schedules from web pages. Report only what the page says. Quote mileages and service names exactly. Do not add anything from other knowledge."],
                        ["role": "user", "content": "Read the \(modelName) maintenance schedule page at \(url.absoluteString). For EVERY mileage milestone it lists, from the first to the last, write the milestone as a markdown heading (e.g. \"## 15,000 Mile Service\") and list exactly which services the page says are done at it. If the page has no mileage milestones or you cannot read it, reply only: NO MILESTONES. Then say whether the page names a model year."]
                    ]
                ]
                guard let reply = try? await callPerplexityAPI(body: body, timeout: 90) else { continue }
                let text = reply.content.trimmingCharacters(in: .whitespacesAndNewlines)
                if isMilestoneTable(text) {
                    print("🔧 [AIAnalyzer] Milestone table read from \(host) (attempt \(attempts))")
                    return ["SOURCE: \(url.absoluteString)\n\(text)"]
                }
                // A readable page with no table won't change on retry.
                if !text.lowercased().contains("could not") && !text.lowercased().contains("cannot") { break }
            }
        }
        print("🔧 [AIAnalyzer] No dealer milestone table found after \(attempts) reads")
        return []
    }

    private static func fetchOEMSchedule(vehicle: Vehicle) async throws -> OEMScheduleResponse {
        let notes = await researchSchedule(vehicle: vehicle)

        var requestBody: [String: Any] = [
            "model": "sonar-pro",
            "messages": [
                ["role": "system", "content": oemSystemPrompt],
                ["role": "user", "content": buildOEMUserPrompt(vehicle: vehicle, researchNotes: notes)]
            ],
            "temperature": 0.1,
            // A full schedule runs to ~25 items; 4,096 tokens cut the JSON off mid-string.
            "max_tokens": 8192
        ]
        // Step 2 only converts the notes into the structure — no need to search again.
        if notes != nil { requestBody["disable_search"] = true }

        // Writing ~25 items of JSON can take well over a minute.
        let reply = try await callPerplexityAPI(body: requestBody, timeout: 180)
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

            // Schedule shape with gaps filled: months-only intervals converted to miles,
            // and a typical interval when the OEM gives none (Maintenance Minder cars).
            let scheduleItem = oemItemToScheduleInput(oemItem, vehicle: vehicle)
            let interval = scheduleItem.resolvedIntervalMiles ?? 0

            let history = categoryToHistory[oemItem.category]
            let answer = history.flatMap { answers[$0.answerKey] }
            let lastMileage = history?.lastMileage

            if interval > 0, let lastMileage {
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
            } else if interval > 0, let answer, answer != "unknown" {
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
                // No usable history: place the item on its schedule. It only counts as
                // overdue if we asked about this kind of service, the user didn't know,
                // and a scheduled occurrence has already passed. A one-time item that
                // isn't due yet (spark plugs at 105k on a 56k car) is on track.
                let result = MaintenanceScheduleMath.scheduleStatus(
                    for: scheduleItem,
                    currentMileage: currentMileage,
                    historyUnknown: history != nil
                )
                items.append(makeItem(
                    oemItem: oemItem, vehicle: vehicle, status: result.status,
                    dueMileage: result.dueMileage, description: result.description
                ))
            }
        }

        return items
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

    /// Calls Perplexity with a streamed reply. Streaming keeps bytes flowing while a long
    /// answer is written — a non-streamed request sits silent for a minute or more and the
    /// connection gets dropped. `timeout` is the longest allowed gap between bytes.
    private static func callPerplexityAPI(body: [String: Any], timeout: TimeInterval) async throws -> PerplexityReply {
        var body = body
        body["stream"] = true
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.timeoutInterval = timeout
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        print("🔧 [AIAnalyzer] Calling Perplexity API...")
        let callStart = Date()
        // A fresh session per call: reusing the shared pooled connection for these long
        // requests stalled after the first call (status 200, then no bytes) or dropped it.
        let session = URLSession(configuration: .ephemeral)
        defer { session.finishTasksAndInvalidate() }
        let (bytes, response) = try await session.bytes(for: request)

        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        print("🔧 [AIAnalyzer] Response status: \(statusCode)")
        if statusCode != 200 {
            var errorBody = ""
            for try await line in bytes.lines { errorBody += line }
            print("🔧 [AIAnalyzer] Error body: \(errorBody.prefix(500))")
            AnalyticsService.shared.track(.perplexityCallFailed(reason: "HTTP \(statusCode)"))
            throw AnalyzerError.apiError
        }

        var content = ""
        var citations: [String]?
        var searchResults: [ChatCompletionResponse.SearchResult]?
        let decoder = JSONDecoder()
        for try await line in bytes.lines {
            guard line.hasPrefix("data:") else { continue }
            let payload = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
            if payload == "[DONE]" { break }
            guard let chunk = try? decoder.decode(StreamChunk.self, from: Data(payload.utf8)) else { continue }
            content += chunk.choices?.first?.delta?.content ?? ""
            if let c = chunk.citations, !c.isEmpty { citations = c }
            if let r = chunk.search_results, !r.isEmpty { searchResults = r }
        }
        let durationMs = Int(Date().timeIntervalSince(callStart) * 1000)

        guard !content.isEmpty else {
            print("🔧 [AIAnalyzer] No content in response")
            AnalyticsService.shared.track(.perplexityCallFailed(reason: "no content in response"))
            throw AnalyzerError.invalidResponse
        }

        AnalyticsService.shared.track(.perplexityCallSucceeded(durationMs: durationMs))
        print("🔧 [AIAnalyzer] ═══════════ EXTRACTED CONTENT (\(durationMs) ms) ═══════════")
        print(content)
        print("🔧 [AIAnalyzer] ═══════════ END CONTENT ═══════════")
        return PerplexityReply(
            content: content,
            citations: sourcesFromCitations(searchResults: searchResults, citations: citations)
        )
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
    When research notes are provided, build the schedule from them and do not search again. \
    If you cannot access a PDF, use dealer websites, KBB, Youtube, Edmunds, RepairPal, \
    manufacturer service bulletins, and enthusiast forums to compile the schedule. \
    The maintenance intervals for popular vehicles are widely published across \
    many sources — you do not need the PDF to answer this.
    """

    // MARK: - User Prompts

    private static func buildOEMUserPrompt(vehicle: Vehicle, researchNotes: String? = nil) -> String {
        let notesSection: String = researchNotes.map {
            """

            RESEARCH NOTES — already gathered from the pages listed below. Build the schedule \
            from these notes and do not search again. List the pages that supplied mileages \
            in "sources" (keep their URLs). If the notes contain DEALER PAGE EXTRACTS, those \
            were read directly from the page: take every mileage from them exactly — an item's \
            first due mileage is the first milestone it appears at, and its repeat interval is \
            the gap between the milestones it appears at (e.g. listed at 15k, 45k, 75k, 105k → \
            first 15,000, every 30,000; listed at 30k, 60k, 90k → first 30,000, every 30,000). \
            An item listed at two or more milestones is ALWAYS "recurring", never "one_time". \
            The extracts may come from several pages: give ONE item per service — merge \
            "Inspect brake lines" and "Brake hoses and lines", "Replace air filter" and \
            "Engine air filter", and so on — keeping the most complete milestone list. \
            Use the rest of the notes only for items the extracts do not cover. If notes \
            conflict elsewhere, prefer the dealer page.

            \($0)

            """
        } ?? ""
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

        \(notesSection)
        Find the official manufacturer warranty & maintenance guide for this exact vehicle.
        Cross-reference at least 2-3 sources. Prioritize in this order:
        1. Official OEM owner's manual or warranty & maintenance guide PDF
        2. Official dealer maintenance schedule pages
        3. Specialist repair sites (e.g. Firestone, RepairPal)
        4. Enthusiast forums that reference the actual owner's manual intervals

        Use the actual published schedule — do NOT invent intervals. If sources conflict,
        prefer the official OEM manual over dealer pages, and dealer pages over forums —
        EXCEPT for mileage numbers when the manual has none (see CONDITION-BASED CARS below).

        CONDITION-BASED CARS (Honda/Acura "Maintenance Minder", GM "Oil Life Monitor",
        BMW "Condition Based Service", etc.): the owner's manual often gives only dashboard
        codes and NO fixed mileages. That does NOT mean there are no mileages. Dealers and
        specialist sites publish the same schedule as a MILESTONE TABLE
        ("7,500 miles: oil, tire rotation… 15,000 miles: … 30,000 miles: …"). When the manual
        has no mileage for an item you MUST search for and read such a dealer or specialist
        milestone table for this vehicle, and take the mileages from it. Do not stop at the
        manual. Cite the dealer/specialist page in "sources".

        IMPORTANT: The OUTPUT must be a FLAT LIST OF MAINTENANCE ITEMS, each returned ONCE with
        its recurrence pattern — never as milestone snapshots. You MAY read milestone tables
        as input, but you must convert them into recurrence. Work out each item's cycle from
        every milestone where it appears:
        - oil + tire rotation at 7,500, 15,000, 22,500… → "recurring", interval 7,500
        - rear differential fluid at 15,000, 45,000, 75,000, 105,000 →
          "recurring_after_first", first_due 15,000, subsequent interval 30,000
        - brake fluid at 45,000 and 90,000 → "recurring", interval 45,000
        - transmission fluid at 60,000 only → "one_time" at 60,000 (or "recurring" if the
          source says it repeats)
        - timing belt at 105,000 only → "one_time" at 105,000
        Only use a mileage that a source actually states or that follows directly from the
        milestone table. NEVER make up a mileage. If, after checking dealer/specialist pages,
        an item truly has no mileage anywhere, leave both interval fields null and say in
        "notes" that it is condition-based and follows the dashboard reminder.

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
        - Every mileage must come from a source you cite. Prefer a result with real numbers
          from a dealer or specialist milestone table over a null.
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

    private static func oemItemToScheduleInput(_ item: OEMMaintenanceItem, vehicle: Vehicle) -> OEMScheduleItemInput {
        // Time-only intervals ("every 3 years") become miles using the owner's yearly mileage.
        let milesPerMonth = Double(MileageReminder.annualMiles(for: vehicle)) / 12
        func miles(fromMonths months: Int?) -> Int? {
            guard let months, months > 0 else { return nil }
            return max(5_000, Int((Double(months) * milesPerMonth / 5_000).rounded()) * 5_000)
        }
        func positive(_ value: Int?) -> Int? { (value ?? 0) > 0 ? value : nil }

        return OEMScheduleItemInput.make(
            name: item.name,
            action: item.action,
            category: item.category,
            type: item.type,
            intervalMiles: positive(item.interval_miles) ?? miles(fromMonths: item.interval_months),
            firstDueMiles: positive(item.first_due_miles) ?? miles(fromMonths: item.first_due_months),
            subsequentIntervalMiles: positive(item.subsequent_interval_miles)
                ?? miles(fromMonths: item.subsequent_interval_months),
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

import Foundation

/// Bridges CarAPI → UI with caching and fallback to VehicleDatabase.
@Observable
class VehicleLookupManager {

    // MARK: - Data

    var makes: [String] = []
    var models: [String] = []
    var trims: [String] = []
    var vinResult: CarAPIService.VINDecodeResult?

    // MARK: - Loading States

    var isLoadingMakes = false
    var isLoadingModels = false
    var isLoadingTrims = false
    var isDecodingVIN = false

    // MARK: - Error States

    var vinError: String?
    var vinSuccess: String?

    // MARK: - Cache Keys

    private static let makesCacheKey = "carapi_makes_cache"
    private static let makesCacheDateKey = "carapi_makes_cache_date"
    private static let cacheTTL: TimeInterval = 30 * 24 * 60 * 60 // 30 days

    // In-memory caches
    private var modelsCache: [String: [String]] = [:] // "make-year" → models
    private var trimsCache: [String: [String]] = [:]  // "make-model-year" → trims

    // The most recent request. Switching make/model quickly starts overlapping
    // fetches; a slower, older reply must not overwrite the current list.
    private var latestModelsKey: String?
    private var latestTrimsKey: String?

    // MARK: - Popular Makes (shown first)

    private static let popularMakes: Set<String> = [
        "Acura", "Alfa Romeo", "Aston Martin", "Audi", "Bentley", "BMW", "Buick",
        "Cadillac", "Chevrolet", "Chrysler", "Dodge", "Ferrari", "Fiat", "Ford",
        "Genesis", "GMC", "Honda", "Hyundai", "Infiniti", "Jaguar", "Jeep", "Kia",
        "Lamborghini", "Land Rover", "Lexus", "Lincoln", "Lucid", "Maserati",
        "Mazda", "McLaren", "Mercedes-Benz", "Mini", "Mitsubishi", "Nissan",
        "Polestar", "Porsche", "Ram", "Rivian", "Rolls-Royce", "Subaru",
        "Tesla", "Toyota", "Volkswagen", "Volvo"
    ]

    // MARK: - Load Makes

    func loadMakes(year: Int? = nil) async {
        // Check cache first (only for non-year-filtered requests)
        if year == nil, let cached = loadMakesFromCache() {
            makes = cached
            return
        }

        isLoadingMakes = true
        defer { isLoadingMakes = false }

        do {
            let fetched = try await CarAPIService.fetchMakes(year: year)
            // Free CarAPI plan only covers 2015–2020; an empty list means "no data", not "no makes".
            guard !fetched.isEmpty else {
                makes = VehicleDatabase.makes
                return
            }
            // Sort: popular makes first, then alphabetical
            makes = sortWithPopularFirst(fetched)

            // Cache if no year filter
            if year == nil {
                saveMakesToCache(fetched)
            }
        } catch {
            print("🚗 [Lookup] Makes fetch failed, using fallback: \(error.localizedDescription)")
            makes = VehicleDatabase.makes
        }
    }

    // MARK: - Load Models

    func loadModels(make: String, year: Int) async {
        let cacheKey = "\(make)-\(year)"
        latestModelsKey = cacheKey
        if let cached = modelsCache[cacheKey] {
            models = cached
            isLoadingModels = false
            return
        }

        isLoadingModels = true
        defer { if latestModelsKey == cacheKey { isLoadingModels = false } }

        do {
            let fetched = try await CarAPIService.fetchModels(make: make, year: year)
            guard latestModelsKey == cacheKey else {
                if !fetched.isEmpty { modelsCache[cacheKey] = fetched }
                return
            }
            guard !fetched.isEmpty else {
                // Outside the plan's years (or unknown make): use the bundled list.
                models = VehicleDatabase.models[make] ?? []
                return
            }
            models = fetched
            modelsCache[cacheKey] = fetched
        } catch {
            print("🚗 [Lookup] Models fetch failed, using fallback: \(error.localizedDescription)")
            guard latestModelsKey == cacheKey else { return }
            models = VehicleDatabase.models[make] ?? []
        }
    }

    // MARK: - Load Trims

    func loadTrims(make: String, model: String, year: Int) async {
        let cacheKey = "\(make)-\(model)-\(year)"
        latestTrimsKey = cacheKey
        if let cached = trimsCache[cacheKey] {
            trims = cached
            isLoadingTrims = false
            return
        }

        isLoadingTrims = true
        defer { if latestTrimsKey == cacheKey { isLoadingTrims = false } }

        do {
            let fetched = try await CarAPIService.fetchTrims(make: make, model: model, year: year)
            guard latestTrimsKey == cacheKey else {
                if !fetched.isEmpty { trimsCache[cacheKey] = fetched }
                return
            }
            guard !fetched.isEmpty else {
                trims = VehicleDatabase.trimsFor(make: make, model: model)
                return
            }
            trims = fetched
            trimsCache[cacheKey] = fetched
        } catch {
            print("🚗 [Lookup] Trims fetch failed, using fallback: \(error.localizedDescription)")
            guard latestTrimsKey == cacheKey else { return }
            trims = VehicleDatabase.trimsFor(make: make, model: model)
        }
    }

    // MARK: - VIN Decode

    func decodeVIN(_ vin: String) async {
        vinError = nil
        vinSuccess = nil
        vinResult = nil

        guard vin.count == 17 else {
            vinError = "VIN must be exactly 17 characters"
            return
        }

        isDecodingVIN = true
        defer { isDecodingVIN = false }

        do {
            let result = try await NHTSAVINService.decodeVIN(vin)
            vinResult = result
            vinSuccess = "Found: \(result.year) \(result.make) \(result.model) \(result.trim ?? "")"
        } catch {
            print("🚗 [Lookup] VIN decode failed: \(error.localizedDescription)")
            vinError = "Couldn't decode this VIN. You can enter details manually."
        }
    }

    // MARK: - Cache Helpers

    private func loadMakesFromCache() -> [String]? {
        guard let date = UserDefaults.standard.object(forKey: Self.makesCacheDateKey) as? Date,
              Date().timeIntervalSince(date) < Self.cacheTTL,
              let data = UserDefaults.standard.data(forKey: Self.makesCacheKey),
              let cached = try? JSONDecoder().decode([String].self, from: data) else {
            return nil
        }
        return sortWithPopularFirst(cached)
    }

    private func saveMakesToCache(_ makes: [String]) {
        if let data = try? JSONEncoder().encode(makes) {
            UserDefaults.standard.set(data, forKey: Self.makesCacheKey)
            UserDefaults.standard.set(Date(), forKey: Self.makesCacheDateKey)
        }
    }

    private func sortWithPopularFirst(_ makes: [String]) -> [String] {
        let popular = makes.filter { Self.popularMakes.contains($0) }.sorted()
        let others = makes.filter { !Self.popularMakes.contains($0) }.sorted()
        return popular + others
    }
}

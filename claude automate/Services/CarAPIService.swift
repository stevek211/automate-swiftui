import Foundation

/// Client for CarAPI.app — provides make/model/trim browsing and VIN decoding.
enum CarAPIService {

    // MARK: - Configuration

    /// Credentials from Secrets.swift (gitignored)
    private static let apiToken = Secrets.carAPIToken
    private static let apiSecret = Secrets.carAPISecret
    private static let baseURL = "https://carapi.app/api"

    // MARK: - JWT State

    private static var jwt: String?
    private static var jwtExpiry: Date?

    // MARK: - Response Models

    struct VINDecodeResult {
        let year: Int
        let make: String
        let model: String
        let trim: String?
        let engine: String?
        let transmission: String?
        let driveType: String?
    }

    private struct AuthResponse: Decodable {
        // The login endpoint returns a plain JWT string
    }

    private struct PaginatedResponse<T: Decodable>: Decodable {
        let data: [T]
        let collection: CollectionMeta?
    }

    private struct CollectionMeta: Decodable {
        let total: Int?
        let count: Int?
        let pages: Int?
        let next: String?
    }

    private struct MakeItem: Decodable {
        let id: Int
        let name: String
    }

    private struct ModelItem: Decodable {
        let id: Int
        let name: String
        let make_id: Int?
    }

    /// `/trims/v2` item: the trim name is in `trim` (falls back to `submodel`).
    private struct TrimItem: Decodable {
        let id: Int
        let trim: String?
        let submodel: String?
        let year: Int?
        let description: String?

        var displayName: String? {
            let value = (trim?.isEmpty == false ? trim : submodel)?
                .trimmingCharacters(in: .whitespaces)
            return value?.isEmpty == false ? value : nil
        }
    }

    // MARK: - Authentication

    /// Authenticates with CarAPI and caches the JWT (7-day expiry).
    static func authenticate() async throws {
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            throw CarAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        let body: [String: String] = [
            "api_token": apiToken,
            "api_secret": apiSecret
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("🚗 [CarAPI] Auth failed with status \(statusCode)")
            throw CarAPIError.authFailed
        }

        // Response is a plain JWT string
        guard let token = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines.union(.init(charactersIn: "\""))) else {
            throw CarAPIError.authFailed
        }

        jwt = token
        // JWT expires in 7 days, refresh a bit early
        jwtExpiry = Date().addingTimeInterval(6 * 24 * 60 * 60)
        print("🚗 [CarAPI] Authenticated successfully")
    }

    /// Ensures we have a valid JWT, refreshing if needed.
    private static func ensureAuth() async throws {
        if let expiry = jwtExpiry, Date() < expiry, jwt != nil {
            return // Still valid
        }
        try await authenticate()
    }

    /// Creates an authenticated GET request.
    private static func authenticatedRequest(url: URL) async throws -> URLRequest {
        try await ensureAuth()
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(jwt ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15
        return request
    }

    // MARK: - Public API

    /// Fetch all makes, optionally filtered by year.
    static func fetchMakes(year: Int? = nil) async throws -> [String] {
        var components = URLComponents(string: "\(baseURL)/makes/v2")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: "1000")
        ]
        if let year {
            queryItems.append(URLQueryItem(name: "year", value: "\(year)"))
        }
        components.queryItems = queryItems

        guard let url = components.url else { throw CarAPIError.invalidURL }

        let request = try await authenticatedRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("🚗 [CarAPI] fetchMakes failed with status \(statusCode)")
            throw CarAPIError.requestFailed
        }

        let result = try JSONDecoder().decode(PaginatedResponse<MakeItem>.self, from: data)
        let makes = Array(Set(result.data.map(\.name))).sorted()
        print("🚗 [CarAPI] Fetched \(makes.count) makes")
        return makes
    }

    /// Fetch models for a given make and year.
    static func fetchModels(make: String, year: Int) async throws -> [String] {
        var components = URLComponents(string: "\(baseURL)/models/v2")!
        components.queryItems = [
            URLQueryItem(name: "make", value: make),
            URLQueryItem(name: "year", value: "\(year)"),
            URLQueryItem(name: "limit", value: "1000")
        ]

        guard let url = components.url else { throw CarAPIError.invalidURL }

        let request = try await authenticatedRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("🚗 [CarAPI] fetchModels failed with status \(statusCode)")
            throw CarAPIError.requestFailed
        }

        let result = try JSONDecoder().decode(PaginatedResponse<ModelItem>.self, from: data)
        // Deduplicate model names (API may return duplicates for different body styles)
        let models = Array(Set(result.data.map(\.name))).sorted()
        print("🚗 [CarAPI] Fetched \(models.count) models for \(make) \(year)")
        return models
    }

    /// Fetch trims for a given make, model, and year.
    static func fetchTrims(make: String, model: String, year: Int) async throws -> [String] {
        var components = URLComponents(string: "\(baseURL)/trims/v2")!
        components.queryItems = [
            URLQueryItem(name: "make", value: make),
            URLQueryItem(name: "model", value: model),
            URLQueryItem(name: "year", value: "\(year)"),
            URLQueryItem(name: "limit", value: "1000")
        ]

        guard let url = components.url else { throw CarAPIError.invalidURL }

        let request = try await authenticatedRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("🚗 [CarAPI] fetchTrims failed with status \(statusCode)")
            throw CarAPIError.requestFailed
        }

        let result = try JSONDecoder().decode(PaginatedResponse<TrimItem>.self, from: data)
        let trims = Array(Set(result.data.compactMap(\.displayName))).sorted()
        print("🚗 [CarAPI] Fetched \(trims.count) trims for \(year) \(make) \(model)")
        return trims
    }

    /// Decode a VIN to get vehicle details.
    static func decodeVIN(_ vin: String) async throws -> VINDecodeResult {
        guard let url = URL(string: "\(baseURL)/vin/\(vin)") else {
            throw CarAPIError.invalidURL
        }

        let request = try await authenticatedRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            let body = String(data: data, encoding: .utf8) ?? ""
            print("🚗 [CarAPI] decodeVIN failed with status \(statusCode): \(body)")
            throw CarAPIError.vinDecodeFailed
        }

        // Parse the VIN response — structure varies, extract key fields
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CarAPIError.invalidResponse
        }

        let year = json["year"] as? Int ?? 0
        let rawMake = json["make"] as? String ?? ""
        let make = rawMake.capitalized  // "TOYOTA" → "Toyota", "MERCEDES-BENZ" → "Mercedes-Benz"
        let model = json["model"] as? String ?? ""
        let rawTrim = json["trim"] as? String
        // Filter out chassis codes (e.g. "ASV50L/GSV50L/AVV50L") — keep only human-readable trims
        let trim: String? = {
            guard let t = rawTrim, !t.isEmpty else { return nil }
            // Chassis codes typically contain slashes or are long alphanumeric codes
            if t.contains("/") { return nil }
            // Chassis codes like "ASV50L" — mix of letters and digits, 5+ chars, no spaces
            if t.count >= 5, !t.contains(" "), t.range(of: "^[A-Z0-9]+$", options: .regularExpression) != nil {
                return nil
            }
            return t
        }()
        let engine = json["engine"] as? String
        let transmission = json["transmission"] as? String
        let driveType = json["drive_type"] as? String

        guard !make.isEmpty, !model.isEmpty, year > 0 else {
            print("🚗 [CarAPI] VIN decode returned incomplete data")
            throw CarAPIError.vinDecodeFailed
        }

        print("🚗 [CarAPI] VIN decoded: \(year) \(make) \(model) \(trim ?? "")")
        return VINDecodeResult(
            year: year,
            make: make,
            model: model,
            trim: trim,
            engine: engine,
            transmission: transmission,
            driveType: driveType
        )
    }

    // MARK: - Errors

    enum CarAPIError: LocalizedError {
        case invalidURL
        case authFailed
        case requestFailed
        case invalidResponse
        case vinDecodeFailed

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid API URL"
            case .authFailed: return "CarAPI authentication failed"
            case .requestFailed: return "CarAPI request failed"
            case .invalidResponse: return "Could not parse CarAPI response"
            case .vinDecodeFailed: return "Could not decode VIN"
            }
        }
    }
}

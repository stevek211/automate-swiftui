import Foundation

// MARK: - String helper for vehicle name casing

private extension String {
    /// Brands that should stay fully uppercased.
    static let allCapsBrands: Set<String> = [
        "BMW", "GMC", "MINI", "VW", "RAM", "KIA", "BYD", "GAC",
        "MG", "GEO", "AM", "SRT", "HSV", "FPV", "SSC", "TVR"
    ]

    /// Title-cases a vehicle make/model string while preserving known all-caps brands.
    var vehicleTitleCased: String {
        let upper = self.uppercased()
        if String.allCapsBrands.contains(upper) { return upper }
        // Word-by-word: keep known acronyms uppercased, title-case the rest
        return self.capitalized.components(separatedBy: " ").map { word in
            String.allCapsBrands.contains(word.uppercased()) ? word.uppercased() : word
        }.joined(separator: " ")
    }
}

/// Free VIN decoder using NHTSA's vPIC API.
/// No auth, no rate limits, covers all model years (including 2023+).
/// Endpoint: https://vpic.nhtsa.dot.gov/api/vehicles/decodevinvalues/{VIN}?format=json
enum NHTSAVINService {

    private static let baseURL = "https://vpic.nhtsa.dot.gov/api/vehicles/decodevinvalues"

    // MARK: - Raw NHTSA response

    private struct NHTSAResponse: Decodable {
        let Results: [NHTSAResult]
    }

    private struct NHTSAResult: Decodable {
        let ModelYear: String?
        let Make: String?
        let Model: String?
        let Trim: String?
        let Trim2: String?
        let Series: String?
        let EngineModel: String?
        let DisplacementL: String?
        let EngineCylinders: String?
        let FuelTypePrimary: String?
        let TransmissionStyle: String?
        let TransmissionSpeeds: String?
        let DriveType: String?
        let ErrorCode: String?
        let ErrorText: String?
    }

    // MARK: - Public API

    /// Decode a VIN using NHTSA. Returns the same struct shape as CarAPIService
    /// so callers don't need to change.
    static func decodeVIN(_ vin: String) async throws -> CarAPIService.VINDecodeResult {
        let trimmed = vin.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard trimmed.count == 17 else {
            throw NHTSAError.invalidVIN
        }

        guard let url = URL(string: "\(baseURL)/\(trimmed)?format=json") else {
            throw NHTSAError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("🚗 [NHTSA] decodeVIN failed with status \(statusCode)")
            throw NHTSAError.requestFailed
        }

        let decoded = try JSONDecoder().decode(NHTSAResponse.self, from: data)
        guard let result = decoded.Results.first else {
            throw NHTSAError.vinDecodeFailed
        }

        // NHTSA ErrorCode "0" means success. Anything else is partial or failed.
        // We still try to use the data if core fields exist.
        let errorCode = result.ErrorCode ?? ""
        if !errorCode.hasPrefix("0") {
            print("🚗 [NHTSA] ErrorCode=\(errorCode) Text=\(result.ErrorText ?? "")")
        }

        guard
            let yearStr = result.ModelYear, let year = Int(yearStr), year > 0,
            let rawMake = result.Make, !rawMake.isEmpty,
            let rawModel = result.Model, !rawModel.isEmpty
        else {
            print("🚗 [NHTSA] VIN decode returned incomplete data")
            throw NHTSAError.vinDecodeFailed
        }

        let make = rawMake.vehicleTitleCased
        let model = rawModel.vehicleTitleCased

        // Prefer Trim, fall back to Trim2, then Series
        let rawTrim = [result.Trim, result.Trim2, result.Series]
            .compactMap { $0?.trimmingCharacters(in: .whitespaces) }
            .first { !$0.isEmpty }

        // Reuse chassis-code filtering logic from CarAPIService
        let trim: String? = {
            guard let t = rawTrim, !t.isEmpty else { return nil }
            if t.contains("/") { return nil }
            let upper = t.uppercased()
            if upper.count >= 5, !upper.contains(" "), upper.range(of: "^[A-Z0-9]+$", options: .regularExpression) != nil {
                return nil
            }
            return t
        }()

        // Build engine description: "2.5L 4-cyl" style if available, else raw EngineModel
        let engine: String? = {
            var parts: [String] = []
            if let disp = result.DisplacementL, let d = Double(disp) {
                parts.append(String(format: "%.1fL", d))
            }
            if let cyl = result.EngineCylinders, !cyl.isEmpty {
                parts.append("\(cyl)-cyl")
            }
            if let fuel = result.FuelTypePrimary, !fuel.isEmpty, fuel.lowercased() != "gasoline" {
                parts.append(fuel)
            }
            if !parts.isEmpty { return parts.joined(separator: " ") }
            return result.EngineModel?.isEmpty == false ? result.EngineModel : nil
        }()

        let transmission: String? = {
            var parts: [String] = []
            if let speeds = result.TransmissionSpeeds, !speeds.isEmpty {
                parts.append("\(speeds)-spd")
            }
            if let style = result.TransmissionStyle, !style.isEmpty {
                parts.append(style)
            }
            return parts.isEmpty ? nil : parts.joined(separator: " ")
        }()

        let driveType = result.DriveType?.isEmpty == false ? result.DriveType : nil

        print("🚗 [NHTSA] VIN decoded: \(year) \(make) \(model) \(trim ?? "")")
        return CarAPIService.VINDecodeResult(
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

    enum NHTSAError: LocalizedError {
        case invalidVIN
        case invalidURL
        case requestFailed
        case vinDecodeFailed

        var errorDescription: String? {
            switch self {
            case .invalidVIN: return "VIN must be 17 characters"
            case .invalidURL: return "Invalid NHTSA URL"
            case .requestFailed: return "NHTSA request failed"
            case .vinDecodeFailed: return "Could not decode VIN"
            }
        }
    }
}

import Foundation

/// Constructs URLs for the IMAGIN.studio CDN vehicle image API.
/// No SDK, no auth header — just a URL with query parameters.
/// Uses `customer=img` (free demo key) for MVP.
enum VehicleImageService {

    /// Returns a URL for a stock photo of the given vehicle.
    /// - Parameters:
    ///   - make: Vehicle manufacturer (e.g. "Honda", "Toyota")
    ///   - model: Vehicle model (e.g. "CR-V", "Camry Hybrid")
    ///   - year: Model year (e.g. 2021)
    ///   - color: Vehicle color string (e.g. "White", "Midnight Blue") — mapped to IMAGIN paint ID
    ///   - angle: Camera angle, default "01" (front 3/4 view). "21" is a side profile, nose left.
    ///   - tightCrop: Adds `zoomType=fullscreen` so the car fills the image edge-to-edge.
    ///   - width: Optional output width in pixels.
    /// - Returns: A fully-formed IMAGIN.studio CDN URL, or nil if encoding fails.
    static func vehicleImageURL(
        make: String,
        model: String,
        year: Int,
        color: String? = nil,
        angle: String = "01",
        tightCrop: Bool = false,
        width: Int? = nil
    ) -> URL? {
        let resolvedMake = resolveParam(make)
        let resolvedModel = resolveModelFamily(model)

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "customer", value: "img"),
            URLQueryItem(name: "make", value: resolvedMake),
            URLQueryItem(name: "modelFamily", value: resolvedModel),
            URLQueryItem(name: "modelYear", value: String(year)),
            URLQueryItem(name: "angle", value: angle),
        ]

        // Add paint color if we can map it
        if let color, let paintId = resolvePaintId(color) {
            queryItems.append(URLQueryItem(name: "paintId", value: paintId))
        }

        // Crop whitespace so the car fills the frame edge-to-edge.
        if tightCrop {
            queryItems.append(URLQueryItem(name: "zoomType", value: "fullscreen"))
        }
        if let width {
            queryItems.append(URLQueryItem(name: "width", value: String(width)))
        }

        var components = URLComponents(string: "https://cdn.imagin.studio/getimage")
        components?.queryItems = queryItems
        return components?.url
    }

    // MARK: - Color mapping

    /// Maps plain-English color names to IMAGIN.studio paintId values.
    /// IMAGIN always returns HTTP 200 — unknown paint IDs just show default color.
    private static func resolvePaintId(_ color: String) -> String? {
        let normalized = color.lowercased().trimmingCharacters(in: .whitespaces)

        // Exact and partial keyword matches → IMAGIN paint IDs
        let mapping: [(keywords: [String], paintId: String)] = [
            (["white", "pearl", "ivory"],                   "white"),
            (["black", "ebony", "obsidian", "jet"],         "black"),
            (["silver", "sterling", "platinum", "chrome"],  "silver"),
            (["gray", "grey", "charcoal", "graphite"],      "gray"),
            (["red", "crimson", "cherry", "scarlet"],       "red"),
            (["blue", "navy", "sapphire", "cobalt"],        "blue"),
            (["green", "forest", "olive", "sage"],          "green"),
            (["brown", "bronze", "copper", "mocha"],        "brown"),
            (["gold", "golden", "champagne", "sand"],       "gold"),
            (["orange", "amber", "tangerine"],              "orange"),
            (["yellow", "lemon"],                           "yellow"),
            (["purple", "violet", "plum"],                  "purple"),
            (["beige", "cream", "tan", "khaki"],            "beige"),
        ]

        for entry in mapping {
            if entry.keywords.contains(where: { normalized.contains($0) }) {
                return entry.paintId
            }
        }

        return nil // Let IMAGIN use its default color
    }

    // MARK: - String helpers

    /// Lowercases and trims whitespace.
    private static func resolveParam(_ value: String) -> String {
        value.lowercased().trimmingCharacters(in: .whitespaces)
    }

    /// Resolves a model name into the IMAGIN.studio `modelFamily` format.
    ///
    /// Examples:
    ///   "CR-V"           → "cr-v"
    ///   "Camry Hybrid"   → "camry-hybrid"
    ///   "Model 3"        → "model-3"
    ///   "Grand Cherokee" → "grand-cherokee"
    ///   "F-150"          → "f-150"
    ///   "RAV4"           → "rav4"
    static func resolveModelFamily(_ model: String) -> String {
        model
            .lowercased()
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "\\s+", with: "-", options: .regularExpression)
            .replacingOccurrences(of: "[^a-z0-9\\-]", with: "", options: .regularExpression)
    }
}

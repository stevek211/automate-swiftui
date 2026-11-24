import SwiftUI

// MARK: - Palettes
//
// Every color in the app comes from one of these roles. To try your own palette:
//   1. Copy one of the blocks below (e.g. `static let slateBlue = Palette(...)`).
//   2. Give it a new variable name and `name:`, then paste in your hex codes.
//   3. Add it to `Palette.all` at the bottom of this section and rebuild.
// It then shows up under Settings → Debug → Color palette (debug builds only).
//
// What each role colors:
//   brand        – main buttons, selected tabs, links, progress, checkmarks
//   brandDeep    – darker brand for pressed/emphasis states and deep tints
//   secondary    – warm second color: health score, onboarding CTAs, decorative dots
//   accent       – small highlights (badges, chips)
//   heading      – large titles and key numbers (Home, Garage headings)
//   ink          – normal body text and icons
//   mutedText    – labels, captions, secondary text
//   faintText    – placeholders, disabled text, tertiary details
//   background   – page background behind cards
//   card         – cards, sheets, buttons on top of the background
//   surfaceAlt   – chips, segmented-control tracks, soft fills
//   border       – card and field outlines
//   borderStrong – stronger outlines (pills, stacked cards, toggles when off)
//   hairline     – thin dividers between rows
//   success / warning / danger – status colors (on track / due soon / overdue)

struct Palette: Identifiable, Equatable {
    let name: String
    let brand: Color
    let brandDeep: Color
    let secondary: Color
    let accent: Color
    let heading: Color
    let ink: Color
    let mutedText: Color
    let faintText: Color
    let background: Color
    let card: Color
    let surfaceAlt: Color
    let border: Color
    let borderStrong: Color
    let hairline: Color
    let success: Color
    let warning: Color
    let danger: Color

    var id: String { name }

    /// Today's look, merged from the per-screen palettes the app used before.
    static let current = Palette(
        name: "Current",
        brand: Color(hex: "227770"),
        brandDeep: Color(hex: "295350"),
        secondary: Color(hex: "B8735A"),
        accent: Color(hex: "CC8A14"),
        heading: Color(hex: "1E1A4D"),
        ink: Color(hex: "1F242E"),
        mutedText: Color(hex: "5F6676"),
        faintText: Color(hex: "99A1AF"),
        background: Color(hex: "F9F8F5"),
        card: Color(hex: "FFFFFF"),
        surfaceAlt: Color(hex: "F0EEEA"),
        border: Color(hex: "E5E2DC"),
        borderStrong: Color(hex: "C9C4BC"),
        hairline: Color(hex: "ECE9E4"),
        success: Color(hex: "3B8560"),
        warning: Color(hex: "CC8A14"),
        danger: Color(hex: "C73838")
    )

    static let slateBlue = Palette(
        name: "Slate Blue",
        brand: Color(hex: "3D5A98"),
        brandDeep: Color(hex: "263B66"),
        secondary: Color(hex: "D08C60"),
        accent: Color(hex: "E0A030"),
        heading: Color(hex: "1B2540"),
        ink: Color(hex: "1E2433"),
        mutedText: Color(hex: "5B6478"),
        faintText: Color(hex: "9AA3B5"),
        background: Color(hex: "F6F7FA"),
        card: Color(hex: "FFFFFF"),
        surfaceAlt: Color(hex: "ECEFF5"),
        border: Color(hex: "DFE3EB"),
        borderStrong: Color(hex: "C3C9D6"),
        hairline: Color(hex: "E9ECF2"),
        success: Color(hex: "2F8A5B"),
        warning: Color(hex: "D9921A"),
        danger: Color(hex: "C8403A")
    )

    static let forest = Palette(
        name: "Forest",
        brand: Color(hex: "2F6B3F"),
        brandDeep: Color(hex: "1F4A2B"),
        secondary: Color(hex: "A8743A"),
        accent: Color(hex: "C9962B"),
        heading: Color(hex: "1D2E22"),
        ink: Color(hex: "1F2A22"),
        mutedText: Color(hex: "5C6B60"),
        faintText: Color(hex: "9AA79D"),
        background: Color(hex: "F6F7F2"),
        card: Color(hex: "FFFFFF"),
        surfaceAlt: Color(hex: "ECEFE4"),
        border: Color(hex: "DFE3D6"),
        borderStrong: Color(hex: "C2C9B8"),
        hairline: Color(hex: "E8EBE1"),
        success: Color(hex: "3A8A4F"),
        warning: Color(hex: "C98A1B"),
        danger: Color(hex: "B9473C")
    )

    static let warmClay = Palette(
        name: "Warm Clay",
        brand: Color(hex: "B5573A"),
        brandDeep: Color(hex: "7E3A26"),
        secondary: Color(hex: "3F6E6A"),
        accent: Color(hex: "D9A441"),
        heading: Color(hex: "3A2218"),
        ink: Color(hex: "33261F"),
        mutedText: Color(hex: "76655B"),
        faintText: Color(hex: "A8998F"),
        background: Color(hex: "FAF6F1"),
        card: Color(hex: "FFFFFF"),
        surfaceAlt: Color(hex: "F2EAE0"),
        border: Color(hex: "E7DDD1"),
        borderStrong: Color(hex: "CDBFB0"),
        hairline: Color(hex: "EFE7DD"),
        success: Color(hex: "4E8A5A"),
        warning: Color(hex: "D08A1E"),
        danger: Color(hex: "B83B32")
    )

    // Your palettes. Each lists 5 source colors; roles they don't cover (body text,
    // borders, cards) are shades derived from them. Status colors stay the same as
    // Current so overdue / due soon / on track keep their meaning.

    /// Berry blush 8E5572 · mint cream F2F7F2 · dry sage C2B97F · khaki beige BCAA99 · smoky rose 88665D
    static let berryBlush = Palette(
        name: "Berry Blush",
        brand: Color(hex: "8E5572"),        // berry blush
        brandDeep: Color(hex: "6B3E55"),    // berry blush, darker
        secondary: Color(hex: "88665D"),    // smoky rose
        accent: Color(hex: "C2B97F"),       // dry sage
        heading: Color(hex: "4A2C3B"),      // berry blush, very dark
        ink: Color(hex: "3A2F2C"),          // smoky rose, very dark
        mutedText: Color(hex: "7A6A64"),    // smoky rose, muted (readable on mint cream)
        faintText: Color(hex: "BCAA99"),    // khaki beige
        background: Color(hex: "F2F7F2"),   // mint cream
        card: Color(hex: "FFFFFF"),
        surfaceAlt: Color(hex: "E6E3D9"),   // khaki beige, light
        border: Color(hex: "DDD8CC"),
        borderStrong: Color(hex: "BCAA99"), // khaki beige
        hairline: Color(hex: "E7E9E2"),
        success: Color(hex: "3B8560"),
        warning: Color(hex: "CC8A14"),
        danger: Color(hex: "C73838")
    )

    /// Graphite 353535 · white smoke F5F5F5 · pale slate D2D7DF · silver BDBBB0 · grey olive 969588
    static let graphite = Palette(
        name: "Graphite",
        brand: Color(hex: "353535"),        // graphite
        brandDeep: Color(hex: "1F1F1F"),    // graphite, darker
        secondary: Color(hex: "969588"),    // grey olive
        accent: Color(hex: "BDBBB0"),       // silver
        heading: Color(hex: "353535"),      // graphite
        ink: Color(hex: "353535"),          // graphite
        mutedText: Color(hex: "6E6D66"),    // grey olive, darker (readable on white smoke)
        faintText: Color(hex: "969588"),    // grey olive
        background: Color(hex: "F5F5F5"),   // white smoke
        card: Color(hex: "FFFFFF"),
        surfaceAlt: Color(hex: "E9EBEF"),   // pale slate, light
        border: Color(hex: "D2D7DF"),       // pale slate
        borderStrong: Color(hex: "BDBBB0"), // silver
        hairline: Color(hex: "E4E7EC"),
        success: Color(hex: "3B8560"),
        warning: Color(hex: "CC8A14"),
        danger: Color(hex: "C73838")
    )

    /// Taupe 463F3A · rosy granite 8C827D · silver BCB8B1 · parchment F4F3EE · powder blush E0AFA0
    static let parchment = Palette(
        name: "Parchment",
        brand: Color(hex: "463F3A"),        // taupe
        brandDeep: Color(hex: "2E2925"),    // taupe, darker
        secondary: Color(hex: "E0AFA0"),    // powder blush
        accent: Color(hex: "C9897A"),       // powder blush, deeper
        heading: Color(hex: "463F3A"),      // taupe
        ink: Color(hex: "2F2A27"),          // taupe, darker
        mutedText: Color(hex: "6F6661"),    // rosy granite, darker (readable on parchment)
        faintText: Color(hex: "8C827D"),    // rosy granite
        background: Color(hex: "F4F3EE"),   // parchment
        card: Color(hex: "FFFFFF"),
        surfaceAlt: Color(hex: "EAE7E0"),   // parchment, deeper
        border: Color(hex: "DDD9D1"),
        borderStrong: Color(hex: "BCB8B1"), // silver
        hairline: Color(hex: "E6E3DC"),
        success: Color(hex: "3B8560"),
        warning: Color(hex: "CC8A14"),
        danger: Color(hex: "C73838")
    )

    /// Burnt tangerine E3170A · spicy paprika E16036 · powder blush D6A99A · dust grey D6CBC1 · dust grey 2 CDD6D0
    static let tangerine = Palette(
        name: "Tangerine",
        brand: Color(hex: "E3170A"),        // burnt tangerine
        brandDeep: Color(hex: "A8120A"),    // burnt tangerine, darker
        secondary: Color(hex: "E16036"),    // spicy paprika
        accent: Color(hex: "D6A99A"),       // powder blush
        heading: Color(hex: "3A1A14"),      // burnt tangerine, very dark
        ink: Color(hex: "2E2420"),
        mutedText: Color(hex: "6E625A"),    // dust grey, darker (readable)
        faintText: Color(hex: "A2968C"),    // dust grey, mid
        background: Color(hex: "F6F2EE"),   // dust grey, very light
        card: Color(hex: "FFFFFF"),
        surfaceAlt: Color(hex: "ECE5DF"),   // dust grey, light
        border: Color(hex: "D6CBC1"),       // dust grey
        borderStrong: Color(hex: "BFB3A8"),
        hairline: Color(hex: "CDD6D0"),     // dust grey 2
        success: Color(hex: "3B8560"),
        warning: Color(hex: "CC8A14"),
        danger: Color(hex: "C73838")
    )

    /// F2F1ED · FEB546 · B9B5AC
    /// Amber is too light for white button text, so buttons use a dark warm brown and amber is the highlight color.
    static let amberStone = Palette(
        name: "Amber Stone",
        brand: Color(hex: "3A362F"),        // stone, very dark
        brandDeep: Color(hex: "24211C"),
        secondary: Color(hex: "FEB546"),    // amber
        accent: Color(hex: "FEB546"),       // amber
        heading: Color(hex: "2F2D29"),
        ink: Color(hex: "2F2D29"),
        mutedText: Color(hex: "6B675F"),    // stone, darker (readable)
        faintText: Color(hex: "B9B5AC"),    // stone
        background: Color(hex: "F2F1ED"),   // off-white
        card: Color(hex: "FFFFFF"),
        surfaceAlt: Color(hex: "E7E5DF"),
        border: Color(hex: "DCD9D2"),
        borderStrong: Color(hex: "B9B5AC"), // stone
        hairline: Color(hex: "E6E4DE"),
        success: Color(hex: "3B8560"),
        warning: Color(hex: "CC8A14"),
        danger: Color(hex: "C73838")
    )

    /// Dusk blue 464D77 · teal 36827F · royal gold F9DB6D · snow F4EDED · dusty taupe 877666
    static let dusk = Palette(
        name: "Dusk",
        brand: Color(hex: "464D77"),        // dusk blue
        brandDeep: Color(hex: "30365A"),    // dusk blue, darker
        secondary: Color(hex: "36827F"),    // teal
        accent: Color(hex: "F9DB6D"),       // royal gold
        heading: Color(hex: "2E3350"),      // dusk blue, very dark
        ink: Color(hex: "2B2D3A"),
        mutedText: Color(hex: "6F6153"),    // dusty taupe, darker (readable on snow)
        faintText: Color(hex: "877666"),    // dusty taupe
        background: Color(hex: "F4EDED"),   // snow
        card: Color(hex: "FFFFFF"),
        surfaceAlt: Color(hex: "EAE3E3"),   // snow, deeper
        border: Color(hex: "DDD5D4"),
        borderStrong: Color(hex: "BFB4B0"),
        hairline: Color(hex: "E8E1E0"),
        success: Color(hex: "3B8560"),
        warning: Color(hex: "CC8A14"),
        danger: Color(hex: "C73838")
    )

    /// Shadow grey 231F20 · tomato jam BB4430 · tropical teal 7EBDC2 · vanilla custard F3DFA2 · linen EFE6DD
    static let tomatoJam = Palette(
        name: "Tomato Jam",
        brand: Color(hex: "BB4430"),        // tomato jam
        brandDeep: Color(hex: "8A3022"),    // tomato jam, darker
        secondary: Color(hex: "7EBDC2"),    // tropical teal
        accent: Color(hex: "F3DFA2"),       // vanilla custard
        heading: Color(hex: "1E1A4D"),      // text roles are ignored (Current's text is always used)
        ink: Color(hex: "1F242E"),
        mutedText: Color(hex: "5F6676"),
        faintText: Color(hex: "99A1AF"),
        background: Color(hex: "EFE6DD"),   // linen
        card: Color(hex: "FFFFFF"),
        surfaceAlt: Color(hex: "E6DACE"),
        border: Color(hex: "DDD0C3"),
        borderStrong: Color(hex: "C2B3A4"),
        hairline: Color(hex: "E8DED4"),
        success: Color(hex: "3B8560"),
        warning: Color(hex: "CC8A14"),
        danger: Color(hex: "C73838")
    )

    /// Camel AF9164 · ivory mist F7F3E3 · silver B3B6B7 · molten lava 6F1A07 · dark coffee 2B2118
    static let moltenCoffee = Palette(
        name: "Molten Coffee",
        brand: Color(hex: "6F1A07"),        // molten lava
        brandDeep: Color(hex: "4A1105"),    // molten lava, darker
        secondary: Color(hex: "AF9164"),    // camel
        accent: Color(hex: "AF9164"),       // camel
        heading: Color(hex: "1E1A4D"),      // text roles are ignored (Current's text is always used)
        ink: Color(hex: "1F242E"),
        mutedText: Color(hex: "5F6676"),
        faintText: Color(hex: "99A1AF"),
        background: Color(hex: "F7F3E3"),   // ivory mist
        card: Color(hex: "FFFFFF"),
        surfaceAlt: Color(hex: "EDE7D2"),
        border: Color(hex: "DDD9CB"),
        borderStrong: Color(hex: "B3B6B7"),
        hairline: Color(hex: "EAE5D4"),
        success: Color(hex: "3B8560"),
        warning: Color(hex: "CC8A14"),
        danger: Color(hex: "C73838")
    )

    /// Vibrant coral F05D5E · stormy teal 0F7173 · platinum E7ECEF · shadow grey 272932 · light bronze D8A47F
    static let coralStorm = Palette(
        name: "Coral Storm",
        brand: Color(hex: "0F7173"),        // stormy teal
        brandDeep: Color(hex: "0A5052"),    // stormy teal, darker
        secondary: Color(hex: "F05D5E"),    // vibrant coral
        accent: Color(hex: "D8A47F"),       // light bronze
        heading: Color(hex: "1E1A4D"),      // text roles are ignored (Current's text is always used)
        ink: Color(hex: "1F242E"),
        mutedText: Color(hex: "5F6676"),
        faintText: Color(hex: "99A1AF"),
        background: Color(hex: "FFFBFB"),   // sky white
        card: Color(hex: "FFFFFF"),
        surfaceAlt: Color(hex: "DCE3E7"),
        border: Color(hex: "D2DAE0"),
        borderStrong: Color(hex: "B4BEC5"),
        hairline: Color(hex: "DEE4E8"),
        success: Color(hex: "3B8560"),
        warning: Color(hex: "CC8A14"),
        danger: Color(hex: "C73838")
    )

    /// Palettes offered in the debug picker, in order.
    static let all: [Palette] = [
        .current, .berryBlush, .graphite, .parchment, .tangerine, .amberStone, .dusk,
        .tomatoJam, .moltenCoffee, .coralStorm,
        .slateBlue, .forest, .warmClay,
    ]
}

// MARK: - Selected palette

/// Holds the palette the whole app draws with. Views that read a color token in `body`
/// redraw when `palette` changes. Release builds always use `Palette.current`.
@Observable
final class ThemeStore {
    static let shared = ThemeStore()

    private static let storageKey = "debug.colorPalette"

    var palette: Palette {
        didSet { UserDefaults.standard.set(palette.name, forKey: Self.storageKey) }
    }

    private init() {
        #if DEBUG
        let saved = UserDefaults.standard.string(forKey: Self.storageKey)
        palette = Palette.all.first { $0.name == saved } ?? .current
        #else
        palette = .current
        #endif
    }
}

extension Palette {
    /// This palette with Current's text colors. Palettes only change backgrounds, buttons,
    /// borders and accents; text keeps one consistent look across all of them.
    var keepingCurrentText: Palette {
        Palette(
            name: name, brand: brand, brandDeep: brandDeep, secondary: secondary, accent: accent,
            heading: Palette.current.heading, ink: Palette.current.ink,
            mutedText: Palette.current.mutedText, faintText: Palette.current.faintText,
            background: background, card: card, surfaceAlt: surfaceAlt, border: border,
            borderStrong: borderStrong, hairline: hairline,
            success: success, warning: warning, danger: danger
        )
    }
}

extension Color {
    /// The palette currently in use, with text colors held at Current's.
    static var theme: Palette { ThemeStore.shared.palette.keepingCurrentText }
}

import SwiftUI

struct AuraTheme: Identifiable, Equatable {
    let id: String
    let name: String
    let caption: String
    let symbol: String
    let accent: Color
    let accentSoft: Color
    let accentStrong: Color
    let canvasTop: Color
    let canvasBottom: Color
    let panelTop: Color
    let panelBottom: Color
    let cardFill: Color
    let cardSecondaryFill: Color
    let stroke: Color
    let heroGlow: Color
    let previewTop: Color
    let previewBottom: Color
    let dockTint: Color
    let statusDot: Color
    let material: Material
    let systemAccentInput: String

    var canvasGradient: LinearGradient {
        LinearGradient(
            colors: [canvasTop, canvasBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var panelGradient: LinearGradient {
        LinearGradient(
            colors: [panelTop, panelBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var previewGradient: LinearGradient {
        LinearGradient(
            colors: [previewTop, previewBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static let sakura = AuraTheme(
        id: "sakura",
        name: "Sakura",
        caption: "Soft bloom",
        symbol: "blossom.fill",
        accent: Color(hex: 0xF06EAA),
        accentSoft: Color(hex: 0xF7C9DE),
        accentStrong: Color(hex: 0xC63B79),
        canvasTop: Color(hex: 0xFFF5F8),
        canvasBottom: Color(hex: 0xFDE1EC),
        panelTop: Color(hex: 0xFFF9FB, opacity: 0.96),
        panelBottom: Color(hex: 0xF7E7EF, opacity: 0.94),
        cardFill: Color(hex: 0xFFFFFF, opacity: 0.72),
        cardSecondaryFill: Color(hex: 0xFBEAF1, opacity: 0.8),
        stroke: Color(hex: 0xE8B7CB, opacity: 0.62),
        heroGlow: Color(hex: 0xFFC6DE, opacity: 0.9),
        previewTop: Color(hex: 0xF9C5D7),
        previewBottom: Color(hex: 0xFCEBEE),
        dockTint: Color(hex: 0xF4B4CB, opacity: 0.4),
        statusDot: Color(hex: 0xFF8FB6),
        material: .thinMaterial,
        systemAccentInput: "ff69b4"
    )

    static let tidal = AuraTheme(
        id: "tidal",
        name: "Tidal",
        caption: "Crisp ocean",
        symbol: "water.waves",
        accent: Color(hex: 0x2797D8),
        accentSoft: Color(hex: 0xA5DCF9),
        accentStrong: Color(hex: 0x11689C),
        canvasTop: Color(hex: 0xEEF9FF),
        canvasBottom: Color(hex: 0xD7EEF8),
        panelTop: Color(hex: 0xF8FDFF, opacity: 0.95),
        panelBottom: Color(hex: 0xDDF3FA, opacity: 0.93),
        cardFill: Color(hex: 0xFFFFFF, opacity: 0.74),
        cardSecondaryFill: Color(hex: 0xE5F6FC, opacity: 0.82),
        stroke: Color(hex: 0x8BCBE8, opacity: 0.56),
        heroGlow: Color(hex: 0x88D8FF, opacity: 0.82),
        previewTop: Color(hex: 0x73C3F2),
        previewBottom: Color(hex: 0xD9F6FF),
        dockTint: Color(hex: 0x86D0F5, opacity: 0.34),
        statusDot: Color(hex: 0x1CB1E8),
        material: .regularMaterial,
        systemAccentInput: "2797d8"
    )

    static let ember = AuraTheme(
        id: "ember",
        name: "Ember",
        caption: "Warm signal",
        symbol: "sparkles",
        accent: Color(hex: 0xE66732),
        accentSoft: Color(hex: 0xFFC8A6),
        accentStrong: Color(hex: 0xB33B10),
        canvasTop: Color(hex: 0xFFF6ED),
        canvasBottom: Color(hex: 0xF9DFC9),
        panelTop: Color(hex: 0xFFFDF9, opacity: 0.95),
        panelBottom: Color(hex: 0xF8E7D6, opacity: 0.93),
        cardFill: Color(hex: 0xFFFFFF, opacity: 0.75),
        cardSecondaryFill: Color(hex: 0xFBE6D4, opacity: 0.82),
        stroke: Color(hex: 0xE5A882, opacity: 0.58),
        heroGlow: Color(hex: 0xFFBE8A, opacity: 0.84),
        previewTop: Color(hex: 0xEE8A52),
        previewBottom: Color(hex: 0xF9E7C8),
        dockTint: Color(hex: 0xF1A56C, opacity: 0.34),
        statusDot: Color(hex: 0xF2843C),
        material: .thinMaterial,
        systemAccentInput: "e66732"
    )

    static let nocturne = AuraTheme(
        id: "nocturne",
        name: "Nocturne",
        caption: "Deep glass",
        symbol: "moon.stars.fill",
        accent: Color(hex: 0x8C9EFF),
        accentSoft: Color(hex: 0xC7D0FF),
        accentStrong: Color(hex: 0x6574D9),
        canvasTop: Color(hex: 0x10131F),
        canvasBottom: Color(hex: 0x1A2237),
        panelTop: Color(hex: 0x1A2231, opacity: 0.94),
        panelBottom: Color(hex: 0x101722, opacity: 0.94),
        cardFill: Color(hex: 0x293349, opacity: 0.64),
        cardSecondaryFill: Color(hex: 0x202A40, opacity: 0.82),
        stroke: Color(hex: 0x4D5D85, opacity: 0.55),
        heroGlow: Color(hex: 0x7A8FFF, opacity: 0.48),
        previewTop: Color(hex: 0x28345A),
        previewBottom: Color(hex: 0x121823),
        dockTint: Color(hex: 0x415280, opacity: 0.38),
        statusDot: Color(hex: 0x9BA8FF),
        material: .ultraThinMaterial,
        systemAccentInput: "8c9eff"
    )

    static let all: [AuraTheme] = [.sakura, .tidal, .ember, .nocturne]

    static func == (lhs: AuraTheme, rhs: AuraTheme) -> Bool {
        lhs.id == rhs.id
    }
}

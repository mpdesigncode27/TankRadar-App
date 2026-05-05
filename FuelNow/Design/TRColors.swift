import SwiftUI

/// Semantische App-Farben — alle aus `TRDesignAssets` (generierte `Color.tr*`).
///
/// Feature-Code soll `TRColors` statt direkter Hex- oder RGB-Konstruktoren nutzen.
///
/// **WCAG-AAA-Hinweise (TAN-80):**
/// * `accent` (Brand-Teal) ist als **Surface/Tint/Glow** gedacht — nicht als kleiner Text auf hellem Background
///   (Kontrast nur ~2:1). Für Accent-**Text** den Token `accentText` verwenden.
/// * `labelSecondary` / `labelTertiary` erfüllen `SC 1.4.6 Contrast (Enhanced)` (≥ 7:1) gegen
///   `background` und `backgroundSecondary` in Light & Dark.
/// * `success` / `danger` sind kontrast-stark genug, um sowohl als Text-Tinten als auch als
///   Indikator-Punkte (mit zusätzlichem SF-Symbol; `SC 1.4.1 Use of Color`) zu funktionieren.
enum TRColors {
    static let accent = Color.trAccent
    static let accentMuted = Color.trAccentMuted
    /// Dunkler Teal (`#0F5650` Light, hellerer Teal in Dark) für **Text** mit Accent-Charakter
    /// und Buttons mit weißer Schrift — erfüllt AAA-Kontrast.
    static let accentText = Color.trAccentText
    static let background = Color.trBackground
    static let backgroundSecondary = Color.trBackgroundSecondary
    static let backgroundTertiary = Color.trBackgroundTertiary
    static let labelPrimary = Color.trLabelPrimary
    static let labelSecondary = Color.trLabelSecondary
    static let labelTertiary = Color.trLabelTertiary
    static let separator = Color.trSeparator
    static let danger = Color.trDanger
    static let success = Color.trSuccess
}

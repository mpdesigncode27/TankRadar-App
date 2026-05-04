import SwiftUI

/// Semantische App-Farben — alle aus `TRDesignAssets` (generierte `Color.tr*`).
///
/// Feature-Code soll `TRColors` statt direkter Hex- oder RGB-Konstruktoren nutzen.
enum TRColors {
    static let accent = Color.trAccent
    static let accentMuted = Color.trAccentMuted
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

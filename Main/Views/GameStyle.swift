import SwiftUI

// MARK: - Shared style
//
// One home for the styling the sheets and rows share, so a change lands
// everywhere at once instead of being re-typed per view. Sheet chrome is the
// exception: `gameSheetClose` lives in RootView.swift beside the button bar it
// installs.

/// Thresholds for the traffic-light odds readout. Presentation only — these are
/// where a probability *reads* as good or middling to the player, not a game
/// rule (those live in `GameConstants`).
private enum OddsPalette {
    static let good = 0.6
    static let fair = 0.3
}

extension Color {
    /// Traffic-light colour for a `0...1` probability: green when the odds are
    /// good, amber when they're middling, red when they're a long shot. Shared
    /// so the hire, founder, promotion-offer and admission readouts all grade on
    /// one scale.
    static func forOdds(_ probability: Double) -> Color {
        if probability >= OddsPalette.good { return .green }
        if probability >= OddsPalette.fair { return .orange }
        return .red
    }
}

/// The one-tap commit control on every activity row — Hobbies, Sports, Events,
/// Trainings, Projects. Tapping it spends the year on that row: the sheet
/// closes and the year runs immediately, so there is nothing to toggle back
/// off. Shared so "spend this year on X" looks the same in every sheet.
struct TakeButton: View {
    var label: String = "Take"
    let action: () -> Void

    var body: some View {
        Button(label, action: action)
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
    }
}

extension View {
    /// Toggle style appropriate for the current platform: a checkbox on macOS, a
    /// switch on iOS. Used by the Jobs list's qualified-only filter.
    @ViewBuilder
    func platformToggleStyle() -> some View {
        #if os(macOS)
        self.toggleStyle(.checkbox)
        #elseif os(iOS)
        self.toggleStyle(.switch)
        #else
        self
        #endif
    }

    /// The standard style for the footer's dialog buttons. Applied once by
    /// `FooterButtonRow` rather than per button.
    func gameFooterButtonStyle() -> some View {
        self.buttonStyle(.bordered).font(.headline)
    }
}

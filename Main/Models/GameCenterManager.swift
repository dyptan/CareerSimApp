import GameKit
import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Wraps Game Center: authenticates the local player and submits scores to a
/// leaderboard. The score is the player's "wealth velocity" — savings ÷ age —
/// so banking wealth at a younger age ranks higher (see `Player.leaderboardScore`).
/// Only scored runs use it at all (`Difficulty.keepsScore`): the Simplified
/// tutorial neither signs in nor submits.
///
/// ── One-time setup required outside the code ──────────────────────────────
///  1. Xcode → CareersApp target → Signing & Capabilities → **+ Capability →
///     Game Center** (adds the `com.apple.developer.game-center` entitlement and
///     enables Game Center on the App ID).
///  2. App Store Connect → your app → Features → Leaderboards → create a
///     leaderboard (Integer format, High score is best) and set its ID below in
///     `leaderboardID`.
///  3. The Mac / device must be signed into Game Center (System Settings).
/// Until that's done, authentication and submission fail gracefully — they log
/// and are ignored, so the rest of the game is unaffected.
final class GameCenterManager: ObservableObject {
    static let shared = GameCenterManager()

    /// The US leaderboard's identifier in App Store Connect. Every country has a
    /// board of its own (`Country.leaderboardID`), since a score is money ÷ age
    /// and euros aren't dollars.
    static let leaderboardID = GameCenterLeaderboards.wealthVelocity

    /// True once the local player has signed into Game Center.
    @Published private(set) var isAuthenticated = false

    private var hasStartedAuthentication = false

    private init() {}

    /// Kicks off Game Center sign-in, once — a scored run calls it as it
    /// starts, so a Simplified player is never asked to sign in. If Game
    /// Center needs to show its sign-in UI, that view controller is presented
    /// automatically.
    func authenticate() {
        guard !hasStartedAuthentication else { return }
        hasStartedAuthentication = true
        GKLocalPlayer.local.authenticateHandler = { viewController, error in
            DispatchQueue.main.async {
                if let viewController {
                    GameCenterManager.present(viewController)
                    return
                }
                if let error {
                    print("[GameCenter] authentication failed: \(error.localizedDescription)")
                }
                GameCenterManager.shared.isAuthenticated = GKLocalPlayer.local.isAuthenticated
            }
        }
    }

    /// Banks the player's score on the leaderboard (Game Center keeps the best,
    /// so it's safe to call at every game-ending moment) — unless their mode
    /// keeps no score (`Difficulty.keepsScore`): the Simplified tutorial's
    /// numbers aren't comparable with a Real Life run's. The one way in, so no
    /// caller has to remember the rule.
    func submitScore(of player: Player) {
        guard player.difficulty.keepsScore else { return }
        submit(score: player.leaderboardScore, to: player.country.leaderboardID)
    }

    /// No-op — logged — when the player isn't signed in, Game Center isn't
    /// configured, or score ≤ 0.
    private func submit(score: Int, to leaderboardID: String) {
        guard score > 0 else { return }
        guard GKLocalPlayer.local.isAuthenticated else {
            print("[GameCenter] not authenticated; skipping score \(score)")
            return
        }
        GKLeaderboard.submitScore(
            score,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [leaderboardID]
        ) { error in
            if let error {
                print("[GameCenter] score submission failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Cross-platform presentation of the sign-in UI

    #if os(iOS)
    private static func present(_ viewController: UIViewController) {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        guard let root = scene?.keyWindow?.rootViewController else { return }
        root.present(viewController, animated: true)
    }
    #elseif os(macOS)
    private static func present(_ viewController: NSViewController) {
        guard let content = NSApp.keyWindow?.contentViewController else { return }
        content.presentAsSheet(viewController)
    }
    #endif
}

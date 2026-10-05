import GameKit
import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Wraps Game Center: authenticates the local player, submits scores to a
/// leaderboard and reads the top of it back. The score is the player's "wealth
/// velocity" — net worth ÷ age — so banking wealth at a younger age ranks higher
/// (see `Player.leaderboardScore`). Only scored runs use it at all
/// (`Difficulty.keepsScore`): the Simplified tutorial neither signs in, submits
/// nor reads a board.
///
/// The boards themselves live in App Store Connect, one per country
/// (`Country.leaderboardID`); `Tools/GameCenter/leaderboards.py` creates them.
/// Until a board exists, or while the player isn't signed into Game Center,
/// authentication and submission fail gracefully — they log and are ignored, so
/// the rest of the game is unaffected.
/// One line of a country's leaderboard.
struct LeaderboardRow: Equatable {
    let rank: Int
    /// The Game Center name; empty for the local player, whose line the sheet labels "You".
    let name: String
    let score: Int
    let isLocalPlayer: Bool
}

/// What the score sheet's leaderboard section has to show.
enum LeaderboardState: Equatable {
    case loading
    /// Not signed in to Game Center, so there is no board to read.
    case signedOut
    /// Signed in, but the board couldn't be read: offline, or not set up in App Store Connect yet.
    case unavailable
    /// The ten best scores, and the local player's own line when it isn't among them.
    case loaded(top: [LeaderboardRow], you: LeaderboardRow?)
}

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
    /// Reads the run's score and country now, since a caller may reset the run next;
    /// the returned task finishes when Game Center has the score (or has refused it).
    @discardableResult
    func submitScore(of player: Player) -> Task<Void, Never> {
        guard player.difficulty.keepsScore else { return Task {} }
        let score = player.leaderboardScore
        let leaderboardID = player.country.leaderboardID
        return Task { await submit(score: score, to: leaderboardID) }
    }

    /// No-op — logged — when the player isn't signed in, Game Center isn't
    /// configured, or score ≤ 0.
    private func submit(score: Int, to leaderboardID: String) async {
        guard score > 0 else { return }
        guard GKLocalPlayer.local.isAuthenticated else {
            print("[GameCenter] not authenticated; skipping score \(score)")
            return
        }
        do {
            try await GKLeaderboard.submitScore(
                score,
                context: 0,
                player: GKLocalPlayer.local,
                leaderboardIDs: [leaderboardID]
            )
        } catch {
            print("[GameCenter] score submission failed: \(error.localizedDescription)")
        }
    }

    /// The ten best scores on a country's board, and the local player's own line when it
    /// is further down. Never throws: whatever goes wrong becomes a state the sheet shows.
    func loadLeaderboard(for country: Country) async -> LeaderboardState {
        guard GKLocalPlayer.local.isAuthenticated else { return .signedOut }
        do {
            guard let board = try await GKLeaderboard.loadLeaderboards(IDs: [country.leaderboardID]).first else {
                return .unavailable
            }
            let (local, entries, _) = try await board.loadEntries(
                for: .global, timeScope: .allTime, range: NSRange(location: 1, length: 10))
            let localID = local?.player.gamePlayerID
            func row(_ entry: GKLeaderboard.Entry) -> LeaderboardRow {
                let isLocal = entry.player.gamePlayerID == localID
                return LeaderboardRow(rank: entry.rank, name: isLocal ? "" : entry.player.displayName,
                                      score: entry.score, isLocalPlayer: isLocal)
            }
            let top = entries.map(row)
            let you = local.map(row).flatMap { mine in top.contains(where: \.isLocalPlayer) ? nil : mine }
            return .loaded(top: top, you: you)
        } catch {
            print("[GameCenter] leaderboard load failed: \(error.localizedDescription)")
            return .unavailable
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

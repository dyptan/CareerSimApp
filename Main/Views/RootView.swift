import SwiftUI
import ConfettiSwiftUI

struct RootView: View {
    @StateObject var player = Player()
    @StateObject var appUIState = AppUIState()

    private var availableJobs: [Job] { player.availableJobs }

    var body: some View {
        if appUIState.hasSelectedMode {
            gameView
        } else {
            ModeSelectionView(player: player, appUIState: appUIState)
        }
    }

    private var gameView: some View {
        VStack(alignment: .leading) {
            HeaderView(player: player, appUIState: appUIState)
                .padding(.bottom)

            Divider()
            Spacer()

            SkillsView(player: player, appUIState: appUIState)

            Spacer()
            Divider()

            FooterView(player: player, appUIState: appUIState)
                .padding(.bottom)
        }
        #if os(macOS)
        // Resizable game window with a sensible default; min keeps it usable.
        .frame(minWidth: 900, idealWidth: 1000, maxWidth: .infinity,
               minHeight: 600, idealHeight: 700, maxHeight: .infinity)
        #endif
        .sheet(isPresented: $appUIState.showDecisionSheet) {
            DecisionView(appUIState: appUIState)
        }
        .sheet(isPresented: $appUIState.showTertiarySheet) {
            EducationView(
                player: player,
                yearsLeftToGraduation: $appUIState.yearsLeftToGraduation,
                showTertiarySheet: $appUIState.showTertiarySheet,
                showCareersSheet: $appUIState.showCareersSheet
            )
            #if os(macOS)
            .frame(minWidth: 800, minHeight: 500)
            #endif

            Button("Close") { appUIState.showTertiarySheet = false }
                .padding()
        }
        .sheet(isPresented: $appUIState.showCareersSheet) {
            JobsView(
                availableJobs: availableJobs,
                player: player,
                showCareersSheet: $appUIState.showCareersSheet
            )
            .frame(idealHeight: 500, alignment: .leading)
            #if os(macOS)
            .frame(minWidth: 800, minHeight: 500)
            #endif

            Button("Close") { appUIState.showCareersSheet = false }
                .padding()
        }
        .sheet(isPresented: $appUIState.showCertificationsSheet) {
            navigationSheet { certificationsContent }
        }
        .sheet(isPresented: $appUIState.showLicensesSheet) {
            navigationSheet { licensesContent }
        }
        .sheet(isPresented: $appUIState.showProjectsSheet) {
            navigationSheet { projectsContent }
        }
        .sheet(isPresented: $appUIState.showActivitiesSheet) {
            navigationSheet { activitiesContent }
        }
        .sheet(isPresented: $appUIState.showSideHustlesSheet) {
            navigationSheet { sideHustlesContent }
        }
        .sheet(isPresented: $appUIState.showRetirementSheet) {
            RetirementView(player: player, appUIState: appUIState)
        }
        .sheet(isPresented: $appUIState.showGoalSheet) {
            GoalView(player: player, appUIState: appUIState)
        }
        .onChange(of: player.savings) { _ in checkGoalReached() }
        .onChange(of: player.currentOccupation) { _ in checkGoalReached() }
        .onChange(of: player.age) { newValue in
            switch newValue {
            case 10:
                player.degrees.append(Education(Level.Stage.PrimarySchool))
                player.currentEducation = Education(Level.Stage.MiddleSchool)
            case 14:
                player.degrees.append(Education(Level.Stage.MiddleSchool))
                player.currentEducation = Education(Level.Stage.HighSchool)
            case 18:
                appUIState.decisionText = "You're 18! What's your next step?"
                player.degrees.append(Education(Level.Stage.HighSchool))
                player.currentEducation = nil
                appUIState.showDecisionSheet.toggle()
            case 68: appUIState.showRetirementSheet.toggle()
            default: break
            }
        }
        .padding()
        // A layoff is a major setback, so it interrupts with a pop-up. The
        // header note (player.lostJobThisYear) lingers for the year afterward.
        .alert("Laid Off", isPresented: $player.showLayoffAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("A downturn hit your employer and your position was cut. You'll need to find a new job — open Careers to start applying.")
        }
        // Celebrates a lucky break — a promotion or a long-shot college
        // admission — fired by bumping `player.celebrationTrigger`. Anchored
        // top-centre so the burst rains over the game view.
        .confettiCannon(
            counter: $player.celebrationTrigger,
            num: 60,
            confettiSize: 12,
            radius: 420
        )
    }

    // MARK: - Goal tracking

    /// Pops the celebration sheet the first time the active mode's goal is met.
    private func checkGoalReached() {
        guard !appUIState.hasShownGoal, player.goalMet else { return }
        appUIState.hasShownGoal = true
        appUIState.showGoalSheet = true
    }

    // MARK: - Navigation sheet wrapper

    @ViewBuilder
    private func navigationSheet<C: View>(@ViewBuilder content: () -> C) -> some View {
        Group {
            if #available(iOS 16, macOS 13, *) {
                NavigationStack { content() }
            } else {
                NavigationView { content() }
                #if os(iOS)
                .navigationViewStyle(.stack)
                #endif
            }
        }
        #if os(macOS)
        .frame(minWidth: 800, minHeight: 500)
        #endif
    }

    // MARK: - Sheet content

    private var activitiesContent: some View {
        ActivitiesView(player: player, selectedActivities: $appUIState.selectedActivities)
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") { appUIState.showActivitiesSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Next") {
                        appUIState.showActivitiesSheet = false
                        player.advanceYear(appUIState: appUIState)
                    }
                }
            }
    }

    private var sideHustlesContent: some View {
        SideHustlesView(player: player, selectedSideHustles: $appUIState.selectedSideHustles)
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") { appUIState.showSideHustlesSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Next") {
                        appUIState.showSideHustlesSheet = false
                        player.advanceYear(appUIState: appUIState)
                    }
                }
            }
    }

    private var certificationsContent: some View {
        CertificationsView(
            player: player,
            selectedCertifications: $appUIState.selectedCertifications,
            selectedActivities: $appUIState.selectedActivities
        )
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { appUIState.showCertificationsSheet = false }
            }
        }
    }

    private var licensesContent: some View {
        LicensesView(
            player: player,
            selectedLicenses: $appUIState.selectedLicenses,
            selectedActivities: $appUIState.selectedActivities
        )
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { appUIState.showLicensesSheet = false }
            }
        }
    }

    private var projectsContent: some View {
        ProjectsView(
            player: player,
            selectedPortfolio: $appUIState.selectedPortfolio,
            selectedActivities: $appUIState.selectedActivities
        )
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { appUIState.showProjectsSheet = false }
            }
        }
    }
}

/// Launch screen: asks the player to pick a game mode before the game starts.
/// Shown whenever `appUIState.hasSelectedMode` is false (initial launch and
/// after a restart).
struct ModeSelectionView: View {
    @ObservedObject var player: Player
    @ObservedObject var appUIState: AppUIState

    /// Once Realistic is picked, the chooser advances to its difficulty step.
    /// Simplified starts immediately, so it never sets this.
    @State private var pendingRealistic = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Career Sim")
                .font(.largeTitle.bold())

            if pendingRealistic {
                difficultyChooser
            } else {
                modeChooser
            }

            Spacer()
        }
        .padding()
        #if os(macOS)
        // Fixed width so the window (bound to content size) doesn't stretch.
        .frame(width: 500)
        #else
        .frame(maxWidth: 500)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #endif
    }

    private var modeChooser: some View {
        VStack(spacing: 20) {
            Text("How do you want to play?")
                .font(.title3)
                .foregroundStyle(.secondary)

            ForEach(GameMode.allCases) { mode in
                Button {
                    if mode == .realistic {
                        pendingRealistic = true
                    } else {
                        start(mode)
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(mode.icon)  \(mode.title)")
                            .font(.title2.bold())
                        Text(mode.tagline)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("🎯 Goal: \(mode.goalHeadline)")
                            .font(.callout.bold())
                            .padding(.top, 2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var difficultyChooser: some View {
        VStack(spacing: 20) {
            Text("Pick your starting point")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("Your family's income sets how much of each paycheck you can save, and a tougher economy means more frequent — and longer — downturns.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(Difficulty.allCases) { difficulty in
                Button {
                    start(.realistic, difficulty: difficulty)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(difficulty.icon)  \(difficulty.title)")
                            .font(.title2.bold())
                        Text(difficulty.blurb)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("💵 Save \(Int(difficulty.savingsRate * 100))% of income · 📉 \(Int(difficulty.turmoilChance * 100))% downturn risk/yr")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }

            Button("← Back") { pendingRealistic = false }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
        }
    }

    /// Locks in the chosen mode (and difficulty, for realistic) and starts the game.
    private func start(_ mode: GameMode, difficulty: Difficulty = .default) {
        player.gameMode = mode
        player.difficulty = difficulty
        player.regenerateAvailableJobs()
        appUIState.hasSelectedMode = true
    }
}

#Preview {
    RootView()
}

#Preview("Mode selection") {
    ModeSelectionView(player: Player(), appUIState: AppUIState())
}

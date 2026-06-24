import SwiftUI

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
        .sheet(isPresented: $appUIState.showRetirementSheet) {
            RetirementView(player: player, appUIState: appUIState)
        }
        .sheet(isPresented: $appUIState.showGoalSheet) {
            GoalView(player: player, appUIState: appUIState)
        }
        .alert("Economic Turmoil", isPresented: $appUIState.showTurmoilAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(appUIState.turmoilMessage)
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

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Career Sim")
                .font(.largeTitle.bold())

            modeChooser

            Spacer()
        }
        .padding()
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var modeChooser: some View {
        VStack(spacing: 20) {
            Text("How do you want to play?")
                .font(.title3)
                .foregroundStyle(.secondary)

            ForEach(GameMode.allCases) { mode in
                Button {
                    start(mode)
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

    /// Locks in the chosen mode and starts the game.
    private func start(_ mode: GameMode) {
        player.gameMode = mode
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

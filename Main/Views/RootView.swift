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

            StatusBarView(player: player)
                .padding(.bottom, 4)

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
        .sheet(isPresented: $appUIState.showTrainingsSheet) {
            navigationSheet { trainingsContent }
        }
        .sheet(isPresented: $appUIState.showHobbiesSheet) {
            navigationSheet { hobbiesContent }
        }
        .sheet(isPresented: $appUIState.showSideHustlesSheet) {
            navigationSheet { sideHustlesContent }
        }
        .sheet(isPresented: $appUIState.showProjectsSheet) {
            navigationSheet { projectsContent }
        }
        .sheet(isPresented: $appUIState.showEventsSheet) {
            navigationSheet { eventsContent }
        }
        .sheet(isPresented: $appUIState.showCompetitionsSheet) {
            navigationSheet { competitionsContent }
        }
        .sheet(isPresented: $appUIState.showSportsSheet) {
            navigationSheet { sportsContent }
        }
        .sheet(isPresented: $appUIState.showRetirementSheet) {
            RetirementView(player: player, appUIState: appUIState)
        }
        .sheet(isPresented: $appUIState.showGoalSheet) {
            GoalView(player: player, appUIState: appUIState)
        }
        .sheet(isPresented: $player.showStartupOfferSheet) {
            StartupOfferView(player: player)
        }
        .alert("Bankruptcy", isPresented: $player.showStartupBankruptcyAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("A downturn forced you to liquidate your startup. You walked away with \(player.lastBankruptcySalvage.formatted(.number)) $ from the fire-sale.")
        }
        .onChange(of: player.savings) { _ in checkGoalReached() }
        .onChange(of: player.currentOccupation) { _ in checkGoalReached() }
        .onChange(of: player.age) { newValue in
            switch newValue {
            case 10:
                let degree = Education(Level.Stage.PrimarySchool)
                player.degrees.append(degree)
                player.recordStatus("🎓", "Graduated — \(degree.degreeName)")
                player.currentEducation = Education(Level.Stage.MiddleSchool)
            case 14:
                let degree = Education(Level.Stage.MiddleSchool)
                player.degrees.append(degree)
                player.recordStatus("🎓", "Graduated — \(degree.degreeName)")
                player.currentEducation = Education(Level.Stage.HighSchool)
            case 18:
                let degree = Education(Level.Stage.HighSchool)
                player.degrees.append(degree)
                player.recordStatus("🎓", "Graduated — \(degree.degreeName)")
                player.graduationMessage = "Congratulations! You finished \(degree.degreeName). Time to figure out the next step — university, vocational training, or straight into work."
                player.showGraduationAlert = true
                player.celebrationTrigger += 1
                player.currentEducation = nil
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
        // Congratulates the player on a promotion — a milestone worth a pop-up.
        // The header note (player.lastPromotionRaisePct) lingers for the year.
        .alert("Congratulations! 🎉", isPresented: $player.showPromotionAlert) {
            Button("Thanks!", role: .cancel) { }
        } message: {
            Text(player.promotionMessage)
        }
        // Marks the end of a degree with a congrats pop-up. The same milestone
        // is also banked into the StatusBar history so the player can revisit it
        // later. College and Careers stay reachable any year from the footer.
        .alert("Congratulations! 🎓", isPresented: $player.showGraduationAlert) {
            Button("Thanks!", role: .cancel) { }
        } message: {
            Text(player.graduationMessage)
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

    private var hobbiesContent: some View {
        HobbiesView(player: player, selectedActivities: $appUIState.selectedActivities)
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") { appUIState.showHobbiesSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Next") {
                        appUIState.showHobbiesSheet = false
                        player.advanceYear(appUIState: appUIState)
                    }
                }
            }
    }

    private var eventsContent: some View {
        EventsView(player: player, selectedEvents: $appUIState.selectedEvents)
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") { appUIState.showEventsSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Next") {
                        appUIState.showEventsSheet = false
                        player.advanceYear(appUIState: appUIState)
                    }
                }
            }
    }

    private var competitionsContent: some View {
        CompetitionsView(player: player, selectedCompetitions: $appUIState.selectedCompetitions)
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") { appUIState.showCompetitionsSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Next") {
                        appUIState.showCompetitionsSheet = false
                        player.advanceYear(appUIState: appUIState)
                    }
                }
            }
    }

    private var sportsContent: some View {
        SportsView(
            player: player,
            selectedActivities: $appUIState.selectedActivities,
            selectedSports: $appUIState.selectedSports
        )
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") { appUIState.showSportsSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Next") {
                        appUIState.showSportsSheet = false
                        player.advanceYear(appUIState: appUIState)
                    }
                }
            }
    }

    private var sideHustlesContent: some View {
        PrivateProjectsView(
            player: player,
            selectedSideHustles: $appUIState.selectedSideHustles
        )
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

    private var projectsContent: some View {
        ProjectsView(
            player: player,
            selectedProjects: $appUIState.selectedProjects
        )
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") { appUIState.showProjectsSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Next") {
                        appUIState.showProjectsSheet = false
                        player.advanceYear(appUIState: appUIState)
                    }
                }
            }
    }

    private var trainingsContent: some View {
        TrainingsView(
            player: player,
            selectedTrainings: $appUIState.selectedTrainings,
            selectedActivities: $appUIState.selectedActivities
        )
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Back") { appUIState.showTrainingsSheet = false }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Next") {
                    appUIState.showTrainingsSheet = false
                    player.advanceYear(appUIState: appUIState)
                }
            }
        }
    }

}

/// Launch screen: asks the player to pick a difficulty before the game starts.
/// Shown whenever `appUIState.hasSelectedMode` is false (initial launch and
/// after a restart).
struct ModeSelectionView: View {
    @ObservedObject var player: Player
    @ObservedObject var appUIState: AppUIState

    /// Chosen avatar and starting age (7–18), set before a difficulty is picked.
    @State private var avatar: String = Player.avatarOptions[0]
    @State private var startAge: Int = GameConstants.startingAge

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Career Sim")
                    .font(.largeTitle.bold())
                    .padding(.top)

                avatarChooser
                ageChooser
                difficultyChooser
            }
            .padding()
        }
        #if os(macOS)
        // Fixed width so the window (bound to content size) doesn't stretch.
        .frame(width: 500)
        #else
        .frame(maxWidth: 500)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #endif
    }

    private var avatarChooser: some View {
        VStack(spacing: 10) {
            Text("Pick your character")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text(avatar)
                .font(.system(size: 64))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                ForEach(Player.avatarOptions, id: \.self) { option in
                    Button {
                        avatar = option
                    } label: {
                        Text(option)
                            .font(.system(size: 28))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(option == avatar ? Color.accentColor.opacity(0.25) : Color.secondary.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var ageChooser: some View {
        VStack(spacing: 6) {
            Text("Starting age")
                .font(.title3)
                .foregroundStyle(.secondary)

            Stepper(value: $startAge, in: 7...18) {
                Text("Age \(startAge)")
                    .font(.headline.monospacedDigit())
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text(startingEducationNote)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Tells the player which school stage they'll begin in for the chosen age.
    private var startingEducationNote: String {
        switch startAge {
        case ..<10:   return "🎒 You'll start in primary school."
        case 10..<14: return "🎒 You'll start in middle school (primary school done)."
        case 14..<18: return "🎒 You'll start in high school (middle school done)."
        default:      return "🎓 You'll start having just finished high school — time to choose your next step."
        }
    }

    private var difficultyChooser: some View {
        VStack(spacing: 20) {
            Text("How do you want to play?")
                .font(.title3)
                .foregroundStyle(.secondary)

            ForEach(Difficulty.allCases) { difficulty in
                Button {
                    start(difficulty)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(difficulty.icon)  \(difficulty.title)")
                            .font(.title2.bold())
                        Text(difficulty.blurb)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("🎯 Goal: \(difficulty.goalHeadline)")
                            .font(.callout.bold())
                            .padding(.top, 2)
                        if !difficulty.isSimplified {
                            Text("💵 Save \(Int(difficulty.savingsRate * 100))% of income · 📉 \(Int(difficulty.turmoilChance * 100))% downturn risk/yr")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                        }
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

    /// Locks in the avatar, starting age (with its matching education), and the
    /// chosen difficulty, then starts the game.
    private func start(_ difficulty: Difficulty) {
        player.difficulty = difficulty
        player.avatar = avatar
        player.configureStart(age: startAge)
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

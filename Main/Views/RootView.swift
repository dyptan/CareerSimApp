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
        VStack(alignment: .leading, spacing: 8) {
            HeaderView(player: player, appUIState: appUIState)

            StatusBarView(player: player)

            Divider()

            // The skills panel flexes to fill the space between the pinned header
            // and footer — scrolling when there's a lot to show (a full career)
            // and top-aligning when there isn't (early childhood) — instead of the
            // old pair of Spacers that centred it and left a large void mid-screen.
            SkillsView(player: player, appUIState: appUIState)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            Divider()

            FooterView(player: player, appUIState: appUIState)
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
        }
        .sheet(isPresented: $appUIState.showEntrepreneurshipSheet) {
            EntrepreneurshipView(
                availableJobs: availableJobs,
                player: player,
                showSheet: $appUIState.showEntrepreneurshipSheet
            )
            .frame(idealHeight: 500, alignment: .leading)
            #if os(macOS)
            .frame(minWidth: 800, minHeight: 500)
            #endif
        }
        .sheet(isPresented: $appUIState.showExecutiveSheet) {
            ExecutiveDecisionsView(
                player: player,
                showSheet: $appUIState.showExecutiveSheet
            )
            #if os(macOS)
            .frame(minWidth: 520, minHeight: 480)
            #endif
        }
        .sheet(isPresented: $appUIState.showTrainingsSheet) {
            GameSheet(title: "Trainings", isPresented: $appUIState.showTrainingsSheet) {
                TrainingsView(
                    player: player,
                    selectedTrainings: $appUIState.selectedTrainings,
                    selectedActivities: $appUIState.selectedActivities
                )
            }
        }
        .sheet(isPresented: $appUIState.showHobbiesSheet) {
            GameSheet(title: "Hobbies", isPresented: $appUIState.showHobbiesSheet) {
                HobbiesView(player: player, selectedActivities: $appUIState.selectedActivities)
            }
        }
        .sheet(isPresented: $appUIState.showSideHustlesSheet) {
            GameSheet(title: "Projects", isPresented: $appUIState.showSideHustlesSheet) {
                PrivateProjectsView(
                    player: player,
                    selectedSideHustles: $appUIState.selectedSideHustles
                )
            }
        }
        .sheet(isPresented: $appUIState.showEventsSheet) {
            GameSheet(title: "Events", isPresented: $appUIState.showEventsSheet) {
                EventsView(player: player, selectedEvents: $appUIState.selectedEvents)
            }
        }
        .sheet(isPresented: $appUIState.showSportsSheet) {
            GameSheet(title: "Sports", isPresented: $appUIState.showSportsSheet) {
                SportsView(
                    player: player,
                    selectedActivities: $appUIState.selectedActivities,
                    selectedSports: $appUIState.selectedSports
                )
            }
        }
        .sheet(isPresented: $appUIState.showRetirementSheet) {
            RetirementView(player: player, appUIState: appUIState)
        }
        .sheet(isPresented: $appUIState.showGoalSheet) {
            GoalView(player: player, appUIState: appUIState)
        }
        // The only fixed goal left is Simplified's top-leadership finish line,
        // which turns on when the occupation changes; realistic modes are
        // open-ended and score-based (see `Player.goalMet`).
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
        // Celebrates winning the sport's automatic yearly competition. The
        // header note (player.lastCompetitionWins) lingers for the year, and
        // confetti fires via celebrationTrigger.
        .alert("Champion! 🏆", isPresented: $player.showCompetitionWinAlert) {
            Button("🎉", role: .cancel) { }
        } message: {
            Text(player.competitionWinMessage)
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

// MARK: - Standard sheet chrome

/// Standard chrome for every action sheet in the game. Wraps plain content in a
/// navigation container and gives it the one, uniform dismiss control — a single
/// leading **Close** button with an inline title — via `gameSheetClose`. Dialogs
/// never advance the game year (only the footer's **Next** does), so a sheet
/// carries no confirm/"Next" action; any commit (Apply, Enroll, Launch…) is an
/// in-content button that keeps the sheet open on failure and closes on success.
///
/// The four dialogs that manage their own `NavigationStack` (Jobs, Education,
/// Ventures, Boardroom) don't use this wrapper — they apply `gameSheetClose`
/// directly to their root content — but the dismiss control ends up identical.
struct GameSheet<Content: View>: View {
    let title: String
    @Binding var isPresented: Bool
    @ViewBuilder var content: () -> Content

    var body: some View {
        Group {
            if #available(iOS 16, macOS 13, *) {
                NavigationStack { content().gameSheetClose($isPresented, title: title) }
            } else {
                NavigationView { content().gameSheetClose($isPresented, title: title) }
                #if os(iOS)
                .navigationViewStyle(.stack)
                #endif
            }
        }
        #if os(macOS)
        .frame(minWidth: 520, minHeight: 480)
        #endif
    }
}

extension View {
    /// Applies the game's standard sheet chrome: an inline navigation title and a
    /// single leading **Close** button. Used by `GameSheet` for plain content and
    /// directly by the dialogs that own their navigation stack, so every sheet is
    /// dismissed the same way, from the same place, with the same label.
    func gameSheetClose(_ isPresented: Binding<Bool>, title: String) -> some View {
        self
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { isPresented.wrappedValue = false }
                }
            }
    }
}

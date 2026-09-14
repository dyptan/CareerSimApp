import SwiftUI
import ConfettiSwiftUI

struct RootView: View {
    @StateObject var player = Player()
    @StateObject var appUIState = AppUIState()

    /// Persists across launches: the first-run coach shows only until the player
    /// has seen it once. Reset in a fresh install (or by clearing app storage).
    @AppStorage("hasSeenCoach") private var hasSeenCoach = false
    /// Drives the coach sheet; set true when the game view first appears and the
    /// player hasn't seen the coach yet.
    @State private var showCoach = false

    private var availableJobs: [Job] { player.availableJobs }

    var body: some View {
        Group {
            if appUIState.hasSelectedMode {
                gameView
            } else {
                ModeSelectionView(player: player, appUIState: appUIState)
            }
        }
    }

    /// Spending the year on what the player just chose: close the sheet the
    /// choice was made in, then let the year run. Dismissing *first* keeps any
    /// pop-up the year raises — a graduation, a project result, an offer — from
    /// having to fight an open sheet for the screen.
    private func spendYear(closing sheet: ReferenceWritableKeyPath<AppUIState, Bool>) {
        appUIState[keyPath: sheet] = false
        player.advanceYear(appUIState: appUIState)
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
        // First-run onboarding: greet a brand-new player once, right after they
        // land in the game, then never again (flag persists across launches).
        .onAppear {
            if !hasSeenCoach { showCoach = true }
        }
        .sheet(isPresented: $showCoach, onDismiss: { hasSeenCoach = true }) {
            CoachView(difficulty: player.difficulty, isPresented: $showCoach)
        }
        .sheet(isPresented: $appUIState.showTertiarySheet) {
            EducationView(
                player: player,
                yearsLeftToGraduation: $appUIState.yearsLeftToGraduation,
                showTertiarySheet: $appUIState.showTertiarySheet,
                showCareersSheet: $appUIState.showCareersSheet,
                selectedTrainings: $appUIState.selectedTrainings,
                selectedActivities: $appUIState.selectedActivities,
                onCommit: { spendYear(closing: \.showTertiarySheet) }
            )
            #if os(macOS)
            .frame(minWidth: 800, minHeight: 500)
            #endif
        }
        .sheet(isPresented: $appUIState.showCareersSheet) {
            JobsView(
                availableJobs: availableJobs,
                player: player,
                showCareersSheet: $appUIState.showCareersSheet,
                settingFilter: $appUIState.jobSettingFilter,
                qualifiedOnly: $appUIState.jobQualifiedOnly,
                onCommit: { spendYear(closing: \.showCareersSheet) }
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
                showSheet: $appUIState.showEntrepreneurshipSheet,
                onCommit: { spendYear(closing: \.showEntrepreneurshipSheet) }
            )
            .frame(idealHeight: 500, alignment: .leading)
            #if os(macOS)
            .frame(minWidth: 800, minHeight: 500)
            #endif
        }
        .sheet(isPresented: $appUIState.showExecutiveSheet) {
            ExecutiveDecisionsView(
                player: player,
                showSheet: $appUIState.showExecutiveSheet,
                onCommit: { spendYear(closing: \.showExecutiveSheet) }
            )
            #if os(macOS)
            .frame(minWidth: 520, minHeight: 480)
            #endif
        }
        .sheet(isPresented: $appUIState.showHobbiesSheet) {
            GameSheet(title: "Hobbies", isPresented: $appUIState.showHobbiesSheet) {
                HobbiesView(player: player,
                            selectedActivities: $appUIState.selectedActivities,
                            onCommit: { spendYear(closing: \.showHobbiesSheet) })
            }
        }
        .sheet(isPresented: $appUIState.showSideHustlesSheet) {
            GameSheet(title: "Projects", isPresented: $appUIState.showSideHustlesSheet) {
                PrivateProjectsView(
                    player: player,
                    selectedSideHustles: $appUIState.selectedSideHustles,
                    onCommit: { spendYear(closing: \.showSideHustlesSheet) }
                )
            }
        }
        .sheet(isPresented: $appUIState.showEventsSheet) {
            GameSheet(title: "Events", isPresented: $appUIState.showEventsSheet) {
                EventsView(player: player,
                           selectedEvents: $appUIState.selectedEvents,
                           onCommit: { spendYear(closing: \.showEventsSheet) })
            }
        }
        .sheet(isPresented: $appUIState.showSportsSheet) {
            GameSheet(title: "Sports", isPresented: $appUIState.showSportsSheet) {
                SportsView(
                    player: player,
                    selectedActivities: $appUIState.selectedActivities,
                    selectedSports: $appUIState.selectedSports,
                    onCommit: { spendYear(closing: \.showSportsSheet) }
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
                player.graduationMessage = player.graduationMessage(for: degree, previousEQF: 2)
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
        // A founder's venture folding is a major setback worth a pop-up — they're
        // not laid off, their business fails (see the ongoing venture risk).
        .alert("Venture Folded 📉", isPresented: $player.showVentureFailureAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(player.ventureFailureMessage)
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
        // Reports back on an application or a venture launch — an offer, or a
        // no with what to change. Applying spends the year either way, so the
        // answer arrives here rather than inside a sheet that has closed.
        .alert(player.applicationOutcomeTitle, isPresented: $player.showApplicationOutcomeAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(player.applicationOutcomeMessage)
        }
        // Reports back on the spare-time project the year was spent on — a hit or
        // a flop, either way. A hit also fires the confetti (Player.celebrate).
        .alert(player.projectOutcomeTitle, isPresented: $player.showProjectOutcomeAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(player.projectOutcomeMessage)
        }
        // Marks the end of a degree with a congrats pop-up. The same milestone
        // is also banked into the StatusBar history so the player can revisit it
        // later. College and Careers stay reachable any year from the footer.
        .alert("Congratulations! 🎓", isPresented: $player.showGraduationAlert) {
            Button("OK", role: .cancel) { }
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
                        HStack(spacing: 8) {
                            Text("\(difficulty.icon)  \(difficulty.title)")
                                .font(.title2.bold())
                            if difficulty.isRecommendedForNewPlayers {
                                Text("Start here")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(Color.accentColor))
                                    .foregroundStyle(.white)
                            }
                        }
                        Text(difficulty.audience)
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
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
/// navigation container and gives it a **Close** button in a bar pinned along
/// the sheet's bottom edge, under an inline title, via `gameSheetClose`.
///
/// There is no **Next** control: choosing something *is* committing to the year,
/// so every sheet closes and the year advances as soon as the player picks. The
/// only button here is **Close**, for leaving without spending the year.
///
/// The four dialogs that manage their own `NavigationStack` (Jobs, Education,
/// Ventures, Boardroom) don't use this wrapper — they apply `gameSheetClose`
/// directly to their root content — so the chrome ends up identical either way.
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

/// The uniform button bar every sheet carries along its bottom edge: **Close**,
/// and nothing else. Pinned to the bottom rather than tucked in the navigation
/// bar, so it sits where the hand already is after the player has scrolled
/// through the sheet's options. Choosing an option spends the year and closes
/// the sheet on its own, so there is nothing to confirm here.
struct GameSheetButtonBar: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                Button("Close") { isPresented = false }
                    .buttonStyle(.bordered)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        // Keeps the bar legible when list content scrolls underneath it.
        .background(.bar)
    }
}

extension View {
    /// Applies the game's standard sheet chrome: an inline navigation title and a
    /// bottom button bar holding **Close**. Used by `GameSheet` for plain content
    /// and directly by the dialogs that own their navigation stack, so every
    /// sheet is dismissed the same way, from the same place.
    func gameSheetClose(_ isPresented: Binding<Bool>, title: String) -> some View {
        self
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .safeAreaInset(edge: .bottom, spacing: 0) {
                GameSheetButtonBar(isPresented: isPresented)
            }
    }
}

// MARK: - First-run coach

/// One-time onboarding shown the first time a game starts. Explains the core
/// loop — choosing something spends the year, Skip passes it, the bottom buttons
/// are what a year can be spent on — in plain, friendly language so a first-time (or young) player
/// isn't dropped in cold. Presented once via the `hasSeenCoach` @AppStorage flag
/// in `RootView`; the single **Let's go** button (or Close) dismisses it.
struct CoachView: View {
    let difficulty: Difficulty
    @Binding var isPresented: Bool

    private struct Tip: Identifiable {
        let icon: String
        let title: String
        let body: String
        var id: String { title }
    }

    private var tips: [Tip] {
        [
            Tip(icon: "🎂", title: "One turn = one year",
                body: "Your character grows a year older each turn. Choosing something — a hobby, a course, a job — is how you spend that year, and the year passes as soon as you pick. Nothing you fancy this year? Tap the blue Skip button at the top."),
            Tip(icon: "🎒", title: "Build your life from the buttons",
                body: "The buttons along the bottom — Education, Hobbies, Sports, Jobs and more — are what a year can be spent on. Every choice shapes who you become."),
            Tip(icon: "📈", title: "Watch yourself grow",
                body: "The middle of the screen tracks the skills, titles, and money you pile up over the years."),
            Tip(icon: difficulty.goalIcon, title: "Your goal",
                body: "\(difficulty.goalHeadline). Tap the ⓘ next to your age at any time to check how you're doing."),
            Tip(icon: "💡", title: "Stuck? Look for ⓘ",
                body: "Those little ⓘ buttons are everywhere — tap one to see exactly how something works, from getting hired to winning a competition."),
        ]
    }

    var body: some View {
        NavigationStackOrView {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome to Career Sim! 👋")
                            .font(.title.bold())
                        Text("Live a whole life, one year at a time — here's the idea:")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(tips) { tip in
                        HStack(alignment: .top, spacing: 12) {
                            Text(tip.icon)
                                .font(.title2)
                                .frame(width: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tip.title)
                                    .font(.headline)
                                Text(tip.body)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    Button {
                        isPresented = false
                    } label: {
                        Text("Let's go! 🚀")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
                }
                .padding()
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
            .gameSheetClose($isPresented, title: "How to play")
        }
        #if os(macOS)
        .frame(minWidth: 520, minHeight: 520)
        #endif
    }
}

/// Wraps content in the era-appropriate navigation container (`NavigationStack`
/// on modern OSes, `NavigationView` otherwise) so `CoachView` can reuse the
/// shared `gameSheetClose` chrome without repeating the availability scaffolding.
private struct NavigationStackOrView<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        if #available(iOS 16, macOS 13, *) {
            NavigationStack { content() }
        } else {
            NavigationView { content() }
            #if os(iOS)
            .navigationViewStyle(.stack)
            #endif
        }
    }
}

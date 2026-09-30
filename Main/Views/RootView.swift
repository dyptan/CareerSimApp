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

    /// Opens the sheet an advisor tip pointed to, now that the advisor is gone.
    private func openAdvisorFollowUp() {
        guard let destination = appUIState.advisorFollowUp else { return }
        appUIState.advisorFollowUp = nil
        switch destination {
        case .jobs(let setting):
            // A saved "kind of work" filter mustn't hide the role just recommended.
            if let filter = appUIState.jobSettingFilter, filter != setting {
                appUIState.jobSettingFilter = nil
            }
            appUIState.showCareersSheet = true
        case .listing(let title):
            // Straight onto that role's postings, whatever the list's filters say.
            appUIState.jobFocusRole = title
            appUIState.showCareersSheet = true
        case .education:
            appUIState.showTertiarySheet = true
        case .events:
            appUIState.showEventsSheet = true
        case .projects:
            appUIState.showSideHustlesSheet = true
        case .ventures:
            appUIState.showEntrepreneurshipSheet = true
        case .boardroom:
            appUIState.showExecutiveSheet = true
        case .activities(let tab):
            appUIState.activitiesTab = tab
            appUIState.showActivitiesSheet = true
        }
    }

    private var gameView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HeaderView(player: player, appUIState: appUIState)

            // Hidden until the first milestone, like every stat section.
            if !player.statusEvents.isEmpty {
                StatusBarView(player: player)
            }

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
                focusRole: $appUIState.jobFocusRole,
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
        .sheet(isPresented: $appUIState.showActivitiesSheet) {
            GameSheet(title: "Activities", hint: ActivitiesView.hint, isPresented: $appUIState.showActivitiesSheet) {
                ActivitiesView(player: player,
                               appUIState: appUIState,
                               onCommit: { spendYear(closing: \.showActivitiesSheet) })
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
            GameSheet(title: "Events", hint: EventsView.hint, isPresented: $appUIState.showEventsSheet) {
                EventsView(player: player,
                           selectedEvents: $appUIState.selectedEvents,
                           onCommit: { spendYear(closing: \.showEventsSheet) })
            }
        }
        .sheet(isPresented: $appUIState.showRetirementSheet) {
            RetirementView(player: player, appUIState: appUIState)
        }
        .sheet(isPresented: $appUIState.showAdvisorSheet, onDismiss: openAdvisorFollowUp) {
            GameSheet(title: "Advisor", hint: AdvisorView.hint, isPresented: $appUIState.showAdvisorSheet) {
                AdvisorView(player: player) { destination in
                    appUIState.advisorFollowUp = destination
                    appUIState.showAdvisorSheet = false
                }
            }
        }
        .sheet(isPresented: $appUIState.showGoalSheet) {
            GoalView(player: player, appUIState: appUIState)
        }
        // The only fixed goal left is Simplified's top-leadership finish line,
        // which turns on when the occupation changes; realistic modes are
        // score-based, ending at `GameConstants.retirementAge` (see
        // `Player.goalMet` / `Player.hasRetired`).
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
                player.graduationMessage = player.graduationMessage(for: degree)
                player.showGraduationAlert = true
                player.currentEducation = nil
            case 68: appUIState.showRetirementSheet = true
            default: break
            }
        }
        .padding()
        // A layoff is a major setback, so it interrupts with a pop-up. The
        // status log keeps a "Laid off" line afterward.
        .alert("Laid Off", isPresented: $player.showLayoffAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your employer had to cut jobs, and yours was one of them. You still got part of this year's pay. Open Jobs to find a new one.")
        }
        // A founder's venture folding is a major setback worth a pop-up — they're
        // not laid off, their business fails (see the ongoing venture risk).
        .alert("Business Closed 📉", isPresented: $player.showVentureFailureAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(player.ventureFailureMessage)
        }
        // Congratulates the player on a promotion — a milestone worth a pop-up.
        // The status log keeps a "Promoted" line afterward.
        .alert("Congratulations! 🎉", isPresented: $player.showPromotionAlert) {
            Button("Thanks!", role: .cancel) { }
        } message: {
            Text(player.promotionMessage)
        }
        // Celebrates winning the sport's automatic yearly competition. The
        // status log keeps a "Won" line afterward, and
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

    /// The starting age, with what it means — the school stage it begins in and
    /// what skipping years costs — behind its ⓘ.
    private var ageChooser: some View {
        Stepper(value: $startAge, in: 7...18) {
            HStack(spacing: 6) {
                Text("Age \(startAge)")
                    .font(.headline.monospacedDigit())
                InfoHint(title: "Starting age", message: ageDetails)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var ageDetails: String {
        var lines = [startingEducationNote]
        if let skipped = skippedYearsNote { lines.append(skipped) }
        lines.append("Starting at \(GameConstants.startingAge) lets you choose every year yourself — the early choices are what the hardest schools and jobs are built on.")
        return lines.joined(separator: "\n\n")
    }

    /// What starting later costs: the years skipped leave a few random skill
    /// points instead of the ones the player would have chosen.
    private var skippedYearsNote: String? {
        let years = min(startAge, GameConstants.skippedYearsFullValueBelowAge) - GameConstants.startingAge
        guard years > 0 else { return nil }
        let points = years * GameConstants.skippedYearSkillPoints
        return "🎲 Skipping \(years) year\(years == 1 ? "" : "s") of childhood gives you \(points) random skill point\(points == 1 ? "" : "s"). Playing those years yourself builds far more."
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

    /// One card per mode: its name and a short line. Who it's for, the goal and
    /// the numbers behind it are in the card's ⓘ, which sits over the card
    /// rather than inside its button so a tap on it opens the hint instead of
    /// starting the game.
    private var difficultyChooser: some View {
        VStack(spacing: 14) {
            ForEach(Difficulty.allCases) { difficulty in
                ZStack(alignment: .topTrailing) {
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
                            Text(difficulty.blurb)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .padding(.trailing, 28)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    InfoHint(title: "\(difficulty.icon) \(difficulty.title)", message: difficulty.details)
                        .padding(14)
                }
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
        // Only a scored run reaches the leaderboard, so only it signs in.
        if difficulty.keepsScore { GameCenterManager.shared.authenticate() }
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
    /// Optional ⓘ beside the title — where a sheet explains itself, instead of
    /// a caption taking space above its content.
    var hint: String? = nil
    @Binding var isPresented: Bool
    @ViewBuilder var content: () -> Content

    var body: some View {
        NavigationStack { content().gameSheetClose($isPresented, title: title, hint: hint) }
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
    func gameSheetClose(_ isPresented: Binding<Bool>, title: String, hint: String? = nil) -> some View {
        self
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                if let hint {
                    ToolbarItem(placement: .principal) {
                        HStack(spacing: 6) {
                            Text(title).font(.headline)
                            InfoHint(title: title, message: hint)
                        }
                    }
                }
            }
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
                body: "Your character grows a year older each turn. Choosing something — an activity, a course, a job — is how you spend that year, and the year passes as soon as you pick. Nothing you want to do this year? Tap the blue Skip button at the top."),
            Tip(icon: "🎒", title: "Build your life from the buttons",
                body: "The buttons along the bottom — Education, Activities, Jobs and more — are what a year can be spent on. Every choice shapes who you become."),
            Tip(icon: "📈", title: "Watch yourself grow",
                body: "The middle of the screen tracks the skills, titles, and money you pile up over the years."),
            Tip(icon: difficulty.goalIcon, title: "Your goal",
                body: "\(difficulty.goalHeadline). Tap the ⓘ next to your age at any time to check how you're doing."),
            Tip(icon: "💡", title: "Stuck? Look for ⓘ",
                body: "Those little ⓘ buttons are everywhere — tap one to see exactly how something works, from getting hired to winning a competition."),
        ]
    }

    var body: some View {
        NavigationStack {
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

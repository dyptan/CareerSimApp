import SwiftUI
import Combine

final class AppUIState: ObservableObject {
    // Sheets
    @Published var showTertiarySheet: Bool
    @Published var showCareersSheet: Bool
    @Published var showHobbiesSheet: Bool = false
    @Published var showSideHustlesSheet: Bool = false
    @Published var showEntrepreneurshipSheet: Bool = false
    /// The Boardroom sheet — senior-leadership strategy plays. Gated in the
    /// footer on the player holding an executive seat (`Job.isExecutive`).
    @Published var showExecutiveSheet: Bool = false
    @Published var showEventsSheet: Bool = false
    @Published var showSportsSheet: Bool = false
    @Published var showRetirementSheet: Bool = false

    // Jobs-list filters. They live here rather than in `JobsView` so a choice
    // survives the sheet closing: every application costs a year, so the list is
    // reopened every year, and a filter that forgot itself each time would have
    // to be set again on every visit.
    /// Narrows the jobs list to one kind of work; `nil` shows every setting.
    @Published var jobSettingFilter: WorkSetting?
    /// Hides roles whose hard requirements the player doesn't meet yet.
    @Published var jobQualifiedOnly: Bool = false

    // Selections
    @Published var selectedActivities: Set<String>
    /// Trainings the player is attempting this year (former certifications +
    /// licences, now unified). Resolved and cleared by `Player.advanceYear`.
    @Published var selectedTrainings: Set<Training>
    /// Ids of the spare-time ventures (money hustles + fame projects, now one
    /// system) the player is attempting this year (see `SideHustleCatalog`).
    /// Resolved and cleared by `Player.advanceYear`.
    @Published var selectedSideHustles: Set<String> = []
    /// Ids of the professional events the player is taking the stage at this
    /// year (see `EventCatalog`). Network/soft-skill effects apply on selection;
    /// presenter fame is banked — and picks cleared — by `Player.advanceYear`.
    @Published var selectedEvents: Set<String> = []
    /// Sports the player is committing this year's spare-time slot to.
    /// Banked into `Player.sportYears` and cleared by `Player.advanceYear`.
    @Published var selectedSports: Set<Sport> = []

    // Misc
    @Published var yearsLeftToGraduation: Int?

    /// Whether the player has picked a game mode yet. Until true, RootView shows
    /// the mode picker instead of the game. Reset to false on restart.
    @Published var hasSelectedMode: Bool = false

    /// Drives the goal-reached celebration sheet. `hasShownGoal` guards it so
    /// the celebration only appears once per game.
    @Published var showGoalSheet: Bool = false
    @Published var hasShownGoal: Bool = false


    init(
        showTertiarySheet: Bool = false,
        showCareersSheet: Bool = false,
        selectedActivities: Set<String> = [],
        selectedTrainings: Set<Training> = [],
        yearsLeftToGraduation: Int? = nil,
        showHobbiesSheet: Bool = false,
        showRetirementSheet: Bool = false
    ) {
        self.showTertiarySheet = showTertiarySheet
        self.showCareersSheet = showCareersSheet
        self.selectedActivities = selectedActivities
        self.selectedTrainings = selectedTrainings
        self.yearsLeftToGraduation = yearsLeftToGraduation
        self.showHobbiesSheet = showHobbiesSheet
        self.showRetirementSheet = showRetirementSheet
    }

    func reset() {
        jobSettingFilter = nil
        jobQualifiedOnly = false
        showTertiarySheet = false
        showCareersSheet = false
        showHobbiesSheet = false
        showSideHustlesSheet = false
        showEntrepreneurshipSheet = false
        showExecutiveSheet = false
        showEventsSheet = false
        showSportsSheet = false
        showRetirementSheet = false
        hasSelectedMode = false
        showGoalSheet = false
        hasShownGoal = false
        selectedActivities = []
        selectedTrainings = []
        selectedSideHustles = []
        selectedEvents = []
        selectedSports = []
        yearsLeftToGraduation = nil
    }
}

import Foundation

/// The game's job database. Every job is one `JobSpec` row; the per-title tables
/// below refine the rows whose category default is wrong for them.
///
/// **Why these tables are dictionaries rather than `switch` statements.** Each is
/// keyed by a job title, so renaming a job would silently drop it back to its
/// category defaults — the balance changes and nothing complains. A dictionary's
/// keys can be *enumerated*, so `JobCatalogIntegrityTests` asserts every key
/// names a real job and a rename fails the tests instead. A `switch` cannot be
/// checked that way.
enum JobCatalog {

    // MARK: - Job specification

    /// One row per job — the single place a job is defined.
    ///
    /// Named fields rather than a positional tuple: `icon` and `summary` are
    /// both `String` and adjacent, so a swapped pair would otherwise compile
    /// cleanly and produce a wrong job.
    struct JobSpec {
        let title: String
        let category: JobCategory
        let income: Int
        let icon: String
        let summary: String
        /// Education floor, raised at build time to whatever the role's mandated
        /// credentials themselves require (see `job(from:)`).
        var minEQF: Int = 0
        /// Experience an employer expects before considering an applicant.
        /// `nil` takes the role's entry in `minYearsByTitle` (else 0).
        var minYears: Int? = nil
        /// Capital a founder stakes. Carrying one is what makes a role a venture
        /// (`Job.isEntrepreneurial`) — not its category.
        var targetCapital: Int? = nil
    }

    /// One rung of a career ladder. Everything a rung varies from its ladder;
    /// what it shares (the role name, industry, pictogram) lives on `LadderSpec`.
    struct RungSpec {
        /// Seniority label — "Senior", "Lead" — or empty for the rung that
        /// carries the bare role name. Becomes `Job.rungLabel`.
        let label: String
        let income: Int
        let summary: String
        /// Education floor, raised at build time to whatever the rung's mandated
        /// credentials themselves require (see `job(title:...)`).
        var minEQF: Int = 0
        /// Experience an employer expects. `nil` takes the rung's entry in
        /// `minYearsByTitle` (else 0).
        var minYears: Int? = nil
        /// Pictogram, when this rung's differs from its ladder's.
        var icon: String? = nil
        /// Full title, when it isn't "<label> <ladder name>" — for a rung that
        /// tops a ladder under a name of its own.
        var title: String? = nil
    }

    /// A career ladder: one role at several seniority levels.
    ///
    /// The rungs are **ordered, entry rung first, and that order is the ladder**
    /// — promotion moves to the next index. Previously a ladder existed only as a
    /// coincidence of spelling: rungs were matched by stripping a seniority
    /// prefix off the title and ranked from a prefix table, so two rungs could
    /// tie for "next" (staff and principal both ranked 5, making the promotion
    /// pick shuffle-dependent and stranding staff as a dead end) and a rung whose
    /// title didn't start with a blessed prefix couldn't join its ladder at all.
    struct LadderSpec {
        /// The role irrespective of rung. Becomes `Job.baseTitle`, which tenure
        /// (`Player.experienceByRole`) and the jobs list group by.
        let name: String
        let category: JobCategory
        let icon: String
        /// Ordered, entry rung first. Position is `Job.rung`.
        let rungs: [RungSpec]

        /// The full job title a rung carries.
        func title(for rung: RungSpec) -> String {
            rung.title ?? (rung.label.isEmpty ? name : "\(rung.label) \(name)")
        }
    }

    // MARK: - Per-title soft skills

    /// Soft skills for *one exact rung*, taken exactly as written — the
    /// seniority progression is not applied on top (see `seniority`). Use this
    /// only where a rung is a genuinely different job from the one below it
    /// rather than a more senior version of it: a personal trainer sells and
    /// coaches one client at a time, which is not what the group-class rung
    /// beneath them does. Wins over `softSkillsByBaseTitle`, the same way
    /// `credentialsByFullTitle` wins over `credentialsByBaseTitle`.
    static let softSkillsByFullTitle: [String: SoftSkills] = [
        "Personal Trainer":               .init(communicationAndNetworking: 3, persuasionAndNegotiation: 2, leadershipAndInfluence: 1, carefulnessAndAttentionToDetail: 1, resilienceAndEndurance: 3, stressResistanceAndEmotionalRegulation: 1, empathyAndInterpersonalCare: 3, collaborationAndTeamwork: 1, timeManagementAndPlanning: 2, selfDisciplineAndPerseverance: 3, presentationAndStorytelling: 2),
    ]

    /// Refines roles whose broad category default is clearly wrong — a Sales
    /// Manager needs persuasion an Accountant doesn't, a Counselor needs empathy
    /// a Bookkeeper doesn't. Keyed by *base* title, so every rung of a seniority
    /// ladder inherits its base role's profile. Titles absent here take
    /// `defaultSoftSkills(for:)`.
    static let softSkillsByBaseTitle: [String: SoftSkills] = [
        // Sales / persuasion
        "Retail Salesperson":             .init(communicationAndNetworking: 3, persuasionAndNegotiation: 3, carefulnessAndAttentionToDetail: 1, stressResistanceAndEmotionalRegulation: 1, empathyAndInterpersonalCare: 2, collaborationAndTeamwork: 1, timeManagementAndPlanning: 1, presentationAndStorytelling: 1),
        "Sales Manager":                  .init(analyticalReasoningAndProblemSolving: 1, communicationAndNetworking: 3, persuasionAndNegotiation: 4, leadershipAndInfluence: 3, visionaryThinkingAndAmbition: 1, stressResistanceAndEmotionalRegulation: 2, empathyAndInterpersonalCare: 1, collaborationAndTeamwork: 2, timeManagementAndPlanning: 2, presentationAndStorytelling: 2),
        "Marketing Specialist":           .init(analyticalReasoningAndProblemSolving: 1, creativityAndInsightfulThinking: 3, communicationAndNetworking: 3, persuasionAndNegotiation: 3, visionaryThinkingAndAmbition: 1, timeManagementAndPlanning: 2, presentationAndStorytelling: 3),
        // Breakthrough-gated star tracks. These aren't landed on skill alone —
        // a signature achievement (see `Job.breakthroughFameByRole`) is the
        // real key — but a strong profile still shapes the odds once you're in.
        "Player":                         .init(communicationAndNetworking: 1, leadershipAndInfluence: 1, spacialNavigationAndOrientation: 3, resilienceAndEndurance: 3, stressResistanceAndEmotionalRegulation: 2, collaborationAndTeamwork: 4, selfDisciplineAndPerseverance: 3),
        "Movie Star":                     .init(creativityAndInsightfulThinking: 3, communicationAndNetworking: 2, resilienceAndEndurance: 2, stressResistanceAndEmotionalRegulation: 2, selfDisciplineAndPerseverance: 2, presentationAndStorytelling: 4),
        "Pop Star":                       .init(creativityAndInsightfulThinking: 4, communicationAndNetworking: 2, visionaryThinkingAndAmbition: 2, resilienceAndEndurance: 2, selfDisciplineAndPerseverance: 2, presentationAndStorytelling: 4),
        // Ventures (concrete industry founder plays; no degree gate). Each
        // profile is what *that* business demands — launch odds score the
        // player against it plus raw founder grit (see `Job.founderSkillFit`).
        "Specialty Coffee Roastery":      .init(creativityAndInsightfulThinking: 2, communicationAndNetworking: 2, persuasionAndNegotiation: 2, riskTakingAndInitiative: 2, carefulnessAndAttentionToDetail: 3, tinkeringAndFingerPrecision: 2, timeManagementAndPlanning: 2, selfDisciplineAndPerseverance: 2),
        "Boutique Fitness Studio":        .init(communicationAndNetworking: 3, persuasionAndNegotiation: 2, leadershipAndInfluence: 2, riskTakingAndInitiative: 2, empathyAndInterpersonalCare: 3, timeManagementAndPlanning: 2, selfDisciplineAndPerseverance: 3, presentationAndStorytelling: 2),
        "Farm-to-Table Restaurant":       .init(creativityAndInsightfulThinking: 2, communicationAndNetworking: 2, leadershipAndInfluence: 2, riskTakingAndInitiative: 2, carefulnessAndAttentionToDetail: 2, stressResistanceAndEmotionalRegulation: 3, collaborationAndTeamwork: 2, timeManagementAndPlanning: 3, selfDisciplineAndPerseverance: 2),
        "Indie Game Studio":              .init(analyticalReasoningAndProblemSolving: 3, creativityAndInsightfulThinking: 4, visionaryThinkingAndAmbition: 3, riskTakingAndInitiative: 2, resilienceAndEndurance: 2, collaborationAndTeamwork: 2, selfDisciplineAndPerseverance: 3),
        "Property Development Firm":      .init(analyticalReasoningAndProblemSolving: 3, communicationAndNetworking: 2, persuasionAndNegotiation: 3, visionaryThinkingAndAmbition: 2, riskTakingAndInitiative: 3, carefulnessAndAttentionToDetail: 3, timeManagementAndPlanning: 3, selfDisciplineAndPerseverance: 2),
        "SaaS App Startup":               .init(analyticalReasoningAndProblemSolving: 4, communicationAndNetworking: 2, persuasionAndNegotiation: 3, visionaryThinkingAndAmbition: 4, riskTakingAndInitiative: 3, resilienceAndEndurance: 2, stressResistanceAndEmotionalRegulation: 2, selfDisciplineAndPerseverance: 3),

        // Management / coordination
        "Project Manager":                .init(analyticalReasoningAndProblemSolving: 2, communicationAndNetworking: 3, persuasionAndNegotiation: 2, leadershipAndInfluence: 3, carefulnessAndAttentionToDetail: 2, stressResistanceAndEmotionalRegulation: 2, collaborationAndTeamwork: 3, timeManagementAndPlanning: 4),
        "Event Planner":                  .init(creativityAndInsightfulThinking: 2, communicationAndNetworking: 3, persuasionAndNegotiation: 2, carefulnessAndAttentionToDetail: 2, stressResistanceAndEmotionalRegulation: 2, collaborationAndTeamwork: 2, timeManagementAndPlanning: 4),
        "Hotel Manager":                  .init(analyticalReasoningAndProblemSolving: 1, communicationAndNetworking: 3, persuasionAndNegotiation: 2, leadershipAndInfluence: 3, carefulnessAndAttentionToDetail: 1, stressResistanceAndEmotionalRegulation: 2, empathyAndInterpersonalCare: 2, collaborationAndTeamwork: 2, timeManagementAndPlanning: 3),
        "Human Resources Specialist":     .init(communicationAndNetworking: 3, persuasionAndNegotiation: 2, carefulnessAndAttentionToDetail: 2, stressResistanceAndEmotionalRegulation: 2, empathyAndInterpersonalCare: 3, collaborationAndTeamwork: 2, timeManagementAndPlanning: 2),

        // Finance / detail (low persuasion, high carefulness)
        "Business Analyst":               .init(analyticalReasoningAndProblemSolving: 3, communicationAndNetworking: 3, persuasionAndNegotiation: 1, carefulnessAndAttentionToDetail: 3, timeManagementAndPlanning: 2, presentationAndStorytelling: 2),
        "Accountant":                     .init(analyticalReasoningAndProblemSolving: 3, communicationAndNetworking: 1, carefulnessAndAttentionToDetail: 4, timeManagementAndPlanning: 2, selfDisciplineAndPerseverance: 2),
        "Financial Analyst":              .init(analyticalReasoningAndProblemSolving: 4, communicationAndNetworking: 2, persuasionAndNegotiation: 1, carefulnessAndAttentionToDetail: 3, timeManagementAndPlanning: 2, presentationAndStorytelling: 2),

        // Care / empathy
        "Social Worker":                  .init(communicationAndNetworking: 3, carefulnessAndAttentionToDetail: 1, resilienceAndEndurance: 2, stressResistanceAndEmotionalRegulation: 3, empathyAndInterpersonalCare: 4, collaborationAndTeamwork: 2, timeManagementAndPlanning: 2),
        "Psychologist":                   .init(analyticalReasoningAndProblemSolving: 3, communicationAndNetworking: 3, carefulnessAndAttentionToDetail: 2, stressResistanceAndEmotionalRegulation: 3, empathyAndInterpersonalCare: 4, presentationAndStorytelling: 1),
        "Nursing Aide":                   .init(communicationAndNetworking: 2, carefulnessAndAttentionToDetail: 2, resilienceAndEndurance: 3, stressResistanceAndEmotionalRegulation: 2, empathyAndInterpersonalCare: 3, collaborationAndTeamwork: 2),
        "Licensed Practical Nurse":       .init(communicationAndNetworking: 2, carefulnessAndAttentionToDetail: 3, tinkeringAndFingerPrecision: 1, resilienceAndEndurance: 3, stressResistanceAndEmotionalRegulation: 2, empathyAndInterpersonalCare: 3, collaborationAndTeamwork: 2),
        "Nurse Practitioner":             .init(analyticalReasoningAndProblemSolving: 3, communicationAndNetworking: 3, leadershipAndInfluence: 2, carefulnessAndAttentionToDetail: 4, tinkeringAndFingerPrecision: 2, resilienceAndEndurance: 2, stressResistanceAndEmotionalRegulation: 3, empathyAndInterpersonalCare: 3, collaborationAndTeamwork: 3, timeManagementAndPlanning: 2, presentationAndStorytelling: 1),
        "Flight Attendant":               .init(communicationAndNetworking: 3, carefulnessAndAttentionToDetail: 2, resilienceAndEndurance: 2, stressResistanceAndEmotionalRegulation: 3, empathyAndInterpersonalCare: 2, collaborationAndTeamwork: 2, presentationAndStorytelling: 1),
        "Waiter/Waitress":                .init(communicationAndNetworking: 2, resilienceAndEndurance: 2, stressResistanceAndEmotionalRegulation: 2, empathyAndInterpersonalCare: 2, collaborationAndTeamwork: 2, timeManagementAndPlanning: 1),
        "Receptionist":                   .init(communicationAndNetworking: 3, carefulnessAndAttentionToDetail: 2, stressResistanceAndEmotionalRegulation: 1, empathyAndInterpersonalCare: 2, timeManagementAndPlanning: 1),
        "Hairdresser/Barber":             .init(creativityAndInsightfulThinking: 2, communicationAndNetworking: 3, carefulnessAndAttentionToDetail: 2, tinkeringAndFingerPrecision: 2, empathyAndInterpersonalCare: 2),
        "Beautician/Cosmetologist":       .init(creativityAndInsightfulThinking: 2, communicationAndNetworking: 3, carefulnessAndAttentionToDetail: 2, tinkeringAndFingerPrecision: 2, empathyAndInterpersonalCare: 2),

        // Law (persuasion + analysis)
        "Lawyer":                         .init(analyticalReasoningAndProblemSolving: 4, communicationAndNetworking: 3, persuasionAndNegotiation: 3, carefulnessAndAttentionToDetail: 3, stressResistanceAndEmotionalRegulation: 2, selfDisciplineAndPerseverance: 3, presentationAndStorytelling: 3),
        "Judge":                          .init(analyticalReasoningAndProblemSolving: 4, communicationAndNetworking: 3, leadershipAndInfluence: 2, carefulnessAndAttentionToDetail: 4, stressResistanceAndEmotionalRegulation: 3, selfDisciplineAndPerseverance: 3, presentationAndStorytelling: 2),

        "Fashion Designer":               .init(creativityAndInsightfulThinking: 4, persuasionAndNegotiation: 1, visionaryThinkingAndAmbition: 1, carefulnessAndAttentionToDetail: 2, tinkeringAndFingerPrecision: 1, presentationAndStorytelling: 2),

        // Fitness (personal-brand coaching roles kept; competitive sport ladders removed)
        "Fitness Instructor":             .init(communicationAndNetworking: 3, leadershipAndInfluence: 1, resilienceAndEndurance: 3, stressResistanceAndEmotionalRegulation: 1, empathyAndInterpersonalCare: 2, collaborationAndTeamwork: 1, timeManagementAndPlanning: 1, selfDisciplineAndPerseverance: 2, presentationAndStorytelling: 3),

        // Games — the art, design and engineering that ship them
        "3D Artist":                      .init(creativityAndInsightfulThinking: 4, carefulnessAndAttentionToDetail: 2, tinkeringAndFingerPrecision: 1, spacialNavigationAndOrientation: 3, selfDisciplineAndPerseverance: 2, presentationAndStorytelling: 1),
        "Level Designer":                 .init(analyticalReasoningAndProblemSolving: 3, creativityAndInsightfulThinking: 3, carefulnessAndAttentionToDetail: 2, spacialNavigationAndOrientation: 3, collaborationAndTeamwork: 2, timeManagementAndPlanning: 1),
        "Game Designer":                  .init(analyticalReasoningAndProblemSolving: 3, creativityAndInsightfulThinking: 4, communicationAndNetworking: 2, visionaryThinkingAndAmbition: 2, collaborationAndTeamwork: 2, timeManagementAndPlanning: 2, presentationAndStorytelling: 2),
        "Narrative Designer":             .init(creativityAndInsightfulThinking: 4, communicationAndNetworking: 3, carefulnessAndAttentionToDetail: 2, selfDisciplineAndPerseverance: 2, presentationAndStorytelling: 4),

        // MARK: The biggest employers — the roles most people actually hold
        "Personal Care Aide": .init(communicationAndNetworking: 2, carefulnessAndAttentionToDetail: 2, resilienceAndEndurance: 3, stressResistanceAndEmotionalRegulation: 2, empathyAndInterpersonalCare: 4, collaborationAndTeamwork: 2, timeManagementAndPlanning: 2),
        "Customer Service Representative": .init(communicationAndNetworking: 3, persuasionAndNegotiation: 1, carefulnessAndAttentionToDetail: 2, stressResistanceAndEmotionalRegulation: 3, empathyAndInterpersonalCare: 3, collaborationAndTeamwork: 1, timeManagementAndPlanning: 1),
        "Stocker/Order Filler": .init(carefulnessAndAttentionToDetail: 2, spacialNavigationAndOrientation: 2, resilienceAndEndurance: 3, collaborationAndTeamwork: 1, timeManagementAndPlanning: 2, selfDisciplineAndPerseverance: 1),
        "Cook": .init(carefulnessAndAttentionToDetail: 2, tinkeringAndFingerPrecision: 2, resilienceAndEndurance: 3, stressResistanceAndEmotionalRegulation: 3, collaborationAndTeamwork: 3, timeManagementAndPlanning: 3),
        "Operations Manager": .init(analyticalReasoningAndProblemSolving: 2, communicationAndNetworking: 3, persuasionAndNegotiation: 1, leadershipAndInfluence: 3, carefulnessAndAttentionToDetail: 2, stressResistanceAndEmotionalRegulation: 2, collaborationAndTeamwork: 2, timeManagementAndPlanning: 3, presentationAndStorytelling: 1),
        "Sales Representative": .init(communicationAndNetworking: 3, persuasionAndNegotiation: 3, resilienceAndEndurance: 2, stressResistanceAndEmotionalRegulation: 2, empathyAndInterpersonalCare: 1, collaborationAndTeamwork: 1, timeManagementAndPlanning: 2, presentationAndStorytelling: 2),
        "Store Manager": .init(analyticalReasoningAndProblemSolving: 1, communicationAndNetworking: 3, persuasionAndNegotiation: 2, leadershipAndInfluence: 3, carefulnessAndAttentionToDetail: 2, stressResistanceAndEmotionalRegulation: 2, empathyAndInterpersonalCare: 1, collaborationAndTeamwork: 2, timeManagementAndPlanning: 3),
        "Maintenance & Repair Worker": .init(analyticalReasoningAndProblemSolving: 1, carefulnessAndAttentionToDetail: 2, tinkeringAndFingerPrecision: 3, spacialNavigationAndOrientation: 2, resilienceAndEndurance: 3, outdoorAndWeatherResilience: 2, selfDisciplineAndPerseverance: 1),
        "Bookkeeping Clerk": .init(analyticalReasoningAndProblemSolving: 2, carefulnessAndAttentionToDetail: 4, collaborationAndTeamwork: 1, timeManagementAndPlanning: 3, selfDisciplineAndPerseverance: 2),
        "Teaching Assistant": .init(communicationAndNetworking: 3, carefulnessAndAttentionToDetail: 1, resilienceAndEndurance: 2, stressResistanceAndEmotionalRegulation: 3, empathyAndInterpersonalCare: 3, collaborationAndTeamwork: 3, timeManagementAndPlanning: 1, presentationAndStorytelling: 2),
        "Groundskeeper": .init(carefulnessAndAttentionToDetail: 1, tinkeringAndFingerPrecision: 2, resilienceAndEndurance: 3, outdoorAndWeatherResilience: 4, timeManagementAndPlanning: 1, selfDisciplineAndPerseverance: 2),
        "Childcare Worker": .init(communicationAndNetworking: 3, carefulnessAndAttentionToDetail: 2, resilienceAndEndurance: 3, stressResistanceAndEmotionalRegulation: 3, empathyAndInterpersonalCare: 4, collaborationAndTeamwork: 2, timeManagementAndPlanning: 1, presentationAndStorytelling: 1),
        "Bartender": .init(communicationAndNetworking: 3, persuasionAndNegotiation: 1, carefulnessAndAttentionToDetail: 2, tinkeringAndFingerPrecision: 1, resilienceAndEndurance: 3, stressResistanceAndEmotionalRegulation: 2, empathyAndInterpersonalCare: 2, collaborationAndTeamwork: 2, timeManagementAndPlanning: 2, presentationAndStorytelling: 1),
        "Heavy Equipment Operator": .init(carefulnessAndAttentionToDetail: 3, tinkeringAndFingerPrecision: 2, spacialNavigationAndOrientation: 3, resilienceAndEndurance: 2, stressResistanceAndEmotionalRegulation: 1, outdoorAndWeatherResilience: 2, collaborationAndTeamwork: 1, selfDisciplineAndPerseverance: 1),
        "Pharmacy Technician": .init(analyticalReasoningAndProblemSolving: 1, communicationAndNetworking: 2, carefulnessAndAttentionToDetail: 4, tinkeringAndFingerPrecision: 2, stressResistanceAndEmotionalRegulation: 1, empathyAndInterpersonalCare: 1, collaborationAndTeamwork: 2, timeManagementAndPlanning: 2),
        "Real Estate Agent": .init(communicationAndNetworking: 3, persuasionAndNegotiation: 3, riskTakingAndInitiative: 1, carefulnessAndAttentionToDetail: 2, stressResistanceAndEmotionalRegulation: 2, empathyAndInterpersonalCare: 2, timeManagementAndPlanning: 2, presentationAndStorytelling: 2),
        "Insurance Agent": .init(analyticalReasoningAndProblemSolving: 1, communicationAndNetworking: 3, persuasionAndNegotiation: 3, carefulnessAndAttentionToDetail: 2, stressResistanceAndEmotionalRegulation: 1, empathyAndInterpersonalCare: 1, timeManagementAndPlanning: 2, presentationAndStorytelling: 1),
        "Bank Teller": .init(communicationAndNetworking: 3, carefulnessAndAttentionToDetail: 3, stressResistanceAndEmotionalRegulation: 1, empathyAndInterpersonalCare: 1, collaborationAndTeamwork: 1, timeManagementAndPlanning: 1),
        "Cashier": .init(communicationAndNetworking: 2, carefulnessAndAttentionToDetail: 2, resilienceAndEndurance: 2, stressResistanceAndEmotionalRegulation: 2, empathyAndInterpersonalCare: 1, collaborationAndTeamwork: 1),

        // MARK: Health — the clinical bar rises steeply with what you may do alone
        "Registered Nurse": .init(analyticalReasoningAndProblemSolving: 2, communicationAndNetworking: 3, leadershipAndInfluence: 1, carefulnessAndAttentionToDetail: 4, tinkeringAndFingerPrecision: 2, resilienceAndEndurance: 3, stressResistanceAndEmotionalRegulation: 3, empathyAndInterpersonalCare: 3, collaborationAndTeamwork: 3, timeManagementAndPlanning: 2, selfDisciplineAndPerseverance: 2, presentationAndStorytelling: 1),
        "Medical Assistant": .init(communicationAndNetworking: 2, carefulnessAndAttentionToDetail: 3, resilienceAndEndurance: 2, stressResistanceAndEmotionalRegulation: 2, empathyAndInterpersonalCare: 3, collaborationAndTeamwork: 2, timeManagementAndPlanning: 2),
        "Dental Assistant": .init(communicationAndNetworking: 2, carefulnessAndAttentionToDetail: 3, tinkeringAndFingerPrecision: 3, stressResistanceAndEmotionalRegulation: 1, empathyAndInterpersonalCare: 2, collaborationAndTeamwork: 2, timeManagementAndPlanning: 1),
        "Paramedic": .init(analyticalReasoningAndProblemSolving: 2, communicationAndNetworking: 2, carefulnessAndAttentionToDetail: 3, tinkeringAndFingerPrecision: 2, spacialNavigationAndOrientation: 2, resilienceAndEndurance: 4, stressResistanceAndEmotionalRegulation: 4, empathyAndInterpersonalCare: 3, collaborationAndTeamwork: 3, timeManagementAndPlanning: 1),
        "Physiotherapist": .init(analyticalReasoningAndProblemSolving: 2, communicationAndNetworking: 3, carefulnessAndAttentionToDetail: 3, tinkeringAndFingerPrecision: 3, spacialNavigationAndOrientation: 1, resilienceAndEndurance: 3, stressResistanceAndEmotionalRegulation: 2, empathyAndInterpersonalCare: 4, collaborationAndTeamwork: 2, timeManagementAndPlanning: 2, presentationAndStorytelling: 1),
        "Physician": .init(analyticalReasoningAndProblemSolving: 4, communicationAndNetworking: 3, carefulnessAndAttentionToDetail: 4, tinkeringAndFingerPrecision: 1, resilienceAndEndurance: 3, stressResistanceAndEmotionalRegulation: 3, empathyAndInterpersonalCare: 3, collaborationAndTeamwork: 2, timeManagementAndPlanning: 2, selfDisciplineAndPerseverance: 3),
        "Surgeon": .init(analyticalReasoningAndProblemSolving: 4, communicationAndNetworking: 2, carefulnessAndAttentionToDetail: 5, tinkeringAndFingerPrecision: 5, spacialNavigationAndOrientation: 3, resilienceAndEndurance: 4, stressResistanceAndEmotionalRegulation: 5, empathyAndInterpersonalCare: 2, collaborationAndTeamwork: 3, selfDisciplineAndPerseverance: 4),
        "Anesthesiologist": .init(analyticalReasoningAndProblemSolving: 4, communicationAndNetworking: 2, carefulnessAndAttentionToDetail: 5, tinkeringAndFingerPrecision: 3, spacialNavigationAndOrientation: 2, resilienceAndEndurance: 3, stressResistanceAndEmotionalRegulation: 5, empathyAndInterpersonalCare: 2, collaborationAndTeamwork: 3, selfDisciplineAndPerseverance: 3),
        "Dentist": .init(analyticalReasoningAndProblemSolving: 3, communicationAndNetworking: 3, carefulnessAndAttentionToDetail: 4, tinkeringAndFingerPrecision: 5, spacialNavigationAndOrientation: 2, stressResistanceAndEmotionalRegulation: 3, empathyAndInterpersonalCare: 2, collaborationAndTeamwork: 2, timeManagementAndPlanning: 2),
        "Pharmacist": .init(analyticalReasoningAndProblemSolving: 3, communicationAndNetworking: 3, carefulnessAndAttentionToDetail: 5, tinkeringAndFingerPrecision: 1, stressResistanceAndEmotionalRegulation: 2, empathyAndInterpersonalCare: 2, collaborationAndTeamwork: 2, timeManagementAndPlanning: 2),
        "Veterinarian": .init(analyticalReasoningAndProblemSolving: 3, communicationAndNetworking: 3, carefulnessAndAttentionToDetail: 4, tinkeringAndFingerPrecision: 3, resilienceAndEndurance: 3, stressResistanceAndEmotionalRegulation: 3, empathyAndInterpersonalCare: 3, collaborationAndTeamwork: 2, timeManagementAndPlanning: 2),
        "Chief Medical Officer": .init(analyticalReasoningAndProblemSolving: 4, communicationAndNetworking: 4, persuasionAndNegotiation: 3, leadershipAndInfluence: 5, visionaryThinkingAndAmbition: 4, carefulnessAndAttentionToDetail: 4, stressResistanceAndEmotionalRegulation: 4, empathyAndInterpersonalCare: 2, collaborationAndTeamwork: 4, timeManagementAndPlanning: 4, presentationAndStorytelling: 3),

        // MARK: Technology
        "IT Support Specialist": .init(analyticalReasoningAndProblemSolving: 2, communicationAndNetworking: 3, carefulnessAndAttentionToDetail: 2, tinkeringAndFingerPrecision: 2, stressResistanceAndEmotionalRegulation: 2, empathyAndInterpersonalCare: 1, collaborationAndTeamwork: 2, timeManagementAndPlanning: 2),
        "Software Tester/QA": .init(analyticalReasoningAndProblemSolving: 2, carefulnessAndAttentionToDetail: 4, collaborationAndTeamwork: 2, timeManagementAndPlanning: 2, selfDisciplineAndPerseverance: 2),
        "Cybersecurity Analyst": .init(analyticalReasoningAndProblemSolving: 4, communicationAndNetworking: 2, carefulnessAndAttentionToDetail: 4, stressResistanceAndEmotionalRegulation: 2, collaborationAndTeamwork: 2, selfDisciplineAndPerseverance: 3),
        "Cloud Architect": .init(analyticalReasoningAndProblemSolving: 4, communicationAndNetworking: 3, visionaryThinkingAndAmbition: 2, carefulnessAndAttentionToDetail: 4, collaborationAndTeamwork: 2, timeManagementAndPlanning: 3, selfDisciplineAndPerseverance: 3, presentationAndStorytelling: 2),
        "Data Analyst": .init(analyticalReasoningAndProblemSolving: 3, communicationAndNetworking: 2, carefulnessAndAttentionToDetail: 3, collaborationAndTeamwork: 2, timeManagementAndPlanning: 2, presentationAndStorytelling: 2),
        "Data Scientist": .init(analyticalReasoningAndProblemSolving: 4, creativityAndInsightfulThinking: 2, communicationAndNetworking: 2, carefulnessAndAttentionToDetail: 3, collaborationAndTeamwork: 2, timeManagementAndPlanning: 2, presentationAndStorytelling: 2),
        "Systems Administrator": .init(analyticalReasoningAndProblemSolving: 2, carefulnessAndAttentionToDetail: 3, tinkeringAndFingerPrecision: 2, stressResistanceAndEmotionalRegulation: 2, collaborationAndTeamwork: 2, timeManagementAndPlanning: 2, selfDisciplineAndPerseverance: 2),
        "Chief Technology Officer": .init(analyticalReasoningAndProblemSolving: 4, creativityAndInsightfulThinking: 2, communicationAndNetworking: 4, persuasionAndNegotiation: 3, leadershipAndInfluence: 5, visionaryThinkingAndAmbition: 5, riskTakingAndInitiative: 2, carefulnessAndAttentionToDetail: 3, collaborationAndTeamwork: 4, timeManagementAndPlanning: 4, selfDisciplineAndPerseverance: 3, presentationAndStorytelling: 3),

        // MARK: Engineering — each discipline leans on a different faculty
        "Architect": .init(analyticalReasoningAndProblemSolving: 3, creativityAndInsightfulThinking: 4, communicationAndNetworking: 3, carefulnessAndAttentionToDetail: 3, spacialNavigationAndOrientation: 4, collaborationAndTeamwork: 2, timeManagementAndPlanning: 3, presentationAndStorytelling: 2),
        "Civil Engineer": .init(analyticalReasoningAndProblemSolving: 3, carefulnessAndAttentionToDetail: 4, spacialNavigationAndOrientation: 3, resilienceAndEndurance: 2, outdoorAndWeatherResilience: 2, collaborationAndTeamwork: 2, timeManagementAndPlanning: 2, selfDisciplineAndPerseverance: 2),
        "Mechanical Engineer": .init(analyticalReasoningAndProblemSolving: 3, creativityAndInsightfulThinking: 2, carefulnessAndAttentionToDetail: 3, tinkeringAndFingerPrecision: 2, spacialNavigationAndOrientation: 3, collaborationAndTeamwork: 2, timeManagementAndPlanning: 2, selfDisciplineAndPerseverance: 2),
        "Electrical Engineer": .init(analyticalReasoningAndProblemSolving: 4, carefulnessAndAttentionToDetail: 4, tinkeringAndFingerPrecision: 2, spacialNavigationAndOrientation: 2, collaborationAndTeamwork: 2, timeManagementAndPlanning: 2, selfDisciplineAndPerseverance: 2),
        "Chemical Engineer": .init(analyticalReasoningAndProblemSolving: 3, carefulnessAndAttentionToDetail: 4, spacialNavigationAndOrientation: 1, stressResistanceAndEmotionalRegulation: 2, collaborationAndTeamwork: 2, timeManagementAndPlanning: 2, selfDisciplineAndPerseverance: 2),
        "Aerospace Engineer": .init(analyticalReasoningAndProblemSolving: 4, creativityAndInsightfulThinking: 2, carefulnessAndAttentionToDetail: 4, spacialNavigationAndOrientation: 3, collaborationAndTeamwork: 2, timeManagementAndPlanning: 2, selfDisciplineAndPerseverance: 3),

        // MARK: Science
        "Lab Technician": .init(analyticalReasoningAndProblemSolving: 2, carefulnessAndAttentionToDetail: 4, tinkeringAndFingerPrecision: 2, collaborationAndTeamwork: 2, timeManagementAndPlanning: 2, selfDisciplineAndPerseverance: 2),
        "Research Scientist": .init(analyticalReasoningAndProblemSolving: 4, creativityAndInsightfulThinking: 3, communicationAndNetworking: 2, carefulnessAndAttentionToDetail: 4, collaborationAndTeamwork: 2, timeManagementAndPlanning: 2, selfDisciplineAndPerseverance: 4, presentationAndStorytelling: 2),

        // MARK: Business — the money, the advice, and the people who sell both
        "Investment Banker": .init(analyticalReasoningAndProblemSolving: 4, communicationAndNetworking: 3, persuasionAndNegotiation: 3, carefulnessAndAttentionToDetail: 3, resilienceAndEndurance: 4, stressResistanceAndEmotionalRegulation: 3, collaborationAndTeamwork: 2, timeManagementAndPlanning: 3, selfDisciplineAndPerseverance: 3, presentationAndStorytelling: 2),
        "Management Consultant": .init(analyticalReasoningAndProblemSolving: 4, communicationAndNetworking: 3, persuasionAndNegotiation: 2, carefulnessAndAttentionToDetail: 2, stressResistanceAndEmotionalRegulation: 2, collaborationAndTeamwork: 2, timeManagementAndPlanning: 3, presentationAndStorytelling: 3),
        "Translator/Interpreter": .init(analyticalReasoningAndProblemSolving: 1, communicationAndNetworking: 4, carefulnessAndAttentionToDetail: 4, stressResistanceAndEmotionalRegulation: 3, timeManagementAndPlanning: 2, presentationAndStorytelling: 1),
        "Marketing Director": .init(analyticalReasoningAndProblemSolving: 2, creativityAndInsightfulThinking: 3, communicationAndNetworking: 4, persuasionAndNegotiation: 3, leadershipAndInfluence: 4, visionaryThinkingAndAmbition: 3, carefulnessAndAttentionToDetail: 2, collaborationAndTeamwork: 3, timeManagementAndPlanning: 3, presentationAndStorytelling: 4),
        "Sales Director": .init(analyticalReasoningAndProblemSolving: 2, communicationAndNetworking: 4, persuasionAndNegotiation: 5, leadershipAndInfluence: 4, visionaryThinkingAndAmbition: 2, stressResistanceAndEmotionalRegulation: 3, collaborationAndTeamwork: 3, timeManagementAndPlanning: 3, presentationAndStorytelling: 3),
        "Chief Executive Officer": .init(analyticalReasoningAndProblemSolving: 3, creativityAndInsightfulThinking: 2, communicationAndNetworking: 4, persuasionAndNegotiation: 4, leadershipAndInfluence: 6, visionaryThinkingAndAmbition: 5, riskTakingAndInitiative: 3, carefulnessAndAttentionToDetail: 2, stressResistanceAndEmotionalRegulation: 4, collaborationAndTeamwork: 3, timeManagementAndPlanning: 3, selfDisciplineAndPerseverance: 3, presentationAndStorytelling: 4),

        // MARK: Law
        "Paralegal": .init(analyticalReasoningAndProblemSolving: 2, communicationAndNetworking: 2, carefulnessAndAttentionToDetail: 4, timeManagementAndPlanning: 3, selfDisciplineAndPerseverance: 2),
        "Managing Partner": .init(analyticalReasoningAndProblemSolving: 4, communicationAndNetworking: 4, persuasionAndNegotiation: 5, leadershipAndInfluence: 4, visionaryThinkingAndAmbition: 3, carefulnessAndAttentionToDetail: 3, stressResistanceAndEmotionalRegulation: 3, collaborationAndTeamwork: 2, timeManagementAndPlanning: 3, selfDisciplineAndPerseverance: 3, presentationAndStorytelling: 4),

        // MARK: Design and show business — a brief, a deadline, and an audience
        "UX/UI Designer": .init(analyticalReasoningAndProblemSolving: 3, creativityAndInsightfulThinking: 3, communicationAndNetworking: 2, carefulnessAndAttentionToDetail: 3, spacialNavigationAndOrientation: 2, collaborationAndTeamwork: 2, timeManagementAndPlanning: 2, presentationAndStorytelling: 2),
        "Animator": .init(creativityAndInsightfulThinking: 4, carefulnessAndAttentionToDetail: 3, tinkeringAndFingerPrecision: 3, spacialNavigationAndOrientation: 2, timeManagementAndPlanning: 2, selfDisciplineAndPerseverance: 3),
        "Graphic Artist": .init(creativityAndInsightfulThinking: 3, communicationAndNetworking: 2, carefulnessAndAttentionToDetail: 2, tinkeringAndFingerPrecision: 1, timeManagementAndPlanning: 2, selfDisciplineAndPerseverance: 2, presentationAndStorytelling: 1),
        "Interior Designer": .init(creativityAndInsightfulThinking: 3, communicationAndNetworking: 3, persuasionAndNegotiation: 1, carefulnessAndAttentionToDetail: 2, spacialNavigationAndOrientation: 3, timeManagementAndPlanning: 2, presentationAndStorytelling: 2),
        "Actor": .init(creativityAndInsightfulThinking: 3, communicationAndNetworking: 2, resilienceAndEndurance: 3, stressResistanceAndEmotionalRegulation: 3, selfDisciplineAndPerseverance: 3, presentationAndStorytelling: 4),
        "Musician": .init(creativityAndInsightfulThinking: 4, communicationAndNetworking: 2, tinkeringAndFingerPrecision: 3, resilienceAndEndurance: 2, selfDisciplineAndPerseverance: 4, presentationAndStorytelling: 3),
        "Journalist": .init(analyticalReasoningAndProblemSolving: 2, communicationAndNetworking: 4, persuasionAndNegotiation: 1, carefulnessAndAttentionToDetail: 3, resilienceAndEndurance: 2, stressResistanceAndEmotionalRegulation: 2, timeManagementAndPlanning: 3, presentationAndStorytelling: 3),
        "Photographer": .init(creativityAndInsightfulThinking: 4, communicationAndNetworking: 2, carefulnessAndAttentionToDetail: 2, spacialNavigationAndOrientation: 3, resilienceAndEndurance: 2, outdoorAndWeatherResilience: 2, timeManagementAndPlanning: 2),
        "Content Writer": .init(creativityAndInsightfulThinking: 3, communicationAndNetworking: 2, carefulnessAndAttentionToDetail: 3, timeManagementAndPlanning: 2, selfDisciplineAndPerseverance: 2, presentationAndStorytelling: 2),
        "Video Editor": .init(creativityAndInsightfulThinking: 3, carefulnessAndAttentionToDetail: 4, tinkeringAndFingerPrecision: 1, timeManagementAndPlanning: 2, selfDisciplineAndPerseverance: 3),
        "Social Media Manager": .init(creativityAndInsightfulThinking: 3, communicationAndNetworking: 3, persuasionAndNegotiation: 2, carefulnessAndAttentionToDetail: 2, stressResistanceAndEmotionalRegulation: 2, timeManagementAndPlanning: 2, presentationAndStorytelling: 3),
        "TV Presenter": .init(creativityAndInsightfulThinking: 2, communicationAndNetworking: 3, resilienceAndEndurance: 2, stressResistanceAndEmotionalRegulation: 3, timeManagementAndPlanning: 1, presentationAndStorytelling: 4),
        "Art Director": .init(creativityAndInsightfulThinking: 5, communicationAndNetworking: 3, persuasionAndNegotiation: 2, leadershipAndInfluence: 3, visionaryThinkingAndAmbition: 3, carefulnessAndAttentionToDetail: 3, collaborationAndTeamwork: 3, timeManagementAndPlanning: 3, presentationAndStorytelling: 3),

        // MARK: Hospitality — the kitchen and the rooms behind the dining room
        "Chef": .init(creativityAndInsightfulThinking: 3, communicationAndNetworking: 1, leadershipAndInfluence: 2, carefulnessAndAttentionToDetail: 3, tinkeringAndFingerPrecision: 2, resilienceAndEndurance: 4, stressResistanceAndEmotionalRegulation: 4, collaborationAndTeamwork: 3, timeManagementAndPlanning: 3),
        "Baker": .init(creativityAndInsightfulThinking: 2, carefulnessAndAttentionToDetail: 3, tinkeringAndFingerPrecision: 3, resilienceAndEndurance: 3, stressResistanceAndEmotionalRegulation: 1, timeManagementAndPlanning: 3, selfDisciplineAndPerseverance: 2),
        "Food Preparation Worker": .init(carefulnessAndAttentionToDetail: 2, tinkeringAndFingerPrecision: 2, resilienceAndEndurance: 3, stressResistanceAndEmotionalRegulation: 2, collaborationAndTeamwork: 2, timeManagementAndPlanning: 2),
        "Fast Food Worker": .init(communicationAndNetworking: 2, carefulnessAndAttentionToDetail: 1, resilienceAndEndurance: 2, stressResistanceAndEmotionalRegulation: 2, collaborationAndTeamwork: 2, timeManagementAndPlanning: 2),
        "Dishwasher": .init(resilienceAndEndurance: 3, stressResistanceAndEmotionalRegulation: 1, collaborationAndTeamwork: 2, timeManagementAndPlanning: 1),
        "Housekeeper": .init(carefulnessAndAttentionToDetail: 3, resilienceAndEndurance: 3, collaborationAndTeamwork: 1, timeManagementAndPlanning: 2, selfDisciplineAndPerseverance: 1),
        "Janitor/Cleaner": .init(carefulnessAndAttentionToDetail: 2, resilienceAndEndurance: 3, collaborationAndTeamwork: 1, timeManagementAndPlanning: 2, selfDisciplineAndPerseverance: 2),

        // MARK: Trades, site work, and the line
        "Electrician": .init(analyticalReasoningAndProblemSolving: 2, carefulnessAndAttentionToDetail: 4, tinkeringAndFingerPrecision: 3, spacialNavigationAndOrientation: 2, resilienceAndEndurance: 2, outdoorAndWeatherResilience: 1, collaborationAndTeamwork: 1, selfDisciplineAndPerseverance: 2),
        "Plumber": .init(analyticalReasoningAndProblemSolving: 2, carefulnessAndAttentionToDetail: 3, tinkeringAndFingerPrecision: 4, spacialNavigationAndOrientation: 2, resilienceAndEndurance: 3, outdoorAndWeatherResilience: 2, collaborationAndTeamwork: 1, selfDisciplineAndPerseverance: 2),
        "Carpenter": .init(carefulnessAndAttentionToDetail: 3, tinkeringAndFingerPrecision: 4, spacialNavigationAndOrientation: 3, resilienceAndEndurance: 3, outdoorAndWeatherResilience: 2, collaborationAndTeamwork: 1, selfDisciplineAndPerseverance: 2),
        "HVAC Technician": .init(analyticalReasoningAndProblemSolving: 2, carefulnessAndAttentionToDetail: 3, tinkeringAndFingerPrecision: 4, spacialNavigationAndOrientation: 2, resilienceAndEndurance: 2, outdoorAndWeatherResilience: 2, timeManagementAndPlanning: 2),
        "Roofer": .init(carefulnessAndAttentionToDetail: 2, tinkeringAndFingerPrecision: 2, resilienceAndEndurance: 4, outdoorAndWeatherResilience: 4, collaborationAndTeamwork: 2),
        "Construction Laborer": .init(carefulnessAndAttentionToDetail: 1, tinkeringAndFingerPrecision: 2, resilienceAndEndurance: 4, outdoorAndWeatherResilience: 3, collaborationAndTeamwork: 2),
        "Painter (Construction)": .init(carefulnessAndAttentionToDetail: 3, tinkeringAndFingerPrecision: 3, resilienceAndEndurance: 3, outdoorAndWeatherResilience: 2, timeManagementAndPlanning: 1),
        "Welder": .init(carefulnessAndAttentionToDetail: 3, tinkeringAndFingerPrecision: 4, spacialNavigationAndOrientation: 2, resilienceAndEndurance: 3, stressResistanceAndEmotionalRegulation: 1, selfDisciplineAndPerseverance: 2),
        "Machinist": .init(analyticalReasoningAndProblemSolving: 2, carefulnessAndAttentionToDetail: 4, tinkeringAndFingerPrecision: 4, spacialNavigationAndOrientation: 3, selfDisciplineAndPerseverance: 2),
        "Machine Operator": .init(carefulnessAndAttentionToDetail: 3, tinkeringAndFingerPrecision: 2, resilienceAndEndurance: 3, collaborationAndTeamwork: 1, selfDisciplineAndPerseverance: 2),
        "Factory Worker": .init(carefulnessAndAttentionToDetail: 2, tinkeringAndFingerPrecision: 2, resilienceAndEndurance: 3, collaborationAndTeamwork: 1, selfDisciplineAndPerseverance: 1),
        "Assembler": .init(carefulnessAndAttentionToDetail: 3, tinkeringAndFingerPrecision: 3, resilienceAndEndurance: 2, collaborationAndTeamwork: 1, selfDisciplineAndPerseverance: 1),
        "Quality Control Inspector": .init(analyticalReasoningAndProblemSolving: 2, carefulnessAndAttentionToDetail: 5, tinkeringAndFingerPrecision: 1, collaborationAndTeamwork: 1, timeManagementAndPlanning: 2, selfDisciplineAndPerseverance: 2),

        // MARK: Moving people and goods
        "Airline Pilot": .init(analyticalReasoningAndProblemSolving: 3, communicationAndNetworking: 3, carefulnessAndAttentionToDetail: 4, spacialNavigationAndOrientation: 4, resilienceAndEndurance: 2, stressResistanceAndEmotionalRegulation: 4, collaborationAndTeamwork: 3, timeManagementAndPlanning: 3, selfDisciplineAndPerseverance: 3),
        "Aircraft Maintenance Technician": .init(analyticalReasoningAndProblemSolving: 2, carefulnessAndAttentionToDetail: 5, tinkeringAndFingerPrecision: 4, spacialNavigationAndOrientation: 2, collaborationAndTeamwork: 2, timeManagementAndPlanning: 2, selfDisciplineAndPerseverance: 2),
        "Dispatcher": .init(analyticalReasoningAndProblemSolving: 2, communicationAndNetworking: 3, carefulnessAndAttentionToDetail: 3, stressResistanceAndEmotionalRegulation: 3, collaborationAndTeamwork: 2, timeManagementAndPlanning: 4),
        "Logistics Coordinator": .init(analyticalReasoningAndProblemSolving: 2, communicationAndNetworking: 3, carefulnessAndAttentionToDetail: 3, collaborationAndTeamwork: 2, timeManagementAndPlanning: 4, selfDisciplineAndPerseverance: 2),
        "Truck Driver": .init(carefulnessAndAttentionToDetail: 3, spacialNavigationAndOrientation: 3, resilienceAndEndurance: 3, stressResistanceAndEmotionalRegulation: 2, outdoorAndWeatherResilience: 1, timeManagementAndPlanning: 2, selfDisciplineAndPerseverance: 2),
        "Bus Driver": .init(communicationAndNetworking: 2, carefulnessAndAttentionToDetail: 3, spacialNavigationAndOrientation: 2, resilienceAndEndurance: 2, stressResistanceAndEmotionalRegulation: 3, empathyAndInterpersonalCare: 1, timeManagementAndPlanning: 2),
        "Taxi Driver": .init(communicationAndNetworking: 2, carefulnessAndAttentionToDetail: 2, spacialNavigationAndOrientation: 3, resilienceAndEndurance: 2, stressResistanceAndEmotionalRegulation: 2, timeManagementAndPlanning: 1),
        "Light Truck Delivery Driver": .init(carefulnessAndAttentionToDetail: 2, spacialNavigationAndOrientation: 3, resilienceAndEndurance: 3, outdoorAndWeatherResilience: 1, timeManagementAndPlanning: 3),
        "Delivery Courier": .init(carefulnessAndAttentionToDetail: 2, spacialNavigationAndOrientation: 3, resilienceAndEndurance: 3, outdoorAndWeatherResilience: 2, timeManagementAndPlanning: 2),
        "Mover": .init(tinkeringAndFingerPrecision: 1, spacialNavigationAndOrientation: 2, resilienceAndEndurance: 4, outdoorAndWeatherResilience: 2, collaborationAndTeamwork: 2),
        "Warehouse Worker": .init(carefulnessAndAttentionToDetail: 2, spacialNavigationAndOrientation: 1, resilienceAndEndurance: 3, collaborationAndTeamwork: 1, timeManagementAndPlanning: 1),
        "Forklift Operator": .init(carefulnessAndAttentionToDetail: 3, tinkeringAndFingerPrecision: 1, spacialNavigationAndOrientation: 3, resilienceAndEndurance: 2, collaborationAndTeamwork: 1, selfDisciplineAndPerseverance: 1),
        "Mechanic": .init(analyticalReasoningAndProblemSolving: 2, carefulnessAndAttentionToDetail: 3, tinkeringAndFingerPrecision: 4, spacialNavigationAndOrientation: 2, resilienceAndEndurance: 2, collaborationAndTeamwork: 1, selfDisciplineAndPerseverance: 2),

        // MARK: Public services
        "Police Officer": .init(communicationAndNetworking: 3, leadershipAndInfluence: 1, carefulnessAndAttentionToDetail: 3, resilienceAndEndurance: 3, stressResistanceAndEmotionalRegulation: 4, empathyAndInterpersonalCare: 2, outdoorAndWeatherResilience: 2, collaborationAndTeamwork: 3, selfDisciplineAndPerseverance: 2),
        "Firefighter": .init(communicationAndNetworking: 2, carefulnessAndAttentionToDetail: 2, spacialNavigationAndOrientation: 2, resilienceAndEndurance: 4, stressResistanceAndEmotionalRegulation: 4, empathyAndInterpersonalCare: 2, outdoorAndWeatherResilience: 3, collaborationAndTeamwork: 4, selfDisciplineAndPerseverance: 2),
        "Municipal Worker": .init(carefulnessAndAttentionToDetail: 2, tinkeringAndFingerPrecision: 2, resilienceAndEndurance: 3, outdoorAndWeatherResilience: 3, collaborationAndTeamwork: 2, timeManagementAndPlanning: 1),
        "Security Guard": .init(communicationAndNetworking: 2, carefulnessAndAttentionToDetail: 3, resilienceAndEndurance: 2, stressResistanceAndEmotionalRegulation: 2, outdoorAndWeatherResilience: 1, collaborationAndTeamwork: 1, selfDisciplineAndPerseverance: 1),

        // MARK: Land work
        "Farmhand": .init(tinkeringAndFingerPrecision: 1, resilienceAndEndurance: 4, outdoorAndWeatherResilience: 4, collaborationAndTeamwork: 1, selfDisciplineAndPerseverance: 2),
        "Farmer": .init(analyticalReasoningAndProblemSolving: 1, carefulnessAndAttentionToDetail: 2, tinkeringAndFingerPrecision: 3, spacialNavigationAndOrientation: 1, resilienceAndEndurance: 4, outdoorAndWeatherResilience: 4, timeManagementAndPlanning: 3, selfDisciplineAndPerseverance: 3),

        // MARK: Education
        "Teacher": .init(creativityAndInsightfulThinking: 2, communicationAndNetworking: 3, leadershipAndInfluence: 1, carefulnessAndAttentionToDetail: 2, resilienceAndEndurance: 2, stressResistanceAndEmotionalRegulation: 3, empathyAndInterpersonalCare: 3, collaborationAndTeamwork: 2, timeManagementAndPlanning: 3, selfDisciplineAndPerseverance: 2, presentationAndStorytelling: 4),
        "Tutor": .init(communicationAndNetworking: 3, carefulnessAndAttentionToDetail: 2, stressResistanceAndEmotionalRegulation: 2, empathyAndInterpersonalCare: 3, timeManagementAndPlanning: 2, presentationAndStorytelling: 3),
    ]

    // MARK: - Credentials

    /// Senior-grade credentials keyed on the *full* title, so they attach only to
    /// the senior or standalone rung and not to a ladder's entry rung (a junior
    /// analyst shouldn't need the CFA). An entry here wins over
    /// `credentialsByBaseTitle`, and an explicit empty `HardSkills()` means "this
    /// rung needs none" — which is how a trade apprentice works toward the
    /// licence their journeyman rung requires.
    static let credentialsByFullTitle: [String: HardSkills] = [
        "Accountant": HardSkills(trainings: [.cpa]),
        "Senior Accountant": HardSkills(trainings: [.cpa]),
        // Trade apprentices work *toward* the license, so the entry rung
        // carries none — even though the journeyman base role (Electrician /
        // Plumber, same base title) requires it.
        "Apprentice Electrician": HardSkills(),
        "Apprentice Plumber": HardSkills(),
        "Apprentice Carpenter": HardSkills(),
        // Promotions that demand a *senior* credential on top of the base
        // role's license: master trade licenses and the airline transport
        // pilot certificate. Listed on the full title so only the top rung
        // is gated, not the journeyman/first-officer rungs below it.
        "Master Electrician": HardSkills(trainings: [.electrician, .masterElectrician]),
        "Master Plumber": HardSkills(trainings: [.plumber, .masterPlumber]),
        "Airline Captain": HardSkills(trainings: [.commercialPilot, .airlineTransportPilot]),
        // The PE license is what lets a senior engineer stamp and sign off on
        // designs — juniors work under a PE as engineers-in-training, so the
        // license gates the senior rung, not the entry rungs.
        "Senior Civil Engineer": HardSkills(trainings: [.professionalEngineer]),
        "Senior Mechanical Engineer": HardSkills(trainings: [.professionalEngineer]),
        "Senior Electrical Engineer": HardSkills(trainings: [.professionalEngineer]),
        // Attending physicians and medical leadership hold the medical license
        // and are board-certified in their specialty after residency.
        "Senior Physician": HardSkills(trainings: [.medicalLicense, .boardCertified]),
        "Chief Medical Officer": HardSkills(trainings: [.medicalLicense, .boardCertified]),
    ]

    /// Credentials intrinsic to a role, keyed by base title so every rung of a
    /// ladder inherits them. In regulated fields these hard-gate hiring;
    /// elsewhere they are a helpful signal only.
    static let credentialsByBaseTitle: [String: HardSkills] = [
        // Drivers / transport
        "Light Truck Delivery Driver": HardSkills(trainings: [.drivers]),
        "Taxi Driver": HardSkills(trainings: [.drivers]),
        "Truck Driver": HardSkills(trainings: [.cdl]),
        "Bus Driver": HardSkills(trainings: [.cdl]),
        // Every rung flies on a commercial licence; the captain's rung adds the
        // ATP on top (see `credentialsByFullTitle`, which wins over this).
        "Airline Pilot": HardSkills(trainings: [.commercialPilot]),
        // Only a certificated mechanic may sign an aircraft back into service.
        "Aircraft Maintenance Technician": HardSkills(trainings: [.airframePowerplant]),
        // Trades — licensed by law in most jurisdictions
        "Electrician": HardSkills(trainings: [.electrician]),
        "Plumber": HardSkills(trainings: [.plumber]),
        "Architect": HardSkills(trainings: [.architect]),
        // Refrigerant handling is federally certified, and there is no
        // air-conditioning work without touching refrigerant.
        "HVAC Technician": HardSkills(trainings: [.epaRefrigerant]),
        // Health — licenses + entry-level certs. The nursing ladder climbs
        // by credential: aide (CNA) → practical nurse (LPN) → registered
        // nurse (RN) → nurse practitioner (RN + NP).
        "Registered Nurse": HardSkills(trainings: [.nurse]),
        "Nurse Practitioner": HardSkills(trainings: [.nurse, .np]),
        "Licensed Practical Nurse": HardSkills(trainings: [.lpn]),
        "Physician": HardSkills(trainings: [.medicalLicense]),
        "Surgeon": HardSkills(trainings: [.medicalLicense]),
        "Anesthesiologist": HardSkills(trainings: [.medicalLicense]),
        "Dentist": HardSkills(trainings: [.dentalLicense]),
        "Pharmacist": HardSkills(trainings: [.pharmacistLicense]),
        "Veterinarian": HardSkills(trainings: [.veterinaryLicense]),
        "Paramedic": HardSkills(trainings: [.emt]),
        // Dispensing under supervision is a registered role of its own — the
        // way into a pharmacy without the pharmacist's doctorate.
        "Pharmacy Technician": HardSkills(trainings: [.pharmacyTechnician]),
        // Both are doctoral, licensed professions: the degree qualifies you, the
        // licence is what lets you treat anyone.
        "Psychologist": HardSkills(trainings: [.psychologyLicense]),
        "Physiotherapist": HardSkills(trainings: [.physicalTherapyLicense]),
        "Dental Assistant": HardSkills(trainings: [.dentalAssistant]),
        "Nursing Aide": HardSkills(trainings: [.cna]),
        // Law / public services. Keys are base titles, so one entry covers every
        // rung of a ladder ("Firefighter" also gates Senior/Lead Firefighter).
        "Lawyer": HardSkills(trainings: [.bar]),
        "Judge": HardSkills(trainings: [.bar]),
        "Managing Partner": HardSkills(trainings: [.bar]),
        "Firefighter": HardSkills(trainings: [.emt]),
        // Nobody is sworn in off the street — every officer goes through recruit
        // school first, and every rung above patrol is a promotion from it.
        "Police Officer": HardSkills(trainings: [.policeAcademy]),
        "Security Guard": HardSkills(trainings: [.securityGuard]),
        // Service / hospitality
        "Hairdresser/Barber": HardSkills(trainings: [.cosmetology]),
        "Beautician/Cosmetologist": HardSkills(trainings: [.cosmetology]),
        "Flight Attendant": HardSkills(trainings: [.flightAttendantCert]),
        // Education — teachers are hired on a teaching certificate (a helpful
        // signal in this non-regulated field, not a hard gate).
        "Teacher": HardSkills(trainings: [.teachingCertificate]),
        // Agriculture — pesticides require a state applicator license
        "Farmer": HardSkills(trainings: [.pesticideApplicator]),
    ]

    // MARK: - Expected experience

    /// Years of prior industry experience an employer expects before even
    /// considering an applicant. Senior, management, and regulated roles set this
    /// above zero; entry-level jobs are absent and default to 0.
    static let minYearsByTitle: [String: Int] = [
        "Hotel Manager": 5,
        "Sales Manager": 3,
        "Project Manager": 3,
        "Event Planner": 2,
        "Human Resources Specialist": 1,
        "Business Analyst": 2,
        "Financial Analyst": 2,
        "Marketing Specialist": 2,
        // Security is a second-career field — hired out of IT/networking, not
        // straight from school.
        "Cybersecurity Analyst": 2,
        "Judge": 10,
        // A newly barred lawyer is hired as an associate straight away; the
        // JD + Bar are the real barrier, not prior experience. (Senior Lawyer
        // and Managing Partner carry the experience gates.)
        "Lawyer": 0,
        // Physicians need residency and psychologists need supervised hours
        // before practising, so both keep an experience floor — but dentists
        // and veterinarians practise as soon as they're degreed and licensed.
        "Physician": 2,
        "Psychologist": 2,
        // First Officer is the entry airline-pilot seat (hired on the
        // commercial licence + hours); a full "Pilot" reads as captain-track.
        "First Officer": 1,
        "Pilot": 3,
        "Airline Captain": 8,
        "Research Scientist": 3,
        "Architect": 4,
        "Aerospace Engineer": 2,
        "Surgeon": 5,
        "Anesthesiologist": 5,
        "Management Consultant": 2,
        "Investment Banker": 2,
        "Data Scientist": 2,
        "Cloud Architect": 5,
        "Office Manager": 3,
    ]

    // MARK: - Accepted degree fields

    /// Per-title override where a role draws on a discipline the category map
    /// doesn't capture — an architecture degree reads as design or arts as
    /// readily as engineering, so an Architect shouldn't be gated to
    /// engineering/science/technology degrees.
    static let acceptedProfilesByBaseTitle: [String: [TertiaryProfile]] = [
        "Architect": [.engineering, .design, .arts],
        // Game roles hire from technology, design and arts alike, so they keep
        // that spread rather than inheriting whichever category now holds them.
        "Game Designer": [.technology, .design, .arts],
        "Narrative Designer": [.technology, .design, .arts],
    ]

    // MARK: - Work setting

    /// Roles whose day-to-day setting isn't what their industry suggests. Keyed
    /// by base title, so every rung of a ladder shares it.
    static let workSettingByBaseTitle: [String: WorkSetting] = [
        // Engineering: most of it is desk work, but civil engineering is site work.
        "Civil Engineer": .field,
        // Shop floor and back of house are hands-on, whatever their category
        // default says about the industry around them.
        "Stocker/Order Filler": .field,
        "Cook": .field,
        "Groundskeeper": .field,
        // Selling and branch banking are face-to-face, not desk work.
        "Sales Representative": .peopleFacing,
        "Real Estate Agent": .peopleFacing,
        "Bank Teller": .peopleFacing,
        "Store Manager": .peopleFacing,
        // Health: the chief medical officer runs the hospital from an office.
        "Chief Medical Officer": .office,
        // Hospitality: back of house is hands-on, not customer-facing.
        "Chef": .field,
        "Baker": .field,
        "Dishwasher": .field,
        "Food Preparation Worker": .field,
        "Housekeeper": .field,
        "Janitor/Cleaner": .field,
        "Event Planner": .office,
        // Moving goods: the warehouse floor is hands-on, the planning desks
        // behind it are not — transportation defaults to field.
        "Dispatcher": .office,
        "Logistics Coordinator": .office,
        // Public services: case work is people work.
        "Social Worker": .peopleFacing,
        // Science: bench work is hands-on; writing up the research isn't.
        "Lab Technician": .field,
        // Show business: the desk trades behind the spotlight.
        "Content Writer": .office,
        "Video Editor": .office,
        "Social Media Manager": .office,
        "Art Director": .office,
        // …and the ones that are out chasing the story or the shot.
        "Journalist": .field,
        "Photographer": .field,
        // Transportation: the tower is a control room, not a cab.
    ]

    /// Where a role in `category` is done, absent an entry above.
    /// The markets that plausibly employ a discipline, when
    /// `industriesByBaseTitle` says nothing more specific. A posting draws one of
    /// these each time the market is redrawn (see `allJobs`), which is what makes
    /// "the same category belongs to many industries" true of the listings
    /// themselves rather than only of the catalogue as a whole.
    static func defaultIndustries(for category: JobCategory) -> [Industry] {
        switch category {
        case .technology:       return [.software, .hardware, .telecom, .finance]
        case .engineering:      return [.manufacturing, .energy, .construction, .automotive]
        case .science:          return [.pharmaBiotech, .healthcare, .education, .energy]
        case .health:           return [.healthcare, .pharmaBiotech]
        case .education:        return [.education, .government]
        case .publicServices:   return [.government]
        case .law:              return [.professionalServices, .government, .finance]
        case .business:         return [.finance, .professionalServices, .retailTrade, .manufacturing]
        case .administration:   return [.professionalServices, .finance, .healthcare, .government]
        case .design:           return [.mediaEntertainment, .software, .retailTrade]
        case .showBusiness:     return [.mediaEntertainment]
        case .retail:           return [.retailTrade]
        case .hospitality:      return [.hospitalityTourism]
        case .service:          return [.retailTrade, .hospitalityTourism]
        case .construction:     return [.construction]
        case .manufacturing:    return [.manufacturing, .automotive, .aerospaceDefense, .agriFood]
        case .agriculture:      return [.agriFood]
        // Ground logistics only. Aviation roles name aerospace explicitly below;
        // leaving it in the default posted dispatchers and bus drivers to defence
        // contractors, which is not a thing.
        case .transportation:   return [.logistics]
        case .entrepreneurship: return [.professionalServices]
        }
    }

    /// Roles whose employers are a narrower — or different — set of markets than
    /// their discipline's default. Keyed by base title, so every rung of a ladder
    /// shares it.
    ///
    /// A single entry means the role only ever sits in that market; several means
    /// a posting is drawn from among them each year. This table is the point of
    /// having an `Industry` axis: it is where one discipline fans out.
    static let industriesByBaseTitle: [String: [Industry]] = [
        // Engineering fans out across the sectors that actually build things.
        "Aerospace Engineer": [.aerospaceDefense],
        "Architect": [.construction],
        "Civil Engineer": [.construction, .government],
        "Chemical Engineer": [.energy, .pharmaBiotech, .manufacturing],
        "Electrical Engineer": [.energy, .manufacturing, .hardware],
        "Mechanical Engineer": [.automotive, .aerospaceDefense, .manufacturing],

        // Design follows the thing being designed, not the drawing of it.
        "Fashion Designer": [.retailTrade],
        "Interior Designer": [.construction, .hospitalityTourism],
        "UX/UI Designer": [.software, .finance, .retailTrade],
        "Graphic Artist": [.mediaEntertainment, .professionalServices],

        // Games are an entertainment business that happens to employ programmers.
        "Indie Game Studio": [.mediaEntertainment],
        "Level Designer": [.mediaEntertainment],
        "Narrative Designer": [.mediaEntertainment],

        // Business: only the money roles are in finance; the rest sell advice.
        "Financial Analyst": [.finance],
        "Investment Banker": [.finance],
        "Management Consultant": [.professionalServices],
        "Marketing Director": [.professionalServices, .retailTrade, .mediaEntertainment],
        "Marketing Specialist": [.professionalServices, .retailTrade, .mediaEntertainment],

        // Health: dispensing is pharma, and a gym is leisure, not medicine.
        "Pharmacist": [.pharmaBiotech, .healthcare],
        "Boutique Fitness Studio": [.hospitalityTourism],

        // The state, whatever the nominal discipline.
        "Judge": [.government],
        "Security Guard": [.professionalServices, .government],

        // Moving people and goods.
        "Aircraft Maintenance Technician": [.aerospaceDefense],
        "Airline Pilot": [.aerospaceDefense],
        "Mechanic": [.automotive, .logistics],
        // The last mile is run by retailers as much as by carriers.
        "Delivery Courier": [.logistics, .retailTrade],
        "Light Truck Delivery Driver": [.logistics, .retailTrade],
        "Truck Driver": [.logistics, .agriFood, .manufacturing],

        // Leisure trades sitting under other headings.
        "Fitness Instructor": [.hospitalityTourism],
        "Janitor/Cleaner": [.professionalServices],

        // Ventures keep the market they are a business in.
        "SaaS App Startup": [.software],
        "Specialty Coffee Roastery": [.retailTrade],
        "Farm-to-Table Restaurant": [.hospitalityTourism],
        "Property Development Firm": [.construction],
    ]

    /// The markets a role can be posted by, narrowest declaration first.
    static func industries(forBaseTitle baseTitle: String, category: JobCategory) -> [Industry] {
        industriesByBaseTitle[baseTitle] ?? defaultIndustries(for: category)
    }

    // MARK: - Seniority

    /// How a rung's demands differ from the entry rung's.
    ///
    /// A ladder used to ask exactly the same of every rung: a Delivery Courier
    /// and an Airline Captain, an IT Support Specialist and a Chief Technology
    /// Officer, a Bank Teller and a Chief Executive Officer were each written
    /// down as the same person. Forty of the catalogue's forty-two ladders were
    /// flat, so the only thing that changed on the way up was the pay.
    ///
    /// The authored profile is **the entry rung's** — the bar for joining the
    /// ladder at all. Each rung above it adds:
    ///
    /// * **+1 to the craft.** Every axis the entry rung already leans on
    ///   (3 or more) deepens a level per rung, so a principal engineer's
    ///   analysis bar sits where a junior's cannot reach.
    /// * **+1 leadership and +1 planning, from the second rung up.** Above
    ///   entry level the job starts including other people's work.
    /// * **+1 communication and +1 vision at the top rung only.** The last seat
    ///   on a ladder sets direction and speaks for the function.
    ///
    /// Position, not the label, drives this: `rung` is the ladder (see
    /// `LadderSpec`), and labels are inconsistent across tracks — a flight deck
    /// climbs First Officer → Pilot → Captain with no seniority prefix at all.
    ///
    /// Standalone senior roles (a CEO, a chief medical officer, a managing
    /// partner) are rung 0 of nothing, so they carry their elite profile
    /// explicitly in `softSkillsByBaseTitle` instead.
    static func seniority(_ base: SoftSkills, rung: Int, isTopRung: Bool) -> SoftSkills {
        guard rung > 0 else { return base }
        var profile = base
        for axis in SoftSkills.allAxes {
            let held = base[keyPath: axis.keyPath]
            // The rules take the *largest* lift that applies rather than adding
            // up, so an axis that is both the craft and the management load —
            // a chef's planning, a logistician's — is not raised twice for the
            // same promotion.
            var lift = 0
            if held >= 3 { lift = rung }
            if axis.keyPath == \.leadershipAndInfluence || axis.keyPath == \.timeManagementAndPlanning {
                lift = max(lift, rung)
            }
            if isTopRung,
               axis.keyPath == \.communicationAndNetworking || axis.keyPath == \.visionaryThinkingAndAmbition {
                lift = max(lift, 1)
            }
            profile[keyPath: axis.keyPath] = min(10, held + lift)
        }
        return profile
    }

    static func defaultWorkSetting(for category: JobCategory) -> WorkSetting {
        switch category {
        case .administration, .business, .design, .engineering, .law,
             .science, .technology, .entrepreneurship:
            return .office
        case .agriculture, .construction, .manufacturing, .publicServices,
             .transportation:
            return .field
        case .education, .health, .hospitality, .retail, .service, .showBusiness:
            return .peopleFacing
        }
    }

    // MARK: - Category defaults

    /// The skills a role in `category` asks for **at the entry rung**, when no
    /// per-title profile overrides it. Rungs above entry climb from here (see
    /// `seniority`).
    ///
    /// Read these as the bar for doing the job at all, not as a portrait of the
    /// field's stars. The scale runs 0–10, the same one the player's skills use:
    ///
    /// * **1–2** — helpful; the job goes better with it.
    /// * **3–4** — core; you cannot do this work without it.
    /// * **5+** — reached by climbing, not by being hired off the street.
    ///
    /// Every category is spelled out and there is no `default:` branch, so
    /// adding a category fails the build rather than silently inheriting a
    /// near-empty profile. That is exactly what used to happen to public
    /// services and entrepreneurship: both fell through to a catch-all that
    /// asked almost nothing, which made a $130k precinct commander with twelve
    /// years in one of the easiest hires in the game.
    static func defaultSoftSkills(for category: JobCategory) -> SoftSkills {
        switch category {

        // Building software: reasoning and rigour, done in a team.
        case .technology:
            return .init(
                analyticalReasoningAndProblemSolving: 3,
                creativityAndInsightfulThinking: 1,
                communicationAndNetworking: 1,
                carefulnessAndAttentionToDetail: 3,
                tinkeringAndFingerPrecision: 1,
                stressResistanceAndEmotionalRegulation: 1,
                collaborationAndTeamwork: 2,
                timeManagementAndPlanning: 2,
                selfDisciplineAndPerseverance: 2
            )

        // Engineering adds the physical world: how parts fit and what breaks.
        case .engineering:
            return .init(
                analyticalReasoningAndProblemSolving: 3,
                creativityAndInsightfulThinking: 1,
                carefulnessAndAttentionToDetail: 3,
                tinkeringAndFingerPrecision: 2,
                spacialNavigationAndOrientation: 2,
                collaborationAndTeamwork: 2,
                timeManagementAndPlanning: 2,
                selfDisciplineAndPerseverance: 2
            )

        // The bench: long, exacting work whose results have to be written up.
        case .science:
            return .init(
                analyticalReasoningAndProblemSolving: 3,
                creativityAndInsightfulThinking: 2,
                carefulnessAndAttentionToDetail: 3,
                collaborationAndTeamwork: 2,
                timeManagementAndPlanning: 2,
                selfDisciplineAndPerseverance: 3,
                presentationAndStorytelling: 1
            )

        // Clinical work: accuracy and composure on your feet, with patients.
        case .health:
            return .init(
                analyticalReasoningAndProblemSolving: 2,
                communicationAndNetworking: 2,
                carefulnessAndAttentionToDetail: 3,
                resilienceAndEndurance: 3,
                stressResistanceAndEmotionalRegulation: 3,
                empathyAndInterpersonalCare: 3,
                collaborationAndTeamwork: 3,
                timeManagementAndPlanning: 2
            )

        // Teaching is explaining and holding a room — a different job from
        // nursing, which it used to share a profile with.
        case .education:
            return .init(
                communicationAndNetworking: 3,
                carefulnessAndAttentionToDetail: 1,
                resilienceAndEndurance: 2,
                stressResistanceAndEmotionalRegulation: 3,
                empathyAndInterpersonalCare: 3,
                collaborationAndTeamwork: 2,
                timeManagementAndPlanning: 2,
                selfDisciplineAndPerseverance: 2,
                presentationAndStorytelling: 3
            )

        // The shop floor: the sale is the job.
        case .retail:
            return .init(
                communicationAndNetworking: 3,
                persuasionAndNegotiation: 2,
                carefulnessAndAttentionToDetail: 1,
                resilienceAndEndurance: 2,
                stressResistanceAndEmotionalRegulation: 2,
                empathyAndInterpersonalCare: 2,
                collaborationAndTeamwork: 2,
                timeManagementAndPlanning: 1
            )

        // Service under pressure: a full room, at speed, without losing the plot.
        case .hospitality:
            return .init(
                communicationAndNetworking: 2,
                carefulnessAndAttentionToDetail: 2,
                resilienceAndEndurance: 3,
                stressResistanceAndEmotionalRegulation: 3,
                empathyAndInterpersonalCare: 2,
                collaborationAndTeamwork: 3,
                timeManagementAndPlanning: 2
            )

        // Personal services: one client at a time, and they come back or don't.
        case .service:
            return .init(
                creativityAndInsightfulThinking: 1,
                communicationAndNetworking: 3,
                carefulnessAndAttentionToDetail: 2,
                tinkeringAndFingerPrecision: 1,
                resilienceAndEndurance: 2,
                empathyAndInterpersonalCare: 3,
                timeManagementAndPlanning: 1
            )

        // Site work: hands, stamina, and the weather.
        case .construction:
            return .init(
                carefulnessAndAttentionToDetail: 2,
                tinkeringAndFingerPrecision: 3,
                spacialNavigationAndOrientation: 2,
                resilienceAndEndurance: 3,
                outdoorAndWeatherResilience: 3,
                collaborationAndTeamwork: 2,
                selfDisciplineAndPerseverance: 1
            )

        // The line: the same thing again, correctly, all shift.
        case .manufacturing:
            return .init(
                analyticalReasoningAndProblemSolving: 1,
                carefulnessAndAttentionToDetail: 3,
                tinkeringAndFingerPrecision: 3,
                spacialNavigationAndOrientation: 2,
                resilienceAndEndurance: 3,
                collaborationAndTeamwork: 1,
                selfDisciplineAndPerseverance: 2
            )

        // Design: an idea, made to fit a brief and a deadline.
        case .design:
            return .init(
                creativityAndInsightfulThinking: 3,
                communicationAndNetworking: 2,
                carefulnessAndAttentionToDetail: 2,
                spacialNavigationAndOrientation: 1,
                collaborationAndTeamwork: 2,
                timeManagementAndPlanning: 2,
                selfDisciplineAndPerseverance: 2,
                presentationAndStorytelling: 2
            )

        // Performing and publishing: an audience, and the nerve to face it.
        case .showBusiness:
            return .init(
                creativityAndInsightfulThinking: 3,
                communicationAndNetworking: 2,
                resilienceAndEndurance: 2,
                stressResistanceAndEmotionalRegulation: 2,
                timeManagementAndPlanning: 1,
                selfDisciplineAndPerseverance: 2,
                presentationAndStorytelling: 3
            )

        // Commercial work: reading the numbers and winning the room.
        case .business:
            return .init(
                analyticalReasoningAndProblemSolving: 2,
                communicationAndNetworking: 3,
                persuasionAndNegotiation: 2,
                carefulnessAndAttentionToDetail: 2,
                stressResistanceAndEmotionalRegulation: 1,
                collaborationAndTeamwork: 2,
                timeManagementAndPlanning: 2,
                presentationAndStorytelling: 2
            )

        // Back office: nothing dropped, everything filed, on the day it is due.
        case .administration:
            return .init(
                communicationAndNetworking: 2,
                carefulnessAndAttentionToDetail: 3,
                stressResistanceAndEmotionalRegulation: 1,
                collaborationAndTeamwork: 2,
                timeManagementAndPlanning: 3,
                selfDisciplineAndPerseverance: 2
            )

        // Law: argument built on detail, delivered under pressure.
        case .law:
            return .init(
                analyticalReasoningAndProblemSolving: 3,
                communicationAndNetworking: 2,
                persuasionAndNegotiation: 2,
                carefulnessAndAttentionToDetail: 3,
                stressResistanceAndEmotionalRegulation: 2,
                timeManagementAndPlanning: 2,
                selfDisciplineAndPerseverance: 2,
                presentationAndStorytelling: 2
            )

        // Policing, firefighting, and public works: the calm, physical trades
        // of the state. This used to fall through to the catch-all.
        case .publicServices:
            return .init(
                communicationAndNetworking: 2,
                carefulnessAndAttentionToDetail: 2,
                resilienceAndEndurance: 3,
                stressResistanceAndEmotionalRegulation: 3,
                empathyAndInterpersonalCare: 2,
                outdoorAndWeatherResilience: 2,
                collaborationAndTeamwork: 3,
                selfDisciplineAndPerseverance: 2
            )

        // Moving people and goods: the road, the clock, and staying alert.
        case .transportation:
            return .init(
                carefulnessAndAttentionToDetail: 3,
                spacialNavigationAndOrientation: 3,
                resilienceAndEndurance: 2,
                stressResistanceAndEmotionalRegulation: 2,
                outdoorAndWeatherResilience: 1,
                timeManagementAndPlanning: 2,
                selfDisciplineAndPerseverance: 2
            )

        // Land work: outdoors, all season, fixing what breaks.
        case .agriculture:
            return .init(
                carefulnessAndAttentionToDetail: 1,
                tinkeringAndFingerPrecision: 2,
                spacialNavigationAndOrientation: 1,
                resilienceAndEndurance: 3,
                outdoorAndWeatherResilience: 3,
                collaborationAndTeamwork: 1,
                timeManagementAndPlanning: 1,
                selfDisciplineAndPerseverance: 2
            )

        // Founding: nerve, a story, and the discipline to keep going. Also
        // previously a catch-all case, which asked a founder for nothing.
        case .entrepreneurship:
            return .init(
                analyticalReasoningAndProblemSolving: 2,
                creativityAndInsightfulThinking: 2,
                communicationAndNetworking: 3,
                persuasionAndNegotiation: 3,
                leadershipAndInfluence: 2,
                visionaryThinkingAndAmbition: 3,
                riskTakingAndInitiative: 3,
                stressResistanceAndEmotionalRegulation: 2,
                timeManagementAndPlanning: 2,
                selfDisciplineAndPerseverance: 3
            )
        }
    }

    static func defaultAcceptedProfiles(for category: JobCategory) -> [TertiaryProfile]? {
        switch category {
        case .technology:  return [.technology, .engineering, .science]
        case .engineering: return [.engineering, .science, .technology]
        case .science:     return [.science, .engineering, .technology]
        case .health:      return [.health, .science]
        case .business:    return [.business]
        case .administration: return [.business]
        case .law:         return [.law]
        case .education:   return [.education, .science]
        case .design:      return [.design, .arts]
        case .showBusiness: return [.arts, .design, .sports]
        case .service:     return [.service, .business]
        case .agriculture: return [.agriculture, .science]
        default:           return nil
        }
    }

    // MARK: - Resolution

    /// The credentials a title mandates: its own senior-grade entry if it has
    /// one, else whatever its base role requires, else none.
    static func credentials(forTitle title: String, baseTitle: String) -> HardSkills {
        credentialsByFullTitle[title]
            ?? credentialsByBaseTitle[baseTitle]
            ?? HardSkills()
    }

    /// Builds one job, applying the category defaults and the per-title
    /// overrides. The single place a row becomes a `Job`.
    static func job(title: String, category: JobCategory, income: Int, icon: String,
                    summary: String, minEQF: Int, minYears: Int?, targetCapital: Int?,
                    baseTitle: String, rung: Int, rungLabel: String,
                    isTopRung: Bool, industry: Industry) -> Job {
        let hard = credentials(forTitle: title, baseTitle: baseTitle)
        // A role can't sensibly demand a license or certification the player
        // couldn't have earned at its listed education level. Raise the floor to
        // the toughest education prerequisite of any credential the role
        // mandates, so the stated requirement reflects what the player must
        // genuinely already hold (e.g. a Physiotherapist listed at bachelor's
        // level still reads as doctorate, because the licence it mandates is).
        let credentialEQF = hard.trainings.map(\.minEQF).max() ?? 0
        let effectiveEQF = max(minEQF, credentialEQF)
        // Degree fields only matter once a university degree is required; trades
        // and entry roles accept any background.
        let profiles = effectiveEQF >= 5
            ? (acceptedProfilesByBaseTitle[baseTitle] ?? defaultAcceptedProfiles(for: category))
            : nil
        let requirements = Job.Requirements(
            education: .init(minEQF: effectiveEQF, acceptedProfiles: profiles),
            // A profile written against the *exact* title is taken as authored —
            // it was written for that rung. Everything else is the ladder's
            // entry bar and climbs with the seat (see `seniority`).
            softSkills: softSkillsByFullTitle[title]
                ?? seniority(softSkillsByBaseTitle[baseTitle] ?? defaultSoftSkills(for: category),
                             rung: rung, isTopRung: isTopRung),
            hardSkills: hard,
            minYearsExperience: minYears ?? minYearsByTitle[title] ?? 0
        )
        return Job(id: title, category: category, income: income,
                   summary: summary, icon: icon, requirements: requirements,
                   targetCapital: targetCapital,
                   baseTitle: baseTitle, rung: rung, rungLabel: rungLabel,
                   workSetting: workSettingByBaseTitle[baseTitle]
                       ?? defaultWorkSetting(for: category),
                   industry: industry)
    }

    /// A role with no ladder: its own base title, sitting at rung 0.
    static func job(from spec: JobSpec) -> Job {
        job(title: spec.title, category: spec.category, income: spec.income, icon: spec.icon,
            summary: spec.summary, minEQF: spec.minEQF, minYears: spec.minYears,
            targetCapital: spec.targetCapital,
            baseTitle: spec.title, rung: 0, rungLabel: "", isTopRung: true,
            industry: industries(forBaseTitle: spec.title, category: spec.category).randomElement()!)
    }

    /// Every rung of a ladder, in declared order — the index is `Job.rung`.
    ///
    /// The sector is drawn **once per ladder**, not per rung: a ladder is one
    /// employer's, and a promotion moves the player to `rung + 1` off this same
    /// list — so per-rung draws would teleport them between markets on a raise.
    static func jobs(for ladder: LadderSpec) -> [Job] {
        let sector = industries(forBaseTitle: ladder.name, category: ladder.category).randomElement()!
        return ladder.rungs.enumerated().map { index, rung in
            job(title: ladder.title(for: rung), category: ladder.category, income: rung.income,
                icon: rung.icon ?? ladder.icon, summary: rung.summary, minEQF: rung.minEQF,
                minYears: rung.minYears, targetCapital: nil,
                baseTitle: ladder.name, rung: index, rungLabel: rung.label,
                isTopRung: index == ladder.rungs.count - 1,
                industry: sector)
        }
    }

    // MARK: - Rows: standalone roles
    // EQF: 1=Primary, 2=Middle, 3=High School, 4=Vocational, 5=Bachelor, 6=Master, 7=Doctorate
    static let standaloneRoles: [JobSpec] = [
        // MARK: The biggest employers
        //
        // These are the roles most people actually hold. The catalogue skewed
        // hard toward glamour work — show business and games were 20% of it and
        // are under 2% of real employment — while care work, shop floors, school
        // support, kitchens and back offices, which between them employ tens of
        // millions, were barely represented. US employment figures in the
        // comments are approximate (BLS OES, ~2023), kept here so a future edit
        // can tell a common job from a rare one.
        .init(title: "Personal Care Aide", category: .service, income: 30_000, icon: "🤲", summary: "Helps elderly and disabled clients with daily living at home.", minEQF: 2),                     // ~3.7M — the single largest occupation
        .init(title: "Customer Service Representative", category: .administration, income: 38_000, icon: "🎧", summary: "Answers customer questions and resolves complaints.", minEQF: 3),                 // ~2.9M
        .init(title: "Stocker/Order Filler", category: .retail, income: 32_000, icon: "📦", summary: "Keeps shelves filled and picks orders in stores and warehouses.", minEQF: 2),                        // ~2.9M
        .init(title: "Office Clerk", category: .administration, income: 37_000, icon: "🗂️", summary: "Handles filing, data entry, and general office tasks.", minEQF: 3),                                  // ~2.6M
        .init(title: "Cook", category: .hospitality, income: 33_000, icon: "🍲", summary: "Cooks to order on the line in restaurants and canteens.", minEQF: 2),                                            // ~2.4M
        .init(title: "Operations Manager", category: .business, income: 78_000, icon: "🗃️", summary: "Runs the day-to-day of a site, branch, or department.", minEQF: 4, minYears: 3),                    // ~3.5M
        .init(title: "Sales Representative", category: .business, income: 62_000, icon: "🤝", summary: "Sells products and services to businesses.", minEQF: 3),                                           // ~1.5M
        .init(title: "Store Manager", category: .retail, income: 48_000, icon: "🏪", summary: "Runs a shop floor — staffing, stock, and takings.", minEQF: 3, minYears: 2),                                 // ~1.2M
        .init(title: "Maintenance & Repair Worker", category: .construction, income: 45_000, icon: "🔧", summary: "Keeps buildings and equipment working — the general fixer.", minEQF: 3),                 // ~1.5M
        .init(title: "Bookkeeping Clerk", category: .administration, income: 45_000, icon: "🧮", summary: "Keeps the ledgers, invoices, and payments straight.", minEQF: 3),                               // ~1.5M
        .init(title: "Teaching Assistant", category: .education, income: 32_000, icon: "✏️", summary: "Supports a classroom teacher and works with pupils in small groups.", minEQF: 3),                    // ~1.3M
        .init(title: "Groundskeeper", category: .agriculture, income: 35_000, icon: "🌳", summary: "Maintains lawns, parks, and grounds.", minEQF: 2),                                                      // ~1.1M
        .init(title: "Childcare Worker", category: .education, income: 30_000, icon: "🧸", summary: "Cares for young children in nurseries and homes.", minEQF: 3),                                        // ~1.0M
        .init(title: "Bartender", category: .hospitality, income: 31_000, icon: "🍸", summary: "Mixes and serves drinks at a bar.", minEQF: 2),                                                             // ~0.7M
        .init(title: "Heavy Equipment Operator", category: .construction, income: 52_000, icon: "🚜", summary: "Runs excavators, loaders, and bulldozers on site.", minEQF: 3),                             // ~0.5M
        .init(title: "Pharmacy Technician", category: .health, income: 40_000, icon: "⚗️", summary: "Prepares prescriptions under a pharmacist's supervision.", minEQF: 3),                                 // ~0.46M
        .init(title: "Real Estate Agent", category: .business, income: 54_000, icon: "🏡", summary: "Lists, shows, and sells property on commission.", minEQF: 3),                                          // ~0.45M
        .init(title: "Insurance Agent", category: .business, income: 57_000, icon: "📋", summary: "Sells and services insurance policies.", minEQF: 3),                                                     // ~0.44M
        .init(title: "Bank Teller", category: .business, income: 37_000, icon: "🏧", summary: "Handles deposits, withdrawals, and everyday branch banking.", minEQF: 3),                                    // ~0.36M

        .init(title: "Light Truck Delivery Driver", category: .transportation, income: 42_000, icon: "🚐", summary: "Delivers goods locally using vans or small trucks.", minEQF: 3),
        // Retail
        .init(title: "Retail Salesperson", category: .retail, income: 30_000, icon: "🛍️", summary: "Sells products directly to customers.", minEQF: 3),
        .init(title: "Cashier", category: .retail, income: 26_000, icon: "💳", summary: "Handles customer payments and transactions.", minEQF: 2),
        // Hospitality — restaurants, hotels, and events
        .init(title: "Waiter/Waitress", category: .hospitality, income: 24_000, icon: "🍽️", summary: "Serves food and beverages to customers.", minEQF: 2),
        .init(title: "Food Preparation Worker", category: .hospitality, income: 25_000, icon: "🍳", summary: "Prepares ingredients and supports kitchen staff.", minEQF: 2),
        .init(title: "Dishwasher", category: .hospitality, income: 23_000, icon: "🧽", summary: "Cleans dishes and kitchenware in food-service settings.", minEQF: 1),
        .init(title: "Fast Food Worker", category: .hospitality, income: 24_000, icon: "🍔", summary: "Takes orders and prepares food at quick-service counters.", minEQF: 1),
        .init(title: "Housekeeper", category: .hospitality, income: 27_000, icon: "🧺", summary: "Cleans and tidies rooms in hotels and facilities.", minEQF: 1),
        .init(title: "Janitor/Cleaner", category: .hospitality, income: 34_000, icon: "🧹", summary: "Maintains cleanliness of buildings and facilities.", minEQF: 1),
        .init(title: "Flight Attendant", category: .hospitality, income: 48_000, icon: "🛫", summary: "Ensures passenger safety and comfort.", minEQF: 3),
        .init(title: "Baker", category: .hospitality, income: 32_000, icon: "🥐", summary: "Bakes bread, pastries, and other goods.", minEQF: 3),
        .init(title: "Hotel Manager", category: .hospitality, income: 72_000, icon: "🏨", summary: "Oversees hotel operations and staff.", minEQF: 5),
        .init(title: "Event Planner", category: .hospitality, income: 55_000, icon: "🎉", summary: "Organizes events and logistics.", minEQF: 5),
        // Personal Services — personal and general services
        .init(title: "Hairdresser/Barber", category: .service, income: 32_000, icon: "💇", summary: "Cuts and styles hair for clients.", minEQF: 4),
        .init(title: "Beautician/Cosmetologist", category: .service, income: 30_000, icon: "💄", summary: "Provides beauty treatments and services.", minEQF: 4),
        .init(title: "Surgeon", category: .health, income: 350_000, icon: "🔪", summary: "Performs operations to treat injuries and disease.", minEQF: 7),
        .init(title: "Anesthesiologist", category: .health, income: 330_000, icon: "💉", summary: "Manages anesthesia and patient vitals during surgery.", minEQF: 7),
        .init(title: "Pharmacist", category: .health, income: 132_000, icon: "💊", summary: "Dispenses medications and advises patients.", minEQF: 7),
        .init(title: "Medical Assistant", category: .health, income: 37_000, icon: "🩺", summary: "Supports clinical staff with patient care.", minEQF: 3),
        .init(title: "Nursing Aide", category: .health, income: 30_000, icon: "🛏️", summary: "Assists patients with daily living tasks.", minEQF: 3),
        .init(title: "Licensed Practical Nurse", category: .health, income: 55_000, icon: "💉", summary: "Gives basic nursing care under an RN or physician.", minEQF: 3),
        .init(title: "Dental Assistant", category: .health, income: 38_000, icon: "🦷", summary: "Supports dental professionals during procedures.", minEQF: 3),
        .init(title: "Dentist", category: .health, income: 160_000, icon: "🦷", summary: "Diagnoses and treats dental conditions.", minEQF: 7),
        .init(title: "Physiotherapist", category: .health, income: 65_000, icon: "🤸", summary: "Provides rehabilitation and physical therapy.", minEQF: 7),
        .init(title: "Psychologist", category: .health, income: 90_000, icon: "🧠", summary: "Studies behavior and provides therapy.", minEQF: 7),
        .init(title: "Paramedic", category: .health, income: 52_000, icon: "🚑", summary: "Provides emergency medical care.", minEQF: 4),
        .init(title: "Veterinarian", category: .health, income: 105_000, icon: "🐾", summary: "Cares for animal health and treatments.", minEQF: 7),
        // Social
        .init(title: "Social Worker", category: .publicServices, income: 48_000, icon: "🤝", summary: "Supports vulnerable individuals and families.", minEQF: 5),
        .init(title: "IT Support Specialist", category: .technology, income: 52_000, icon: "🛠️", summary: "Provides technical help desk support.", minEQF: 3),
        .init(title: "Software Tester/QA", category: .technology, income: 68_000, icon: "🔍", summary: "Tests software for defects and quality.", minEQF: 3),
        .init(title: "Cybersecurity Analyst", category: .technology, income: 105_000, icon: "🔐", summary: "Defends systems and networks against attacks.", minEQF: 5),
        .init(title: "Cloud Architect", category: .technology, income: 160_000, icon: "☁️", summary: "Designs and runs large-scale cloud infrastructure.", minEQF: 5),
        .init(title: "Translator/Interpreter", category: .business, income: 50_000, icon: "🌐", summary: "Converts text between languages and provides live interpretation.", minEQF: 5),
        // Administration — back-office functions common to every business
        .init(title: "Administrative Assistant", category: .administration, income: 40_000, icon: "📎", summary: "Supports a team with scheduling, mail, and records.", minEQF: 3),
        .init(title: "Receptionist", category: .administration, income: 33_000, icon: "📞", summary: "Greets visitors and manages front-desk tasks.", minEQF: 3),
        .init(title: "Payroll Specialist", category: .administration, income: 52_000, icon: "💵", summary: "Processes payroll and employee benefits.", minEQF: 4),
        .init(title: "Human Resources Specialist", category: .administration, income: 62_000, icon: "🧑‍💼", summary: "Manages hiring and employee relations.", minEQF: 5),
        .init(title: "Office Manager", category: .administration, income: 64_000, icon: "🗄️", summary: "Runs day-to-day office operations and admin staff.", minEQF: 4),
        // Construction / Trades
        .init(title: "Construction Laborer", category: .construction, income: 36_000, icon: "🏗️", summary: "Performs physical tasks on construction sites.", minEQF: 2),
        .init(title: "Roofer", category: .construction, income: 45_000, icon: "🏠", summary: "Installs and repairs roofs in all weather.", minEQF: 1),
        .init(title: "Painter (Construction)", category: .construction, income: 36_000, icon: "🎨", summary: "Paints buildings and interior spaces.", minEQF: 2),
        .init(title: "HVAC Technician", category: .construction, income: 55_000, icon: "🌡️", summary: "Installs and services heating and cooling systems.", minEQF: 4),
        // Manufacturing
        .init(title: "Factory Worker", category: .manufacturing, income: 34_000, icon: "🏭", summary: "Operates production-line equipment and assembles goods.", minEQF: 1),
        .init(title: "Assembler", category: .manufacturing, income: 36_000, icon: "🔩", summary: "Assembles parts and products to spec.", minEQF: 1),
        .init(title: "Machine Operator", category: .manufacturing, income: 42_000, icon: "⚙️", summary: "Runs and monitors manufacturing machinery.", minEQF: 2),
        .init(title: "Welder", category: .manufacturing, income: 47_000, icon: "🔥", summary: "Joins metal parts for fabrication and repair.", minEQF: 3),
        .init(title: "Machinist", category: .manufacturing, income: 50_000, icon: "🛠️", summary: "Machines precision metal parts from blueprints.", minEQF: 3),
        .init(title: "Quality Control Inspector", category: .manufacturing, income: 46_000, icon: "🔎", summary: "Checks products against quality standards.", minEQF: 3),
        // Transportation — vehicle operation, material handling, and maintenance
        .init(title: "Truck Driver", category: .transportation, income: 50_000, icon: "🚚", summary: "Transports goods over long distances.", minEQF: 3),
        .init(title: "Bus Driver", category: .transportation, income: 42_000, icon: "🚌", summary: "Operates passenger buses on scheduled routes.", minEQF: 3),
        .init(title: "Taxi Driver", category: .transportation, income: 32_000, icon: "🚕", summary: "Provides on-demand passenger transport.", minEQF: 2),
        .init(title: "Delivery Courier", category: .transportation, income: 30_000, icon: "🛵", summary: "Delivers parcels and food by bike, scooter, or on foot.", minEQF: 1),
        .init(title: "Mover", category: .transportation, income: 32_000, icon: "📦", summary: "Loads, hauls, and unloads household and office goods.", minEQF: 1),
        .init(title: "Warehouse Worker", category: .transportation, income: 34_000, icon: "🪜", summary: "Picks, packs, and moves warehouse inventory.", minEQF: 2),
        .init(title: "Forklift Operator", category: .transportation, income: 36_000, icon: "🏗️", summary: "Operates forklifts to move goods.", minEQF: 2),
        .init(title: "Mechanic", category: .transportation, income: 52_000, icon: "🔧", summary: "Repairs vehicles and machinery.", minEQF: 4),
        .init(title: "Aircraft Maintenance Technician", category: .transportation, income: 68_000, icon: "🛩️", summary: "Inspects, services, and repairs aircraft.", minEQF: 4),
        // Moving goods: the planning and management behind the vehicles
        .init(title: "Dispatcher", category: .transportation, income: 46_000, icon: "📡", summary: "Routes drivers and crews and tracks deliveries.", minEQF: 3),
        .init(title: "Judge", category: .law, income: 155_000, icon: "👨‍⚖️", summary: "Presides over court proceedings and rulings.", minEQF: 7),
        .init(title: "Security Guard", category: .publicServices, income: 32_000, icon: "🛡️", summary: "Protects property and ensures public safety.", minEQF: 3),
        // Engineering
        .init(title: "Architect", category: .engineering, income: 88_000, icon: "📐", summary: "Designs building plans and structures.", minEQF: 5),
        .init(title: "Chemical Engineer", category: .engineering, income: 82_000, icon: "🧪", summary: "Applies chemistry to industrial processes.", minEQF: 5),
        .init(title: "Aerospace Engineer", category: .engineering, income: 115_000, icon: "🚀", summary: "Designs aircraft, spacecraft, and propulsion systems.", minEQF: 5),
        .init(title: "Fashion Designer", category: .design, income: 55_000, icon: "👗", summary: "Designs clothing collections and sells to buyers.", minEQF: 4),
        // Media / Writing / Broadcast
        .init(title: "Content Writer", category: .showBusiness, income: 44_000, icon: "✍️", summary: "Creates written content for various channels.", minEQF: 4),
        .init(title: "Photographer", category: .showBusiness, income: 40_000, icon: "📷", summary: "Takes photos for commercial and personal use.", minEQF: 3),
        .init(title: "Video Editor", category: .showBusiness, income: 55_000, icon: "🎬", summary: "Cuts and assembles footage for film, TV, and online.", minEQF: 4),
        .init(title: "Social Media Manager", category: .showBusiness, income: 58_000, icon: "📱", summary: "Runs brand presence and campaigns across social platforms.", minEQF: 5),
        // Sports / Fitness
        // Agriculture
        .init(title: "Farmhand", category: .agriculture, income: 28_000, icon: "🧑‍🌾", summary: "Plants, harvests, and tends crops and livestock.", minEQF: 1),
        .init(title: "Farmer", category: .agriculture, income: 32_000, icon: "🚜", summary: "Operates agricultural production and livestock.", minEQF: 2),
        // Arts / Creative
        .init(title: "Musician", category: .showBusiness, income: 34_000, icon: "🎵", summary: "Performs or composes music professionally.", minEQF: 1),
        .init(title: "Actor", category: .showBusiness, income: 38_000, icon: "🎭", summary: "Performs in theater, film, or television.", minEQF: 1),
        .init(title: "Animator", category: .design, income: 65_000, icon: "🎞️", summary: "Animates characters and motion for film, advertising, and games.", minEQF: 4),
        .init(title: "Interior Designer", category: .design, income: 60_000, icon: "🛋️", summary: "Designs and styles indoor spaces for clients.", minEQF: 4),
        // Games — split across design and technology by what the role does
        .init(title: "Level Designer", category: .design, income: 68_000, icon: "🗺️", summary: "Builds and balances the game's levels and pacing.", minEQF: 4),
        .init(title: "Narrative Designer", category: .design, income: 72_000, icon: "✍️", summary: "Writes the story, characters, and branching dialogue.", minEQF: 5),

        // Capstone roles: senior seats that top out a track under their own
        // name rather than as a rung of a ladder.
        .init(title: "Marketing Director", category: .business, income: 145_000, icon: "📣", summary: "Leads the marketing function and brand strategy.", minEQF: 5, minYears: 8),
        .init(title: "Managing Partner", category: .law, income: 220_000, icon: "⚖️", summary: "Equity partner driving client relationships and firm strategy — the top of the law track.", minEQF: 7, minYears: 8),
        .init(title: "Nurse Practitioner", category: .health, income: 125_000, icon: "🥼", summary: "Advanced-practice nurse who diagnoses, treats, and prescribes with autonomy.", minEQF: 6, minYears: 2),
        .init(title: "Art Director", category: .showBusiness, income: 110_000, icon: "🖼️", summary: "Sets the visual direction for campaigns, films, publications, or a game.", minEQF: 5, minYears: 8),
        .init(title: "Chief Medical Officer", category: .health, income: 300_000, icon: "🏥", summary: "Sets clinical strategy and quality across a health system.", minEQF: 7, minYears: 12),
        .init(title: "Chief Technology Officer", category: .technology, income: 320_000, icon: "🧠", summary: "Owns technology strategy for the whole organization.", minEQF: 6, minYears: 12),
        .init(title: "Chief Executive Officer", category: .business, income: 400_000, icon: "👔", summary: "Leads the entire company and answers to the board.", minEQF: 6, minYears: 15),
        .init(title: "Sales Director", category: .business, income: 175_000, icon: "📈", summary: "Owns the entire sales organization and revenue strategy.", minEQF: 5, minYears: 10),
    ]

    // MARK: - Rows: career ladders
    // One role at several seniority levels. The rungs are ordered entry-first
    // and that order *is* the ladder — promotion moves to the next index, so two
    // rungs can never tie for "next". Credentials and soft skills are inherited
    // from the ladder's name via the per-base-title tables.
    static let ladders: [LadderSpec] = [
        // One flight-deck career, not three jobs. First Officer, Pilot and Airline
        // Captain were separate roles with rising experience gates — a ladder
        // written out longhand, which also meant seniority in the seat didn't
        // count toward the seat above it. Each rung keeps its own real title.
        // One logistics-management career, not four jobs. Warehouse, fleet and
        // supply-chain managers are a single BLS occupation (~160k), and the
        // coordinator role is its entry grade — so they are the rungs of it.
        // Fleet Manager is absorbed rather than kept as a rung: it was the same
        // seniority as the warehouse job, just with vehicles instead of racking.
        .init(name: "Logistics Coordinator", category: .transportation, icon: "🗒️", rungs: [
            .init(label: "", income: 52_000, summary: "Schedules shipments and keeps freight moving to plan.", minEQF: 4),
            .init(label: "", income: 70_000, summary: "Runs a distribution site — racking, shifts, and throughput.", minEQF: 4, minYears: 3, icon: "🏬", title: "Warehouse Manager"),
            .init(label: "", income: 98_000, summary: "Owns the end-to-end supply chain and its suppliers.", minEQF: 5, minYears: 6, icon: "🔗", title: "Supply Chain Manager"),
        ]),
        .init(name: "Airline Pilot", category: .transportation, icon: "✈️", rungs: [
            .init(label: "", income: 95_000, summary: "Co-pilots commercial flights alongside the captain.", minEQF: 5, icon: "🧑‍✈️", title: "First Officer"),
            .init(label: "", income: 155_000, summary: "Operates aircraft for passenger or cargo flights.", minEQF: 5, icon: "✈️", title: "Pilot"),
            .init(label: "", income: 205_000, summary: "Commands the flight deck of commercial airliners.", minEQF: 5, icon: "👨‍✈️", title: "Airline Captain"),
        ]),
        // Modelling is the entry rung of this craft rather than a separate job:
        // "3D Modeler" carried a nearly identical skill profile and sat below the
        // base rung on pay, so it is that ladder's first step.
        .init(name: "3D Artist", category: .design, icon: "🎨", rungs: [
            .init(label: "Junior", income: 58_000, summary: "Sculpts characters, props, and environments as 3D assets.", minEQF: 4, icon: "🧊"),
            // Games — art, design and engineering ladders inside a studio
            .init(label: "", income: 64_000, summary: "Creates textured, lit 3D art for games and film.", minEQF: 4, minYears: 2),
            .init(label: "Senior", income: 95_000, summary: "Owns key art and sets the visual bar for the team.", minEQF: 4, minYears: 5),
        ]),
        .init(name: "Accountant", category: .administration, icon: "📒", rungs: [
            // Business / Finance
            .init(label: "Junior", income: 52_000, summary: "Books transactions and supports month-end close.", minEQF: 4, minYears: 0),
            .init(label: "", income: 72_000, summary: "Prepares financial records and statements.", minEQF: 5),
            .init(label: "Senior", income: 105_000, summary: "Owns ledger areas and supervises junior accountants.", minEQF: 5, minYears: 4),
        ]),
        .init(name: "Business Analyst", category: .business, icon: "📈", rungs: [
            .init(label: "Junior", income: 58_000, summary: "Gathers requirements and documents processes.", minEQF: 4, minYears: 0),
            .init(label: "", income: 80_000, summary: "Analyzes business needs and recommends solutions.", minEQF: 5),
            .init(label: "Senior", income: 115_000, summary: "Leads cross-functional analysis and drives recommendations.", minEQF: 5, minYears: 4),
        ]),
        .init(name: "Carpenter", category: .construction, icon: "🪚", rungs: [
            .init(label: "Apprentice", income: 34_000, summary: "Learns carpentry on site under a master carpenter.", minEQF: 3, minYears: 0),
            .init(label: "", income: 52_000, summary: "Builds and repairs wooden structures.", minEQF: 4),
            .init(label: "Master", income: 76_000, summary: "Master tradesperson on bespoke and large-scale builds.", minEQF: 4, minYears: 6),
        ]),
        .init(name: "Chef", category: .hospitality, icon: "👨‍🍳", rungs: [
            .init(label: "", income: 52_000, summary: "Prepares meals in restaurants or institutions; entry rung of the kitchen ladder.", minEQF: 3),
            // Hospitality (chef ladder)
            .init(label: "Sous", income: 65_000, summary: "Second-in-command in the kitchen, runs daily service.", minEQF: 4, minYears: 3),
            .init(label: "Head", income: 92_000, summary: "Owns menu, sourcing, and kitchen leadership.", minEQF: 4, minYears: 6),
            .init(label: "Executive", income: 140_000, summary: "Oversees multiple kitchens and culinary brand.", minEQF: 4, minYears: 10),
        ]),
        .init(name: "Civil Engineer", category: .engineering, icon: "🛣️", rungs: [
            // Engineering disciplines
            .init(label: "Junior", income: 64_000, summary: "Drafts plans and supports senior engineers on site.", minEQF: 5, minYears: 0),
            .init(label: "", income: 88_000, summary: "Designs infrastructure and public works.", minEQF: 5),
            .init(label: "Senior", income: 125_000, summary: "Leads infrastructure projects and signs off on designs.", minEQF: 5, minYears: 6),
        ]),
        .init(name: "Data Analyst", category: .technology, icon: "📊", rungs: [
            .init(label: "Junior", income: 62_000, summary: "Builds basic dashboards and runs ad-hoc queries under supervision.", minEQF: 4, minYears: 0),
            .init(label: "", income: 85_000, summary: "Analyzes data to inform decisions.", minEQF: 5),
            .init(label: "Senior", income: 118_000, summary: "Owns analytical workstreams and partners with leadership on decisions.", minEQF: 5, minYears: 4),
        ]),
        .init(name: "Data Scientist", category: .technology, icon: "📈", rungs: [
            .init(label: "Junior", income: 95_000, summary: "Builds and validates models under senior data-science guidance.", minEQF: 5, minYears: 0),
            .init(label: "", income: 130_000, summary: "Builds models and extracts insight from large datasets.", minEQF: 5),
        ]),
        .init(name: "Electrical Engineer", category: .engineering, icon: "🔋", rungs: [
            .init(label: "Junior", income: 64_000, summary: "Supports design and testing of electrical systems.", minEQF: 5, minYears: 0),
            .init(label: "", income: 86_000, summary: "Designs electrical systems and circuits.", minEQF: 5),
            .init(label: "Senior", income: 122_000, summary: "Leads electrical-system architecture for complex products.", minEQF: 5, minYears: 6),
        ]),
        .init(name: "Electrician", category: .construction, icon: "🔌", rungs: [
            // Trades — apprentice entry beneath the journeyman base role and master
            .init(label: "Apprentice", income: 40_000, summary: "Trains on the job toward a journeyman electrician license.", minEQF: 3, minYears: 0),
            .init(label: "", income: 62_000, summary: "Installs and repairs electrical systems.", minEQF: 4),
            // Construction trades
            .init(label: "Master", income: 92_000, summary: "Licensed master responsible for jobs and apprentices.", minEQF: 4, minYears: 5),
        ]),
        .init(name: "Financial Analyst", category: .business, icon: "💹", rungs: [
            .init(label: "Junior", income: 68_000, summary: "Builds forecasting models with senior oversight.", minEQF: 5, minYears: 0),
            // Business / Finance
            .init(label: "", income: 95_000, summary: "Analyzes financial performance and forecasts.", minEQF: 5),
            .init(label: "Senior", income: 140_000, summary: "Partners with executives on capital planning and strategy.", minEQF: 5, minYears: 5),
        ]),
        .init(name: "Firefighter", category: .publicServices, icon: "🔥", rungs: [
            .init(label: "", income: 57_000, summary: "Responds to fires, accidents, and rescue emergencies.", minEQF: 3),
            // Public Services — Firefighting / Rescue track (base "Firefighter")
            .init(label: "Senior", income: 85_000, summary: "Experienced firefighter leading a crew on emergency calls.", minEQF: 3, minYears: 6, icon: "🚒"),
            .init(label: "Lead", income: 120_000, summary: "Commands a fire station and emergency operations.", minEQF: 4, minYears: 12, icon: "🚒"),
        ]),
        .init(name: "Game Designer", category: .design, icon: "🎮", rungs: [
            .init(label: "", income: 78_000, summary: "Designs mechanics, systems, and the player experience.", minEQF: 5),
            .init(label: "Senior", income: 115_000, summary: "Owns major game systems and mentors designers.", minEQF: 5, minYears: 5),
            .init(label: "Lead", income: 150_000, summary: "Sets the design vision for the entire title.", minEQF: 5, minYears: 9),
        ]),
        .init(name: "Graphic Artist", category: .design, icon: "🎨", rungs: [
            .init(label: "Junior", income: 36_000, summary: "Produces assets to spec under art-director review.", minEQF: 3, minYears: 0),
            // Design
            .init(label: "", income: 50_000, summary: "Creates visual artwork for media.", minEQF: 4),
            .init(label: "Senior", income: 72_000, summary: "Owns visual identity work and directs junior artists.", minEQF: 4, minYears: 4),
        ]),
        .init(name: "Investment Banker", category: .business, icon: "🏦", rungs: [
            .init(label: "Junior", income: 110_000, summary: "Analyst building models and pitch decks on live deals under senior bankers.", minEQF: 5, minYears: 0),
            .init(label: "", income: 175_000, summary: "Structures deals, raises capital, and advises on M&A.", minEQF: 5),
        ]),
        .init(name: "Lab Technician", category: .science, icon: "🧪", rungs: [
            // Science
            // Science — two tracks: a Lab Technician trade ladder and a
            // doctorate-gated Research Scientist ladder (Senior/Lead/Principal
            // rungs live in the seniority ladders below).
            .init(label: "", income: 42_000, summary: "Runs lab tests, preps samples, and records results.", minEQF: 4),
            // Science — Laboratory track (base "Lab Technician")
            .init(label: "Senior", income: 58_000, summary: "Leads lab testing and trains junior technicians.", minEQF: 4, minYears: 5),
            .init(label: "Lead", income: 74_000, summary: "Runs the lab's daily operations, safety, and quality.", minEQF: 5, minYears: 9, icon: "🔬"),
        ]),
        .init(name: "Lawyer", category: .law, icon: "⚖️", rungs: [
            // Law / Public Services
            .init(label: "", income: 125_000, summary: "Provides legal advice and represents clients.", minEQF: 7),
            // Law — associate → senior associate → partner
            .init(label: "Senior", income: 170_000, summary: "Senior associate leading cases and mentoring junior lawyers.", minEQF: 7, minYears: 6),
        ]),
        .init(name: "Management Consultant", category: .business, icon: "🧠", rungs: [
            .init(label: "Junior", income: 85_000, summary: "Runs analysis workstreams on client engagements under a lead consultant.", minEQF: 5, minYears: 0),
            .init(label: "", income: 140_000, summary: "Advises companies on strategy and operations.", minEQF: 5),
        ]),
        .init(name: "Marketing Specialist", category: .business, icon: "📣", rungs: [
            .init(label: "Junior", income: 46_000, summary: "Executes campaigns under direction from senior marketers.", minEQF: 4, minYears: 0),
            .init(label: "", income: 64_000, summary: "Creates and runs marketing campaigns.", minEQF: 5),
            .init(label: "Senior", income: 94_000, summary: "Owns marketing programs and reports on impact.", minEQF: 5, minYears: 4),
        ]),
        .init(name: "Mechanical Engineer", category: .engineering, icon: "⚙️", rungs: [
            .init(label: "Junior", income: 62_000, summary: "Assists in design and analysis of mechanical components.", minEQF: 5, minYears: 0),
            .init(label: "", income: 84_000, summary: "Designs mechanical systems and machinery.", minEQF: 5),
            .init(label: "Senior", income: 120_000, summary: "Owns mechanical design projects end-to-end.", minEQF: 5, minYears: 6),
        ]),
        // Show business, trimmed to the roles real employment supports. Three
        // pairs here were one occupation apiece, split across two rows:
        // BLS counts gym instructors and personal trainers together (~340k, much
        // the largest role in this category), an anchor is the senior presenter,
        // and an editor-in-chief is where a newsroom career ends up. Dancer
        // (~17k) and fine-art Painter (~11k) were cut outright — the long tail
        // of the category, and the roles a player was least likely to be able to
        // make a living at anyway.
        .init(name: "Fitness Instructor", category: .showBusiness, icon: "🤸", rungs: [
            .init(label: "", income: 34_000, summary: "Leads group exercise and gym classes.", minEQF: 2),
            .init(label: "", income: 40_000, summary: "Coaches clients one-on-one toward their goals.", minEQF: 3, minYears: 2, icon: "🏋️", title: "Personal Trainer"),
        ]),
        .init(name: "TV Presenter", category: .showBusiness, icon: "📺", rungs: [
            .init(label: "", income: 70_000, summary: "Presents television programs and live segments.", minEQF: 5),
            .init(label: "", income: 95_000, summary: "Anchors television news broadcasts.", minEQF: 5, minYears: 3, icon: "🎙️", title: "News Anchor"),
        ]),
        .init(name: "Journalist", category: .showBusiness, icon: "📰", rungs: [
            .init(label: "", income: 48_000, summary: "Reports news and stories for media outlets.", minEQF: 5),
            .init(label: "Senior", income: 78_000, summary: "Runs a beat and breaks the stories others follow.", minEQF: 5, minYears: 5),
            .init(label: "", income: 135_000, summary: "Leads a publication's editorial vision and newsroom.", minEQF: 5, minYears: 10, icon: "🗞️", title: "Editor-in-Chief"),
        ]),
        .init(name: "Movie Star", category: .showBusiness, icon: "🌟", rungs: [
            // Acting — the movie-star track, opened by a "Breakout Role" project.
            .init(label: "Rising", income: 90_000, summary: "A working screen actor landing real roles off a breakout part.", minEQF: 0, minYears: 0, icon: "🎬"),
            .init(label: "", income: 260_000, summary: "A bankable lead whose name sells tickets.", minEQF: 0, minYears: 3),
            .init(label: "A-List", income: 800_000, summary: "A global marquee name commanding top billing and huge paydays.", minEQF: 0, minYears: 7, icon: "🏆"),
        ]),
        .init(name: "Municipal Worker", category: .publicServices, icon: "🧹", rungs: [
            .init(label: "", income: 40_000, summary: "Keeps the city running — sanitation, parks, roads, and facilities.", minEQF: 2),
            // Public Services — Municipal Services track (base "Municipal Worker")
            .init(label: "Senior", income: 55_000, summary: "Seasoned public-works hand running crews and equipment.", minEQF: 2, minYears: 5, icon: "🧰"),
            .init(label: "Lead", income: 72_000, summary: "Supervises municipal crews, budgets, and city services.", minEQF: 3, minYears: 10, icon: "🏛️"),
        ]),
        .init(name: "Paralegal", category: .law, icon: "📑", rungs: [
            // Law
            .init(label: "Junior", income: 38_000, summary: "Files documents and supports research for senior staff.", minEQF: 3, minYears: 0),
            .init(label: "", income: 48_000, summary: "Assists lawyers with research and documentation.", minEQF: 4),
            .init(label: "Senior", income: 65_000, summary: "Manages caseload research and trains junior paralegals.", minEQF: 4, minYears: 4),
        ]),
        .init(name: "Physician", category: .health, icon: "🩺", rungs: [
            // Health
            .init(label: "", income: 220_000, summary: "Diagnoses and treats illnesses.", minEQF: 7),
            // Medicine — attending rung between resident physician and CMO
            .init(label: "Senior", income: 280_000, summary: "Attending physician supervising residents and complex cases.", minEQF: 7, minYears: 5),
        ]),
        .init(name: "Player", category: .showBusiness, icon: "🥅", rungs: [
            // Breakthrough-gated star tracks — the rare, lottery-upside careers.
            // Each entry rung is easy to *qualify* for (no degree, no tenure) but
            // effectively closed without its signature achievement: hire odds sit
            // at the 5% floor until you hold it (see `Job.breakthroughFameByRole`).
            // Athletics — the pro-player track, opened by a junior-competition win
            // ("Junior Champion", from the teen Junior Championship).
            .init(label: "Amateur", income: 30_000, summary: "Signed to a club's development squad after a standout junior career.", minEQF: 1, minYears: 0),
            .init(label: "Professional", income: 130_000, summary: "Earns a living on a professional team's roster.", minEQF: 1, minYears: 3, icon: "⚽"),
            .init(label: "Elite", income: 320_000, summary: "A marquee starter with major contracts and sponsorships.", minEQF: 1, minYears: 7, icon: "🌟"),
        ]),
        .init(name: "Plumber", category: .construction, icon: "🚰", rungs: [
            .init(label: "Apprentice", income: 40_000, summary: "Learns the plumbing trade under a licensed plumber.", minEQF: 3, minYears: 0),
            .init(label: "", income: 60_000, summary: "Installs and repairs plumbing systems.", minEQF: 4),
            .init(label: "Master", income: 88_000, summary: "Licensed master plumber leading complex installations.", minEQF: 4, minYears: 5),
        ]),
        .init(name: "Police Officer", category: .publicServices, icon: "👮", rungs: [
            // Public Services — three tracks, each climbed by seniority:
            // Law Enforcement (Police Officer), Firefighting/Rescue (Firefighter),
            // and Municipal Services (Municipal Worker). Entry rungs here; the
            // Senior/Lead rungs live in the seniority ladders below.
            .init(label: "", income: 67_000, summary: "Enforces laws and protects the public on patrol.", minEQF: 3),
            // Public Services — Law Enforcement track (base "Police Officer")
            .init(label: "Senior", income: 95_000, summary: "Veteran officer leading patrols and mentoring recruits.", minEQF: 3, minYears: 5),
            .init(label: "Lead", income: 130_000, summary: "Commands a precinct and sets policing strategy.", minEQF: 4, minYears: 12, icon: "🚓"),
        ]),
        .init(name: "Pop Star", category: .showBusiness, icon: "🌟", rungs: [
            // Music — the pop-star track, opened by a "Hit Record" project.
            .init(label: "Rising", income: 85_000, summary: "A charting artist touring off a breakout hit.", minEQF: 0, minYears: 0, icon: "🎤"),
            .init(label: "", income: 240_000, summary: "A headline act with hit records and sold-out shows.", minEQF: 0, minYears: 3),
            .init(label: "A-List", income: 700_000, summary: "A global superstar with stadium tours and chart dominance.", minEQF: 0, minYears: 7, icon: "🏆"),
        ]),
        .init(name: "Project Manager", category: .business, icon: "📋", rungs: [
            .init(label: "", income: 98_000, summary: "Plans and oversees projects to completion.", minEQF: 5),
            .init(label: "Senior", income: 145_000, summary: "Manages portfolios of projects and senior stakeholders.", minEQF: 5, minYears: 7),
            // Business — top rung / sales leadership capstone
            .init(label: "Lead", income: 175_000, summary: "Heads the PMO and the organization's most critical programs.", minEQF: 5, minYears: 10),
        ]),
        .init(name: "Registered Nurse", category: .health, icon: "🩺", rungs: [
            .init(label: "", income: 81_000, summary: "Provides patient care, administers medication, and coordinates with medical teams.", minEQF: 5),
            // Health
            .init(label: "Senior", income: 110_000, summary: "Experienced floor nurse mentoring newer staff.", minEQF: 5, minYears: 5),
            .init(label: "Charge", income: 130_000, summary: "Coordinates the nursing shift and triages escalations — the top of the floor-nursing ladder.", minEQF: 5, minYears: 8),
        ]),
        .init(name: "Research Scientist", category: .science, icon: "🔬", rungs: [
            // Science — Research track (base "Research Scientist", doctorate-gated)
            .init(label: "Junior", income: 72_000, summary: "Early-career scientist running experiments under a senior lead.", minEQF: 7, minYears: 0),
            .init(label: "", income: 90_000, summary: "Designs and runs experiments to answer scientific questions.", minEQF: 7),
            .init(label: "Senior", income: 145_000, summary: "Leads research programs and publishes original work.", minEQF: 7, minYears: 6),
            .init(label: "Principal", income: 195_000, summary: "Sets research agenda for the lab and supervises projects.", minEQF: 7, minYears: 10),
        ]),
        .init(name: "Sales Manager", category: .business, icon: "📈", rungs: [
            .init(label: "", income: 98_000, summary: "Leads sales teams and strategies.", minEQF: 5),
            .init(label: "Senior", income: 150_000, summary: "Runs regional sales orgs and hits aggressive targets.", minEQF: 5, minYears: 7),
        ]),
        .init(name: "Software Engineer", category: .technology, icon: "💻", rungs: [
            // Technology
            .init(label: "Junior", income: 78_000, summary: "Entry-level developer learning the codebase and shipping small features.", minEQF: 5, minYears: 0),
            // Technology
            .init(label: "", income: 115_000, summary: "Designs and implements software systems.", minEQF: 5),
            .init(label: "Senior", income: 155_000, summary: "Owns major systems, mentors peers, and drives technical direction.", minEQF: 5, minYears: 5),
            .init(label: "Staff", income: 200_000, summary: "Sets engineering strategy across teams and unblocks complex initiatives.", minEQF: 6, minYears: 9),
            .init(label: "Principal", income: 245_000, summary: "Top-of-ladder IC; defines architecture for the whole organization.", minEQF: 6, minYears: 12),
        ]),
        .init(name: "Systems Administrator", category: .technology, icon: "🖧", rungs: [
            // MARK: Added rungs so every professional track has ≥3 levels.
            // Prefixed rungs gate on same-track (per-role) experience; the
            // Director/Partner capstones stay reachable on broad industry years.
            // Tech — junior entry beneath the Systems Administrator ladder
            .init(label: "Junior", income: 62_000, summary: "Maintains servers and accounts under senior guidance.", minEQF: 4, minYears: 0),
            .init(label: "", income: 80_000, summary: "Maintains IT infrastructure.", minEQF: 4),
            .init(label: "Senior", income: 110_000, summary: "Architects infrastructure and leads incident response.", minEQF: 4, minYears: 5),
        ]),
        .init(name: "Teacher", category: .education, icon: "🏫", rungs: [
            .init(label: "", income: 48_000, summary: "Teaches a class of students their core subjects.", minEQF: 5),
            // Education — Teacher track (base "Teacher", degree-gated)
            .init(label: "Senior", income: 66_000, summary: "Veteran teacher mentoring staff and leading a department.", minEQF: 5, minYears: 6, icon: "📚"),
            .init(label: "Lead", income: 92_000, summary: "Heads the school's academics and leads the teaching staff.", minEQF: 6, minYears: 11, icon: "🍎"),
        ]),
        .init(name: "Tutor", category: .education, icon: "📖", rungs: [
            // Education — two tracks: an accessible Tutor ladder and a
            // degree-gated Teacher ladder (Senior/Lead rungs in the seniority
            // ladders below).
            .init(label: "", income: 34_000, summary: "Coaches students one-on-one in specific subjects.", minEQF: 3),
            // Education — Tutor track (base "Tutor", accessible)
            .init(label: "Senior", income: 46_000, summary: "Experienced tutor running group sessions and mentoring tutors.", minEQF: 4, minYears: 5),
            .init(label: "Lead", income: 60_000, summary: "Runs a tutoring center's staff, curriculum, and clients.", minEQF: 5, minYears: 9),
        ]),
        .init(name: "UX/UI Designer", category: .design, icon: "🖥️", rungs: [
            // Design
            .init(label: "Junior", income: 60_000, summary: "Produces wireframes and visual assets under senior direction.", minEQF: 4, minYears: 0),
            .init(label: "", income: 82_000, summary: "Designs user interfaces and experiences.", minEQF: 5),
            .init(label: "Senior", income: 120_000, summary: "Leads end-to-end design of major product surfaces.", minEQF: 5, minYears: 5),
            .init(label: "Lead", income: 155_000, summary: "Sets design vision and mentors the design team.", minEQF: 5, minYears: 8),
        ]),
    ]

    // MARK: - Rows: ventures (concrete, industry-specific founder plays)
    // Each venture is a real business idea in a real industry, not a generic
    // "startup". They're one-off founder bets — no auto-climbing ladder — and you
    // run one at a time (it becomes your occupation until you sell out or go
    // bankrupt; see `Player.foundVenture` and the Boardroom). What flags a role
    // as a venture is its `targetCapital` (`Job.isEntrepreneurial`), not its
    // category — so each keeps its true industry category, which means your
    // relevant work experience *in that field* feeds the launch odds
    // (`Job.founderSuccessProbability` weights experience + soft-skill fit over
    // raw capital). Founders aren't gated on degrees (`minEQF: 0`); the gate is
    // the years of industry experience the idea demands.
    static let ventures: [JobSpec] = [
        .init(title: "Specialty Coffee Roastery", category: .retail, income: 46_000, icon: "☕", summary: "Source, roast, and sell your own beans through a café and online.", minYears: 1, targetCapital: 30_000),
        .init(title: "Boutique Fitness Studio", category: .health, income: 52_000, icon: "🏋️", summary: "Run your own small-group training studio and build a member community.", minYears: 2, targetCapital: 35_000),
        .init(title: "Farm-to-Table Restaurant", category: .hospitality, income: 60_000, icon: "🍽️", summary: "Open a seasonal restaurant sourcing straight from local growers.", minYears: 3, targetCapital: 80_000),
        .init(title: "Indie Game Studio", category: .technology, income: 85_000, icon: "🎮", summary: "Bootstrap a small studio and ship an original game to players.", minYears: 3, targetCapital: 55_000),
        .init(title: "Property Development Firm", category: .construction, income: 110_000, icon: "🏗️", summary: "Buy, build, and sell property — financing projects and managing crews.", minYears: 4, targetCapital: 120_000),
        .init(title: "SaaS App Startup", category: .technology, income: 120_000, icon: "💻", summary: "Build a subscription software product and grow it toward a real raise.", minYears: 3, targetCapital: 60_000),
    ]

    /// Every job title in the game, ladder rungs included.
    static let allTitles: [String] =
        standaloneRoles.map(\.title)
        + ladders.flatMap { ladder in ladder.rungs.map { ladder.title(for: $0) } }
        + ventures.map(\.title)

    /// Every base title: a ladder's name, or a standalone role's own title.
    static let allBaseTitles: [String] =
        standaloneRoles.map(\.title) + ladders.map(\.name) + ventures.map(\.title)

    /// Builds the full job database. Salaries are the present-day published
    /// figures; a small random variance is applied when each `Job` is constructed.
    /// The whole market. **Not deterministic**: each posting draws its employer's
    /// sector from the markets that role can sit in, so re-reading the catalogue
    /// is a fresh year's listings rather than the same ones again. `Player`
    /// re-reads it every year (see `regenerateAvailableJobs`).
    static func allJobs() -> [Job] {
        standaloneRoles.map(job(from:))
            + ladders.flatMap(jobs(for:))
            + ventures.map(job(from:))
    }

    /// Role pictogram keyed by base title — for surfacing a role's own industry
    /// icon in places that only hold the title string (e.g. the Experience list,
    /// which is keyed by `Job.baseTitle`). Deterministic, so it's built once.
    static let iconByBaseTitle: [String: String] = {
        var map: [String: String] = [:]
        for spec in standaloneRoles where map[spec.title] == nil { map[spec.title] = spec.icon }
        for ladder in ladders where map[ladder.name] == nil { map[ladder.name] = ladder.icon }
        for spec in ventures where map[spec.title] == nil { map[spec.title] = spec.icon }
        return map
    }()
}

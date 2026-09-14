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
    /// Named fields rather than a positional tuple: `icon` and `summary` are both
    /// `String` and adjacent, and the seniority and venture rows used to share
    /// the identical tuple type `(String, JobCategory, Int, String, String, Int,
    /// Int)` while their trailing pair meant different things — so a swapped or
    /// misplaced row compiled cleanly and produced a wrong job.
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

    /// Soft skills for *one exact title*, where a hand-tuned profile must not be
    /// inherited by the rest of its ladder — a registered nurse's profile is not
    /// the senior and charge rungs'. Wins over `softSkillsByBaseTitle`, the same
    /// way `credentialsByFullTitle` wins over `credentialsByBaseTitle`.
    static let softSkillsByFullTitle: [String: SoftSkills] = [
        "Registered Nurse": .init(
                  analyticalReasoningAndProblemSolving: 2, creativityAndInsightfulThinking: 0,
                  communicationAndNetworking: 3, leadershipAndInfluence: 1,
                  visionaryThinkingAndAmbition: 0, carefulnessAndAttentionToDetail: 4,
                  tinkeringAndFingerPrecision: 2, spacialNavigationAndOrientation: 0,
                  resilienceAndEndurance: 3, stressResistanceAndEmotionalRegulation: 3,
                  empathyAndInterpersonalCare: 3, outdoorAndWeatherResilience: 0,
                  collaborationAndTeamwork: 3, timeManagementAndPlanning: 2,
                  selfDisciplineAndPerseverance: 2, presentationAndStorytelling: 1
              ),
        "Light Truck Delivery Driver": .init(
                  analyticalReasoningAndProblemSolving: 0, creativityAndInsightfulThinking: 0,
                  communicationAndNetworking: 1, leadershipAndInfluence: 0,
                  visionaryThinkingAndAmbition: 0, carefulnessAndAttentionToDetail: 2,
                  tinkeringAndFingerPrecision: 0, spacialNavigationAndOrientation: 2,
                  resilienceAndEndurance: 2, stressResistanceAndEmotionalRegulation: 1,
                  outdoorAndWeatherResilience: 1, collaborationAndTeamwork: 1,
                  timeManagementAndPlanning: 2, selfDisciplineAndPerseverance: 1,
                  presentationAndStorytelling: 0
              ),
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
        "Recruiter":                      .init(communicationAndNetworking: 3, persuasionAndNegotiation: 3, carefulnessAndAttentionToDetail: 1, empathyAndInterpersonalCare: 2, timeManagementAndPlanning: 2, presentationAndStorytelling: 1),
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
        "Bookkeeper":                     .init(analyticalReasoningAndProblemSolving: 2, carefulnessAndAttentionToDetail: 4, timeManagementAndPlanning: 2, selfDisciplineAndPerseverance: 2),
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
        "Personal Trainer":               .init(communicationAndNetworking: 3, persuasionAndNegotiation: 2, leadershipAndInfluence: 1, carefulnessAndAttentionToDetail: 1, resilienceAndEndurance: 3, stressResistanceAndEmotionalRegulation: 1, empathyAndInterpersonalCare: 3, collaborationAndTeamwork: 1, timeManagementAndPlanning: 2, selfDisciplineAndPerseverance: 3, presentationAndStorytelling: 2),
        "Fitness Instructor":             .init(communicationAndNetworking: 3, leadershipAndInfluence: 1, resilienceAndEndurance: 3, stressResistanceAndEmotionalRegulation: 1, empathyAndInterpersonalCare: 2, collaborationAndTeamwork: 1, timeManagementAndPlanning: 1, selfDisciplineAndPerseverance: 2, presentationAndStorytelling: 3),

        // Gaming industry (art, design, and engineering that ship games)
        "3D Modeler":                     .init(creativityAndInsightfulThinking: 3, carefulnessAndAttentionToDetail: 2, tinkeringAndFingerPrecision: 2, spacialNavigationAndOrientation: 3, timeManagementAndPlanning: 1, selfDisciplineAndPerseverance: 2),
        "3D Artist":                      .init(creativityAndInsightfulThinking: 4, carefulnessAndAttentionToDetail: 2, tinkeringAndFingerPrecision: 1, spacialNavigationAndOrientation: 3, selfDisciplineAndPerseverance: 2, presentationAndStorytelling: 1),
        "Game Animator":                  .init(creativityAndInsightfulThinking: 3, carefulnessAndAttentionToDetail: 2, tinkeringAndFingerPrecision: 2, spacialNavigationAndOrientation: 2, timeManagementAndPlanning: 1, selfDisciplineAndPerseverance: 2),
        "Level Designer":                 .init(analyticalReasoningAndProblemSolving: 3, creativityAndInsightfulThinking: 3, carefulnessAndAttentionToDetail: 2, spacialNavigationAndOrientation: 3, collaborationAndTeamwork: 2, timeManagementAndPlanning: 1),
        "Game Designer":                  .init(analyticalReasoningAndProblemSolving: 3, creativityAndInsightfulThinking: 4, communicationAndNetworking: 2, visionaryThinkingAndAmbition: 2, collaborationAndTeamwork: 2, timeManagementAndPlanning: 2, presentationAndStorytelling: 2),
        "Narrative Designer":             .init(creativityAndInsightfulThinking: 4, communicationAndNetworking: 3, carefulnessAndAttentionToDetail: 2, selfDisciplineAndPerseverance: 2, presentationAndStorytelling: 4),
        "Gameplay Programmer":            .init(analyticalReasoningAndProblemSolving: 4, creativityAndInsightfulThinking: 2, carefulnessAndAttentionToDetail: 3, tinkeringAndFingerPrecision: 1, collaborationAndTeamwork: 2, timeManagementAndPlanning: 2, selfDisciplineAndPerseverance: 3),
        "Technical Artist":               .init(analyticalReasoningAndProblemSolving: 3, creativityAndInsightfulThinking: 3, carefulnessAndAttentionToDetail: 2, tinkeringAndFingerPrecision: 2, spacialNavigationAndOrientation: 2, collaborationAndTeamwork: 2, selfDisciplineAndPerseverance: 2),
        "Game Producer":                  .init(analyticalReasoningAndProblemSolving: 2, communicationAndNetworking: 3, persuasionAndNegotiation: 2, leadershipAndInfluence: 3, carefulnessAndAttentionToDetail: 2, collaborationAndTeamwork: 3, timeManagementAndPlanning: 4),
        "Game QA Tester":                 .init(analyticalReasoningAndProblemSolving: 2, communicationAndNetworking: 2, carefulnessAndAttentionToDetail: 4, collaborationAndTeamwork: 2, selfDisciplineAndPerseverance: 2),
        "Art Director (Games)":           .init(creativityAndInsightfulThinking: 4, communicationAndNetworking: 3, leadershipAndInfluence: 3, visionaryThinkingAndAmbition: 2, carefulnessAndAttentionToDetail: 2, collaborationAndTeamwork: 2, presentationAndStorytelling: 2),
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
        "Pilot": HardSkills(trainings: [.commercialPilot]),
        "First Officer": HardSkills(trainings: [.commercialPilot]),
        "Airline Captain": HardSkills(trainings: [.commercialPilot]),
        "Air Traffic Controller": HardSkills(trainings: [.atcCertification]),
        // Trades — licensed by law in most jurisdictions
        "Electrician": HardSkills(trainings: [.electrician]),
        "Plumber": HardSkills(trainings: [.plumber]),
        "Architect": HardSkills(trainings: [.architect]),
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
        "Dental Assistant": HardSkills(trainings: [.dentalAssistant]),
        "Nursing Aide": HardSkills(trainings: [.cna]),
        // Law / public services. Keys are base titles, so one entry covers every
        // rung of a ladder ("Firefighter" also gates Senior/Lead Firefighter).
        "Lawyer": HardSkills(trainings: [.bar]),
        "Judge": HardSkills(trainings: [.bar]),
        "Managing Partner": HardSkills(trainings: [.bar]),
        "Firefighter": HardSkills(trainings: [.emt]),
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
        "Hotel Manager": 3,
        "Sales Manager": 3,
        "Project Manager": 3,
        "Event Planner": 3,
        "Human Resources Specialist": 3,
        "Business Analyst": 2,
        "Financial Analyst": 2,
        "Marketing Specialist": 2,
        // Security is a second-career field — hired out of IT/networking, not
        // straight from school.
        "Cybersecurity Analyst": 2,
        // Anchors are promoted after years of on-air reporting.
        "News Anchor": 3,
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
        "Supply Chain Manager": 4,
        "Fleet Manager": 4,
        "Warehouse Manager": 3,
        "Office Manager": 3,
    ]

    // MARK: - Accepted degree fields

    /// Per-title override where a role draws on a discipline the category map
    /// doesn't capture — an architecture degree reads as design or arts as
    /// readily as engineering, so an Architect shouldn't be gated to
    /// engineering/science/technology degrees.
    static let acceptedProfilesByBaseTitle: [String: [TertiaryProfile]] = [
        "Architect": [.engineering, .design, .arts],
    ]

    // MARK: - Category defaults

    static func defaultSoftSkills(for category: JobCategory) -> SoftSkills {
        switch category {

        case .technology, .engineering:
            return .init(
                analyticalReasoningAndProblemSolving: 3,
                creativityAndInsightfulThinking: 1,
                communicationAndNetworking: 1,
                leadershipAndInfluence: 0,
                visionaryThinkingAndAmbition: 1,
                carefulnessAndAttentionToDetail: 3,
                tinkeringAndFingerPrecision: 1,
                spacialNavigationAndOrientation: 0,
                resilienceAndEndurance: 1,
                stressResistanceAndEmotionalRegulation: 2,
                outdoorAndWeatherResilience: 0,
                collaborationAndTeamwork: 2,
                timeManagementAndPlanning: 2,
                selfDisciplineAndPerseverance: 3,
                presentationAndStorytelling: 1
            )

        case .gaming:
            return .init(
                analyticalReasoningAndProblemSolving: 2,
                creativityAndInsightfulThinking: 3,
                communicationAndNetworking: 1,
                visionaryThinkingAndAmbition: 1,
                carefulnessAndAttentionToDetail: 2,
                tinkeringAndFingerPrecision: 1,
                spacialNavigationAndOrientation: 2,
                stressResistanceAndEmotionalRegulation: 1,
                collaborationAndTeamwork: 2,
                timeManagementAndPlanning: 2,
                selfDisciplineAndPerseverance: 2,
                presentationAndStorytelling: 1
            )

        case .health, .education:
            return .init(
                analyticalReasoningAndProblemSolving: 2,
                creativityAndInsightfulThinking: 0,
                communicationAndNetworking: 3,
                leadershipAndInfluence: 1,
                visionaryThinkingAndAmbition: 0,
                carefulnessAndAttentionToDetail: 3,
                tinkeringAndFingerPrecision: 0,
                spacialNavigationAndOrientation: 0,
                resilienceAndEndurance: 3,
                stressResistanceAndEmotionalRegulation: 3,
                empathyAndInterpersonalCare: 3,
                outdoorAndWeatherResilience: 0,
                collaborationAndTeamwork: 3,
                timeManagementAndPlanning: 2,
                selfDisciplineAndPerseverance: 2,
                presentationAndStorytelling: 2
            )

        case .service, .hospitality, .retail, .tourism:
            return .init(
                analyticalReasoningAndProblemSolving: 0,
                creativityAndInsightfulThinking: 1,
                communicationAndNetworking: 3,
                persuasionAndNegotiation: 1,
                leadershipAndInfluence: 0,
                visionaryThinkingAndAmbition: 0,
                carefulnessAndAttentionToDetail: 1,
                tinkeringAndFingerPrecision: 0,
                spacialNavigationAndOrientation: 0,
                resilienceAndEndurance: 2,
                stressResistanceAndEmotionalRegulation: 2,
                empathyAndInterpersonalCare: 2,
                outdoorAndWeatherResilience: 0,
                collaborationAndTeamwork: 2,
                timeManagementAndPlanning: 1,
                selfDisciplineAndPerseverance: 1,
                presentationAndStorytelling: 2
            )

        case .construction, .manufacturing, .automotive:
            return .init(
                analyticalReasoningAndProblemSolving: 1,
                creativityAndInsightfulThinking: 0,
                communicationAndNetworking: 0,
                leadershipAndInfluence: 0,
                visionaryThinkingAndAmbition: 0,
                carefulnessAndAttentionToDetail: 2,
                tinkeringAndFingerPrecision: 3,
                spacialNavigationAndOrientation: 2,
                resilienceAndEndurance: 3,
                stressResistanceAndEmotionalRegulation: 1,
                outdoorAndWeatherResilience: 1,
                collaborationAndTeamwork: 1,
                timeManagementAndPlanning: 1,
                selfDisciplineAndPerseverance: 1,
                presentationAndStorytelling: 0
            )

        case .design, .showBusiness, .fashion:
            return .init(
                analyticalReasoningAndProblemSolving: 1,
                creativityAndInsightfulThinking: 4,
                communicationAndNetworking: 2,
                persuasionAndNegotiation: 1,
                leadershipAndInfluence: 0,
                visionaryThinkingAndAmbition: 2,
                carefulnessAndAttentionToDetail: 2,
                tinkeringAndFingerPrecision: 1,
                spacialNavigationAndOrientation: 1,
                resilienceAndEndurance: 1,
                stressResistanceAndEmotionalRegulation: 1,
                outdoorAndWeatherResilience: 0,
                collaborationAndTeamwork: 2,
                timeManagementAndPlanning: 2,
                selfDisciplineAndPerseverance: 2,
                presentationAndStorytelling: 3
            )

        case .business, .administration, .law, .science:
            return .init(
                analyticalReasoningAndProblemSolving: 3,
                creativityAndInsightfulThinking: 1,
                communicationAndNetworking: 3,
                persuasionAndNegotiation: 1,
                leadershipAndInfluence: 2,
                visionaryThinkingAndAmbition: 1,
                carefulnessAndAttentionToDetail: 2,
                tinkeringAndFingerPrecision: 0,
                spacialNavigationAndOrientation: 0,
                resilienceAndEndurance: 1,
                stressResistanceAndEmotionalRegulation: 2,
                outdoorAndWeatherResilience: 0,
                collaborationAndTeamwork: 2,
                timeManagementAndPlanning: 2,
                selfDisciplineAndPerseverance: 2,
                presentationAndStorytelling: 2
            )

        case .logistics, .transportation:
            return .init(
                analyticalReasoningAndProblemSolving: 1,
                creativityAndInsightfulThinking: 0,
                communicationAndNetworking: 1,
                leadershipAndInfluence: 0,
                visionaryThinkingAndAmbition: 0,
                carefulnessAndAttentionToDetail: 2,
                tinkeringAndFingerPrecision: 0,
                spacialNavigationAndOrientation: 3,
                resilienceAndEndurance: 2,
                stressResistanceAndEmotionalRegulation: 1,
                outdoorAndWeatherResilience: 1,
                collaborationAndTeamwork: 1,
                timeManagementAndPlanning: 2,
                selfDisciplineAndPerseverance: 1,
                presentationAndStorytelling: 0
            )

        case .agriculture, .maritime:
            return .init(
                analyticalReasoningAndProblemSolving: 0,
                creativityAndInsightfulThinking: 0,
                communicationAndNetworking: 0,
                leadershipAndInfluence: 0,
                visionaryThinkingAndAmbition: 1,
                carefulnessAndAttentionToDetail: 1,
                tinkeringAndFingerPrecision: 1,
                spacialNavigationAndOrientation: 1,
                resilienceAndEndurance: 4,
                stressResistanceAndEmotionalRegulation: 1,
                outdoorAndWeatherResilience: 2,
                collaborationAndTeamwork: 1,
                timeManagementAndPlanning: 1,
                selfDisciplineAndPerseverance: 2,
                presentationAndStorytelling: 0
            )

        default:
            return .init(
                analyticalReasoningAndProblemSolving: 0,
                creativityAndInsightfulThinking: 0,
                communicationAndNetworking: 1,
                leadershipAndInfluence: 0,
                visionaryThinkingAndAmbition: 0,
                carefulnessAndAttentionToDetail: 1,
                tinkeringAndFingerPrecision: 0,
                spacialNavigationAndOrientation: 0,
                resilienceAndEndurance: 1,
                stressResistanceAndEmotionalRegulation: 1,
                outdoorAndWeatherResilience: 0,
                collaborationAndTeamwork: 1,
                timeManagementAndPlanning: 1,
                selfDisciplineAndPerseverance: 1,
                presentationAndStorytelling: 0
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
        case .gaming:      return [.technology, .design, .arts]
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
                    baseTitle: String, rung: Int, rungLabel: String) -> Job {
        let hard = credentials(forTitle: title, baseTitle: baseTitle)
        // A role can't sensibly demand a license or certification the player
        // couldn't have earned at its listed education level. Raise the floor to
        // the toughest education prerequisite of any credential the role
        // mandates, so the stated requirement reflects what the player must
        // genuinely already hold (e.g. a Paralegal needs the vocational-level
        // Paralegal Certificate, not just high school).
        let credentialEQF = hard.trainings.map(\.minEQF).max() ?? 0
        let effectiveEQF = max(minEQF, credentialEQF)
        // Degree fields only matter once a university degree is required; trades
        // and entry roles accept any background.
        let profiles = effectiveEQF >= 5
            ? (acceptedProfilesByBaseTitle[baseTitle] ?? defaultAcceptedProfiles(for: category))
            : nil
        let requirements = Job.Requirements(
            education: .init(minEQF: effectiveEQF, acceptedProfiles: profiles),
            softSkills: softSkillsByFullTitle[title]
                ?? softSkillsByBaseTitle[baseTitle]
                ?? defaultSoftSkills(for: category),
            hardSkills: hard,
            minYearsExperience: minYears ?? minYearsByTitle[title] ?? 0
        )
        return Job(id: title, category: category, income: income,
                   summary: summary, icon: icon, requirements: requirements,
                   targetCapital: targetCapital,
                   baseTitle: baseTitle, rung: rung, rungLabel: rungLabel)
    }

    /// A role with no ladder: its own base title, sitting at rung 0.
    static func job(from spec: JobSpec) -> Job {
        job(title: spec.title, category: spec.category, income: spec.income, icon: spec.icon,
            summary: spec.summary, minEQF: spec.minEQF, minYears: spec.minYears,
            targetCapital: spec.targetCapital,
            baseTitle: spec.title, rung: 0, rungLabel: "")
    }

    /// Every rung of a ladder, in declared order — the index is `Job.rung`.
    static func jobs(for ladder: LadderSpec) -> [Job] {
        ladder.rungs.enumerated().map { index, rung in
            job(title: ladder.title(for: rung), category: ladder.category, income: rung.income,
                icon: rung.icon ?? ladder.icon, summary: rung.summary, minEQF: rung.minEQF,
                minYears: rung.minYears, targetCapital: nil,
                baseTitle: ladder.name, rung: index, rungLabel: rung.label)
        }
    }

    // MARK: - Rows: standalone roles
    // EQF: 1=Primary, 2=Middle, 3=High School, 4=Vocational, 5=Bachelor, 6=Master, 7=Doctorate
    static let standaloneRoles: [JobSpec] = [
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
        .init(title: "Office Clerk", category: .administration, income: 33_000, icon: "🗂️", summary: "Performs general administrative duties.", minEQF: 3),
        .init(title: "Administrative Assistant", category: .administration, income: 40_000, icon: "📎", summary: "Supports a team with scheduling, mail, and records.", minEQF: 3),
        .init(title: "Receptionist", category: .administration, income: 33_000, icon: "📞", summary: "Greets visitors and manages front-desk tasks.", minEQF: 3),
        .init(title: "Bookkeeper", category: .administration, income: 44_000, icon: "🧾", summary: "Maintains financial transaction records.", minEQF: 3),
        .init(title: "Payroll Specialist", category: .administration, income: 52_000, icon: "💵", summary: "Processes payroll and employee benefits.", minEQF: 4),
        .init(title: "Recruiter", category: .administration, income: 58_000, icon: "🔎", summary: "Finds and screens candidates for roles.", minEQF: 3),
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
        .init(title: "Air Traffic Controller", category: .transportation, income: 130_000, icon: "🗼", summary: "Directs aircraft safely through airspace and runways.", minEQF: 4),
        .init(title: "First Officer", category: .transportation, income: 95_000, icon: "🧑‍✈️", summary: "Co-pilots commercial flights alongside the captain.", minEQF: 5),
        .init(title: "Pilot", category: .transportation, income: 155_000, icon: "✈️", summary: "Operates aircraft for passenger or cargo flights.", minEQF: 5),
        .init(title: "Airline Captain", category: .transportation, income: 205_000, icon: "👨‍✈️", summary: "Commands the flight deck of commercial airliners.", minEQF: 5),
        // Logistics — planning and management of the supply chain
        .init(title: "Dispatcher", category: .logistics, income: 46_000, icon: "📡", summary: "Routes drivers and crews and tracks deliveries.", minEQF: 3),
        .init(title: "Logistics Coordinator", category: .logistics, income: 52_000, icon: "🗒️", summary: "Schedules shipments and coordinates carriers.", minEQF: 4),
        .init(title: "Warehouse Manager", category: .logistics, income: 66_000, icon: "🏬", summary: "Runs a warehouse's staff, inventory, and throughput.", minEQF: 4),
        .init(title: "Fleet Manager", category: .logistics, income: 74_000, icon: "🚛", summary: "Manages a fleet of vehicles, maintenance, and routing.", minEQF: 5),
        .init(title: "Supply Chain Manager", category: .logistics, income: 98_000, icon: "🔗", summary: "Optimizes sourcing, inventory, and distribution end-to-end.", minEQF: 5),
        .init(title: "Judge", category: .law, income: 155_000, icon: "👨‍⚖️", summary: "Presides over court proceedings and rulings.", minEQF: 7),
        .init(title: "Security Guard", category: .publicServices, income: 32_000, icon: "🛡️", summary: "Protects property and ensures public safety.", minEQF: 3),
        // Engineering
        .init(title: "Architect", category: .engineering, income: 88_000, icon: "📐", summary: "Designs building plans and structures.", minEQF: 5),
        .init(title: "Chemical Engineer", category: .engineering, income: 82_000, icon: "🧪", summary: "Applies chemistry to industrial processes.", minEQF: 5),
        .init(title: "Aerospace Engineer", category: .engineering, income: 115_000, icon: "🚀", summary: "Designs aircraft, spacecraft, and propulsion systems.", minEQF: 5),
        .init(title: "Fashion Designer", category: .design, income: 55_000, icon: "👗", summary: "Designs clothing collections and sells to buyers.", minEQF: 4),
        // Media / Writing / Broadcast
        .init(title: "Content Writer", category: .showBusiness, income: 44_000, icon: "✍️", summary: "Creates written content for various channels.", minEQF: 4),
        .init(title: "Journalist", category: .showBusiness, income: 48_000, icon: "📰", summary: "Reports news and stories for media outlets.", minEQF: 5),
        .init(title: "Photographer", category: .showBusiness, income: 40_000, icon: "📷", summary: "Takes photos for commercial and personal use.", minEQF: 3),
        .init(title: "TV Presenter", category: .showBusiness, income: 70_000, icon: "📺", summary: "Presents television programs and live segments.", minEQF: 5),
        .init(title: "News Anchor", category: .showBusiness, income: 95_000, icon: "🎙️", summary: "Anchors television news broadcasts.", minEQF: 5),
        .init(title: "Video Editor", category: .showBusiness, income: 55_000, icon: "🎬", summary: "Cuts and assembles footage for film, TV, and online.", minEQF: 4),
        .init(title: "Social Media Manager", category: .showBusiness, income: 58_000, icon: "📱", summary: "Runs brand presence and campaigns across social platforms.", minEQF: 5),
        // Sports / Fitness
        .init(title: "Personal Trainer", category: .showBusiness, income: 40_000, icon: "🏋️", summary: "Coaches clients one-on-one toward their fitness goals.", minEQF: 3),
        .init(title: "Fitness Instructor", category: .showBusiness, income: 34_000, icon: "🤸", summary: "Leads group exercise and gym classes.", minEQF: 2),
        // Agriculture
        .init(title: "Farmhand", category: .agriculture, income: 28_000, icon: "🧑‍🌾", summary: "Plants, harvests, and tends crops and livestock.", minEQF: 1),
        .init(title: "Farmer", category: .agriculture, income: 32_000, icon: "🚜", summary: "Operates agricultural production and livestock.", minEQF: 2),
        // Arts / Creative
        .init(title: "Painter (Artist)", category: .showBusiness, income: 32_000, icon: "🎨", summary: "Creates original artwork for sale or exhibition.", minEQF: 1),
        .init(title: "Musician", category: .showBusiness, income: 34_000, icon: "🎵", summary: "Performs or composes music professionally.", minEQF: 1),
        .init(title: "Actor", category: .showBusiness, income: 38_000, icon: "🎭", summary: "Performs in theater, film, or television.", minEQF: 1),
        .init(title: "Dancer", category: .showBusiness, income: 35_000, icon: "💃", summary: "Performs choreographed routines on stage and screen.", minEQF: 1),
        .init(title: "Animator", category: .design, income: 65_000, icon: "🎞️", summary: "Creates 2D/3D animation for studios and clients.", minEQF: 4),
        .init(title: "Interior Designer", category: .design, income: 60_000, icon: "🛋️", summary: "Designs and styles indoor spaces for clients.", minEQF: 4),
        // Gaming — the studios that make video games (art, design, engineering)
        .init(title: "Game QA Tester", category: .gaming, income: 45_000, icon: "🔍", summary: "Hunts bugs and verifies gameplay before release.", minEQF: 3),
        .init(title: "3D Modeler", category: .gaming, income: 58_000, icon: "🧊", summary: "Sculpts characters, props, and environments as 3D assets.", minEQF: 4),
        .init(title: "Game Animator", category: .gaming, income: 62_000, icon: "🎞️", summary: "Brings characters and creatures to life in motion.", minEQF: 4),
        .init(title: "Level Designer", category: .gaming, income: 68_000, icon: "🗺️", summary: "Builds and balances the game's levels and pacing.", minEQF: 4),
        .init(title: "Narrative Designer", category: .gaming, income: 72_000, icon: "✍️", summary: "Writes the story, characters, and branching dialogue.", minEQF: 5),
        .init(title: "Technical Artist", category: .gaming, income: 92_000, icon: "🛠️", summary: "Bridges art and code — shaders, tools, and pipelines.", minEQF: 5),
        .init(title: "Game Producer", category: .gaming, income: 105_000, icon: "📋", summary: "Coordinates team, schedule, and scope to ship the game.", minEQF: 5),

        // Capstone roles: senior seats that top out a track under their own
        // name rather than as a rung of a ladder.
        .init(title: "Marketing Director", category: .business, income: 145_000, icon: "📣", summary: "Leads the marketing function and brand strategy.", minEQF: 5, minYears: 8),
        .init(title: "Managing Partner", category: .law, income: 220_000, icon: "⚖️", summary: "Equity partner driving client relationships and firm strategy — the top of the law track.", minEQF: 7, minYears: 8),
        .init(title: "Nurse Practitioner", category: .health, income: 125_000, icon: "🥼", summary: "Advanced-practice nurse who diagnoses, treats, and prescribes with autonomy.", minEQF: 6, minYears: 2),
        .init(title: "Art Director", category: .showBusiness, income: 100_000, icon: "🖼️", summary: "Sets the visual direction for campaigns, films, or publications.", minEQF: 5, minYears: 8),
        .init(title: "Editor-in-Chief", category: .showBusiness, income: 135_000, icon: "🗞️", summary: "Leads a publication's editorial vision and newsroom.", minEQF: 5, minYears: 10),
        .init(title: "Art Director (Games)", category: .gaming, income: 145_000, icon: "🖌️", summary: "Directs the art team and defines the game's whole look.", minEQF: 5, minYears: 8),
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
        .init(name: "3D Artist", category: .gaming, icon: "🎨", rungs: [
            .init(label: "", income: 64_000, summary: "Creates textured, lit 3D art for games.", minEQF: 4),
            // Gaming — art, design, and engineering ladders inside a studio
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
        .init(name: "Game Designer", category: .gaming, icon: "🎮", rungs: [
            .init(label: "", income: 78_000, summary: "Designs mechanics, systems, and the player experience.", minEQF: 5),
            .init(label: "Senior", income: 115_000, summary: "Owns major game systems and mentors designers.", minEQF: 5, minYears: 5),
            .init(label: "Lead", income: 150_000, summary: "Sets the design vision for the entire title.", minEQF: 5, minYears: 9),
        ]),
        .init(name: "Gameplay Programmer", category: .gaming, icon: "💻", rungs: [
            .init(label: "", income: 98_000, summary: "Codes game systems, mechanics, and engine features.", minEQF: 5),
            .init(label: "Senior", income: 150_000, summary: "Owns complex gameplay systems and mentors engineers.", minEQF: 5, minYears: 5),
            .init(label: "Lead", income: 190_000, summary: "Leads the gameplay engineering team and its architecture.", minEQF: 5, minYears: 9),
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
        .init(title: "Indie Game Studio", category: .gaming, income: 85_000, icon: "🎮", summary: "Bootstrap a small studio and ship an original game to players.", minYears: 3, targetCapital: 55_000),
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

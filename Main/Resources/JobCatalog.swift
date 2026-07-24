import Foundation

enum JobCatalog {
    /// Builds the full job database. Salaries are the present-day published
    /// figures; a small random variance is applied when each `Job` is constructed.
    static func allJobs() -> [Job] {

        // MARK: - Detailed jobs (hand-tuned soft skills)

        let rn = Job(
            id: "Registered Nurse",
            category: .health,
            income: 81_000,
            summary: "Provides patient care, administers medication, and coordinates with medical teams.",
            icon: "🩺",
            requirements: .init(
                education: .init(minEQF: 5, acceptedProfiles: [.health, .science]),
                softSkills: .init(
                    analyticalReasoningAndProblemSolving: 2,
                    creativityAndInsightfulThinking: 0,
                    communicationAndNetworking: 3,
                    leadershipAndInfluence: 1,
                    visionaryThinkingAndAmbition: 0,
                    carefulnessAndAttentionToDetail: 4,
                    tinkeringAndFingerPrecision: 2,
                    spacialNavigationAndOrientation: 0,
                    resilienceAndEndurance: 3,
                    stressResistanceAndEmotionalRegulation: 3,
                    empathyAndInterpersonalCare: 3,
                    outdoorAndWeatherResilience: 0,
                    collaborationAndTeamwork: 3,
                    timeManagementAndPlanning: 2,
                    selfDisciplineAndPerseverance: 2,
                    presentationAndStorytelling: 1
                ),
                hardSkills: .init(trainings: [.nurse])
            )
        )

        let lightDriver = Job(
            id: "Light Truck Delivery Driver",
            category: .transportation,
            income: 42_000,
            summary: "Delivers goods locally using vans or small trucks.",
            icon: "🚐",
            requirements: .init(
                education: .init(minEQF: 3, acceptedProfiles: nil),
                softSkills: .init(
                    analyticalReasoningAndProblemSolving: 0,
                    creativityAndInsightfulThinking: 0,
                    communicationAndNetworking: 1,
                    leadershipAndInfluence: 0,
                    visionaryThinkingAndAmbition: 0,
                    carefulnessAndAttentionToDetail: 2,
                    tinkeringAndFingerPrecision: 0,
                    spacialNavigationAndOrientation: 2,
                    resilienceAndEndurance: 2,
                    stressResistanceAndEmotionalRegulation: 1,
                    outdoorAndWeatherResilience: 1,
                    collaborationAndTeamwork: 1,
                    timeManagementAndPlanning: 2,
                    selfDisciplineAndPerseverance: 1,
                    presentationAndStorytelling: 0
                ),
                hardSkills: .init(trainings: [.drivers])
            )
        )

        // MARK: - Helpers

        // Realistic soft skill defaults per job category.
        // Every category now has non-zero values for stress, collaboration,
        // time management, self-discipline and presentation where they apply.
        func defaultSoft(for category: JobCategory) -> SoftSkills {
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

        // Per-title soft-skill overrides, keyed by base title (so seniority
        // variants inherit via `Job.baseTitle`). These refine roles where the
        // broad category default is clearly wrong — e.g. a Sales Manager needs
        // persuasion an Accountant doesn't, and a Counselor needs empathy a
        // Bookkeeper doesn't. Titles not listed fall back to `defaultSoft`.
        let perTitleSoft: [String: SoftSkills] = [
            // Sales / persuasion
            "Retail Salesperson":             .init(communicationAndNetworking: 3, persuasionAndNegotiation: 3, carefulnessAndAttentionToDetail: 1, stressResistanceAndEmotionalRegulation: 1, empathyAndInterpersonalCare: 2, collaborationAndTeamwork: 1, timeManagementAndPlanning: 1, presentationAndStorytelling: 1),
            "Sales Manager":                  .init(analyticalReasoningAndProblemSolving: 1, communicationAndNetworking: 3, persuasionAndNegotiation: 4, leadershipAndInfluence: 3, visionaryThinkingAndAmbition: 1, stressResistanceAndEmotionalRegulation: 2, empathyAndInterpersonalCare: 1, collaborationAndTeamwork: 2, timeManagementAndPlanning: 2, presentationAndStorytelling: 2),
            "Marketing Specialist":           .init(analyticalReasoningAndProblemSolving: 1, creativityAndInsightfulThinking: 3, communicationAndNetworking: 3, persuasionAndNegotiation: 3, visionaryThinkingAndAmbition: 1, timeManagementAndPlanning: 2, presentationAndStorytelling: 3),
            "Recruiter":                      .init(communicationAndNetworking: 3, persuasionAndNegotiation: 3, carefulnessAndAttentionToDetail: 1, empathyAndInterpersonalCare: 2, timeManagementAndPlanning: 2, presentationAndStorytelling: 1),
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

        // Resolves a title's soft-skill requirements: per-title override if one
        // exists, otherwise the broad category default.
        func softSkills(for title: String, category: JobCategory) -> SoftSkills {
            perTitleSoft[Job.baseTitle(of: title)] ?? defaultSoft(for: category)
        }

        // Hard requirements that are intrinsic to the role — legally required
        // licenses or industry-standard certs the field expects.
        func defaultHard(for title: String, category: JobCategory) -> HardSkills {
            // Senior-grade credentials matched on the *full* title so they attach
            // only to the senior/standalone rung, not a ladder's entry rung (a
            // junior analyst shouldn't need the CFA). In regulated fields these
            // certs hard-gate hiring; elsewhere they're a helpful signal only.
            switch title {
            case "Accountant", "Senior Accountant":
                return HardSkills(trainings: [.cpa])
            // Trade apprentices work *toward* the license, so the entry rung
            // carries none — even though the journeyman base role (Electrician /
            // Plumber, same base title) requires it.
            case "Apprentice Electrician", "Apprentice Plumber", "Apprentice Carpenter":
                return HardSkills()
            // Promotions that demand a *senior* credential on top of the base
            // role's license: master trade licenses and the airline transport
            // pilot certificate. Listed on the full title so only the top rung
            // is gated, not the journeyman/first-officer rungs below it.
            case "Master Electrician":
                return HardSkills(trainings: [.electrician, .masterElectrician])
            case "Master Plumber":
                return HardSkills(trainings: [.plumber, .masterPlumber])
            case "Airline Captain":
                return HardSkills(trainings: [.commercialPilot, .airlineTransportPilot])
            // The PE license is what lets a senior engineer stamp and sign off on
            // designs — juniors work under a PE as engineers-in-training, so the
            // license gates the senior rung, not the entry rungs.
            case "Senior Civil Engineer", "Senior Mechanical Engineer", "Senior Electrical Engineer":
                return HardSkills(trainings: [.professionalEngineer])
            // Attending physicians and medical leadership hold the medical license
            // and are board-certified in their specialty after residency.
            case "Senior Physician", "Chief Medical Officer":
                return HardSkills(trainings: [.medicalLicense, .boardCertified])
            default:
                break
            }

            switch Job.baseTitle(of: title) {
            // Drivers / transport
            case "Light Truck Delivery Driver", "Taxi Driver":
                return HardSkills(trainings: [.drivers])
            case "Truck Driver", "Bus Driver":
                return HardSkills(trainings: [.cdl])
            case "Pilot", "First Officer", "Airline Captain":
                return HardSkills(trainings: [.commercialPilot])
            case "Air Traffic Controller":
                return HardSkills(trainings: [.atcCertification])

            // Trades — licensed by law in most jurisdictions
            case "Electrician":
                return HardSkills(trainings: [.electrician])
            case "Plumber":
                return HardSkills(trainings: [.plumber])
            case "Architect":
                return HardSkills(trainings: [.architect])

            // Health — licenses + entry-level certs. The nursing ladder climbs
            // by credential: aide (CNA) → practical nurse (LPN) → registered
            // nurse (RN) → nurse practitioner (RN + NP).
            case "Registered Nurse":
                return HardSkills(trainings: [.nurse])
            case "Nurse Practitioner":
                return HardSkills(trainings: [.nurse, .np])
            case "Licensed Practical Nurse":
                return HardSkills(trainings: [.lpn])
            case "Physician", "Surgeon", "Anesthesiologist":
                return HardSkills(trainings: [.medicalLicense])
            case "Dentist":
                return HardSkills(trainings: [.dentalLicense])
            case "Pharmacist":
                return HardSkills(trainings: [.pharmacistLicense])
            case "Veterinarian":
                return HardSkills(trainings: [.veterinaryLicense])
            case "Paramedic":
                return HardSkills(trainings: [.emt])
            case "Dental Assistant":
                return HardSkills(trainings: [.dentalAssistant])
            case "Nursing Aide":
                return HardSkills(trainings: [.cna])

            // Law / public services
            case "Lawyer", "Judge", "Managing Partner":
                return HardSkills(trainings: [.bar])
            case "Firefighter", "Senior Firefighter", "Lead Firefighter":
                return HardSkills(trainings: [.emt])
            case "Security Guard":
                return HardSkills(trainings: [.securityGuard])

            // Service / hospitality
            case "Hairdresser/Barber", "Beautician/Cosmetologist":
                return HardSkills(trainings: [.cosmetology])
            case "Flight Attendant":
                return HardSkills(trainings: [.flightAttendantCert])

            // Education — teachers are hired on a teaching certificate (a helpful
            // signal in this non-regulated field, not a hard gate).
            case "Teacher", "Senior Teacher", "Lead Teacher":
                return HardSkills(trainings: [.teachingCertificate])

            // Agriculture — pesticides require a state applicator license
            case "Farmer":
                return HardSkills(trainings: [.pesticideApplicator])

            default:
                return HardSkills()
            }
        }

        // Years of prior industry experience an employer expects before
        // even considering an applicant. Senior / management / regulated
        // roles set this above zero; entry-level jobs leave it at the
        // default of 0.
        func defaultExperience(for title: String) -> Int {
            switch title {
            case "Hotel Manager", "Sales Manager", "Project Manager",
                 "Event Planner", "Human Resources Specialist":
                return 3
            case "Business Analyst", "Financial Analyst", "Marketing Specialist":
                return 2
            // Security is a second-career field — hired out of IT/networking, not
            // straight from school.
            case "Cybersecurity Analyst":
                return 2
            // Anchors are promoted after years of on-air reporting.
            case "News Anchor":
                return 3
            case "Judge":
                return 10
            // A newly barred lawyer is hired as an associate straight away; the
            // JD + Bar are the real barrier, not prior experience. (Senior Lawyer
            // and Managing Partner carry the experience gates.)
            case "Lawyer":
                return 0
            // Physicians need residency and psychologists need supervised hours
            // before practising, so both keep an experience floor — but dentists
            // and veterinarians practise as soon as they're degreed and licensed.
            case "Physician", "Psychologist":
                return 2
            // First Officer is the entry airline-pilot seat (hired on the
            // commercial licence + hours); a full "Pilot" reads as captain-track.
            case "First Officer":
                return 1
            case "Pilot":
                return 3
            case "Airline Captain":
                return 8
            case "Research Scientist":
                return 3
            case "Architect":
                return 4
            case "Aerospace Engineer":
                return 2
            case "Surgeon", "Anesthesiologist":
                return 5
            case "Management Consultant", "Investment Banker", "Data Scientist":
                return 2
            case "Cloud Architect":
                return 5
            case "Supply Chain Manager", "Fleet Manager":
                return 4
            case "Warehouse Manager", "Office Manager":
                return 3
            default:
                return 0
            }
        }

        // Degree fields a role's industry accepts. Only applied to jobs that
        // require a university degree (EQF ≥ 5); lower-EQF jobs accept any
        // background (nil), since trades and entry roles aren't field-specific.
        func defaultAcceptedProfiles(for category: JobCategory) -> [TertiaryProfile]? {
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

        // Per-title accepted degree fields, overriding the category default where
        // a role draws from a discipline the category map doesn't capture — e.g.
        // an architecture degree reads as design or arts as readily as engineering,
        // so an Architect shouldn't be gated to engineering/science/tech degrees.
        let perTitleProfiles: [String: [TertiaryProfile]] = [
            "Architect": [.engineering, .design, .arts],
        ]

        func fullJob(id: String, category: JobCategory, income: Int, icon: String, summary: String, minEQF: Int, minYears: Int? = nil, targetCapital: Int? = nil) -> Job {
            let soft = softSkills(for: id, category: category)
            let hard = defaultHard(for: id, category: category)
            // A role can't sensibly demand a license or certification the player
            // couldn't have earned at its listed education level. Raise the floor
            // to the toughest education prerequisite of any credential the role
            // mandates, so the stated requirement reflects what the player must
            // genuinely already hold (e.g. a Paralegal needs the vocational-level
            // Paralegal Certificate, not just high school).
            let credentialEQF = hard.trainings.map(\.minEQF).max() ?? 0
            let effectiveEQF = max(minEQF, credentialEQF)
            let profiles = effectiveEQF >= 5 ? (perTitleProfiles[Job.baseTitle(of: id)] ?? defaultAcceptedProfiles(for: category)) : nil
            let edu = Job.Requirements.Education(minEQF: effectiveEQF, acceptedProfiles: profiles)
            let req = Job.Requirements(
                education: edu,
                softSkills: soft,
                hardSkills: hard,
                minYearsExperience: minYears ?? defaultExperience(for: id)
            )
            return Job(id: id, category: category, income: income, summary: summary, icon: icon, requirements: req, targetCapital: targetCapital)
        }

        // MARK: - Job titles
        // (id, category, income, icon, summary, minEQF)
        // EQF: 1=Primary, 2=Middle, 3=High School, 4=Vocational, 5=Bachelor, 6=Master, 7=Doctorate
        let titles: [(String, JobCategory, Int, String, String, Int)] = [
            // Retail
            ("Retail Salesperson",              .retail,       30_000, "🛍️", "Sells products directly to customers.",                           3),
            ("Cashier",                         .retail,       26_000, "💳", "Handles customer payments and transactions.",                      2),

            // Hospitality — restaurants, hotels, and events
            ("Waiter/Waitress",                 .hospitality,  24_000, "🍽️", "Serves food and beverages to customers.",                          2),
            ("Food Preparation Worker",         .hospitality,  25_000, "🍳", "Prepares ingredients and supports kitchen staff.",                  2),
            ("Dishwasher",                      .hospitality,  23_000, "🧽", "Cleans dishes and kitchenware in food-service settings.",          1),
            ("Fast Food Worker",                .hospitality,  24_000, "🍔", "Takes orders and prepares food at quick-service counters.",        1),
            ("Housekeeper",                     .hospitality,  27_000, "🧺", "Cleans and tidies rooms in hotels and facilities.",                1),
            ("Janitor/Cleaner",                 .hospitality,  34_000, "🧹", "Maintains cleanliness of buildings and facilities.",               1),
            ("Flight Attendant",                .hospitality,  48_000, "🛫", "Ensures passenger safety and comfort.",                            3),
            ("Baker",                           .hospitality,  32_000, "🥐", "Bakes bread, pastries, and other goods.",                          3),
            ("Chef",                            .hospitality,  52_000, "👨‍🍳", "Prepares meals in restaurants or institutions; entry rung of the kitchen ladder.", 3),
            ("Hotel Manager",                   .hospitality,  72_000, "🏨", "Oversees hotel operations and staff.",                             5),
            ("Event Planner",                   .hospitality,  55_000, "🎉", "Organizes events and logistics.",                                  5),

            // Personal Services — personal and general services
            ("Hairdresser/Barber",              .service,      32_000, "💇", "Cuts and styles hair for clients.",                                 4),
            ("Beautician/Cosmetologist",        .service,      30_000, "💄", "Provides beauty treatments and services.",                         4),

            // Education — two tracks: an accessible Tutor ladder and a
            // degree-gated Teacher ladder (Senior/Lead rungs in the seniority
            // ladders below).
            ("Tutor",                           .education,    34_000, "📖", "Coaches students one-on-one in specific subjects.",                3),
            ("Teacher",                         .education,    48_000, "🏫", "Teaches a class of students their core subjects.",                 5),

            // Health
            ("Physician",                       .health,      220_000, "🩺", "Diagnoses and treats illnesses.",                                  7),
            ("Surgeon",                         .health,      350_000, "🔪", "Performs operations to treat injuries and disease.",               7),
            ("Anesthesiologist",                .health,      330_000, "💉", "Manages anesthesia and patient vitals during surgery.",            7),
            ("Pharmacist",                      .health,      132_000, "💊", "Dispenses medications and advises patients.",                      7),
            ("Medical Assistant",               .health,       37_000, "🩺", "Supports clinical staff with patient care.",                       3),
            ("Nursing Aide",                    .health,       30_000, "🛏️", "Assists patients with daily living tasks.",                        3),
            ("Licensed Practical Nurse",        .health,       55_000, "💉", "Gives basic nursing care under an RN or physician.",               3),
            ("Dental Assistant",                .health,       38_000, "🦷", "Supports dental professionals during procedures.",                  3),
            ("Dentist",                         .health,      160_000, "🦷", "Diagnoses and treats dental conditions.",                          7),
            ("Physiotherapist",                 .health,       65_000, "🤸", "Provides rehabilitation and physical therapy.",                    7),
            ("Psychologist",                    .health,       90_000, "🧠", "Studies behavior and provides therapy.",                           7),
            ("Paramedic",                       .health,       52_000, "🚑", "Provides emergency medical care.",                                 4),
            ("Veterinarian",                    .health,      105_000, "🐾", "Cares for animal health and treatments.",                          7),

            // Social
            ("Social Worker",                   .publicServices,48_000, "🤝", "Supports vulnerable individuals and families.",                    5),

            // Technology
            ("Software Engineer",               .technology,  115_000, "💻", "Designs and implements software systems.",                         5),
            ("Data Analyst",                    .technology,   85_000, "📊", "Analyzes data to inform decisions.",                               5),
            ("Systems Administrator",           .technology,   80_000, "🖧",  "Maintains IT infrastructure.",                                     4),
            ("IT Support Specialist",           .technology,   52_000, "🛠️", "Provides technical help desk support.",                            3),
            ("Software Tester/QA",              .technology,   68_000, "🔍", "Tests software for defects and quality.",                          3),
            ("Cybersecurity Analyst",           .technology,  105_000, "🔐", "Defends systems and networks against attacks.",                    5),
            ("Data Scientist",                  .technology,  130_000, "📈", "Builds models and extracts insight from large datasets.",          5),
            ("Cloud Architect",                 .technology,  160_000, "☁️", "Designs and runs large-scale cloud infrastructure.",               5),

            // Business / Finance
            ("Financial Analyst",               .business,     95_000, "💹", "Analyzes financial performance and forecasts.",                    5),
            ("Sales Manager",                   .business,     98_000, "📈", "Leads sales teams and strategies.",                                5),
            ("Marketing Specialist",            .business,     64_000, "📣", "Creates and runs marketing campaigns.",                            5),
            ("Project Manager",                 .business,     98_000, "📋", "Plans and oversees projects to completion.",                       5),
            ("Business Analyst",                .business,     80_000, "📈", "Analyzes business needs and recommends solutions.",                 5),
            ("Management Consultant",           .business,    140_000, "🧠", "Advises companies on strategy and operations.",                    5),
            ("Investment Banker",               .business,    175_000, "🏦", "Structures deals, raises capital, and advises on M&A.",            5),
            ("Translator/Interpreter",          .business,     50_000, "🌐", "Converts text between languages and provides live interpretation.", 5),

            // Administration — back-office functions common to every business
            ("Office Clerk",                    .administration, 33_000, "🗂️", "Performs general administrative duties.",                        3),
            ("Administrative Assistant",        .administration, 40_000, "📎", "Supports a team with scheduling, mail, and records.",            3),
            ("Receptionist",                    .administration, 33_000, "📞", "Greets visitors and manages front-desk tasks.",                  3),
            ("Bookkeeper",                      .administration, 44_000, "🧾", "Maintains financial transaction records.",                       3),
            ("Payroll Specialist",              .administration, 52_000, "💵", "Processes payroll and employee benefits.",                       4),
            ("Recruiter",                       .administration, 58_000, "🔎", "Finds and screens candidates for roles.",                        3),
            ("Human Resources Specialist",      .administration, 62_000, "🧑‍💼", "Manages hiring and employee relations.",                      5),
            ("Office Manager",                  .administration, 64_000, "🗄️", "Runs day-to-day office operations and admin staff.",             4),
            ("Accountant",                      .administration, 72_000, "📒", "Prepares financial records and statements.",                     5),

            // Construction / Trades
            ("Construction Laborer",            .construction, 36_000, "🏗️", "Performs physical tasks on construction sites.",                   2),
            ("Roofer",                          .construction, 45_000, "🏠", "Installs and repairs roofs in all weather.",                        1),
            ("Electrician",                     .construction, 62_000, "🔌", "Installs and repairs electrical systems.",                         4),
            ("Plumber",                         .construction, 60_000, "🚰", "Installs and repairs plumbing systems.",                           4),
            ("Carpenter",                       .construction, 52_000, "🪚", "Builds and repairs wooden structures.",                            4),
            ("Painter (Construction)",          .construction, 36_000, "🎨", "Paints buildings and interior spaces.",                            2),
            ("HVAC Technician",                 .construction, 55_000, "🌡️", "Installs and services heating and cooling systems.",               4),

            // Manufacturing
            ("Factory Worker",                  .manufacturing, 34_000, "🏭", "Operates production-line equipment and assembles goods.",          1),
            ("Assembler",                       .manufacturing, 36_000, "🔩", "Assembles parts and products to spec.",                            1),
            ("Machine Operator",                .manufacturing, 42_000, "⚙️", "Runs and monitors manufacturing machinery.",                       2),
            ("Welder",                          .manufacturing, 47_000, "🔥", "Joins metal parts for fabrication and repair.",                    3),
            ("Machinist",                       .manufacturing, 50_000, "🛠️", "Machines precision metal parts from blueprints.",                  3),
            ("Quality Control Inspector",       .manufacturing, 46_000, "🔎", "Checks products against quality standards.",                       3),

            // Transportation — vehicle operation, material handling, and maintenance
            ("Truck Driver",                    .transportation, 50_000, "🚚", "Transports goods over long distances.",                          3),
            ("Bus Driver",                      .transportation, 42_000, "🚌", "Operates passenger buses on scheduled routes.",                    3),
            ("Taxi Driver",                     .transportation, 32_000, "🚕", "Provides on-demand passenger transport.",                          2),
            ("Delivery Courier",                .transportation, 30_000, "🛵", "Delivers parcels and food by bike, scooter, or on foot.",          1),
            ("Mover",                           .transportation, 32_000, "📦", "Loads, hauls, and unloads household and office goods.",            1),
            ("Warehouse Worker",                .transportation, 34_000, "🪜", "Picks, packs, and moves warehouse inventory.",                     2),
            ("Forklift Operator",               .transportation, 36_000, "🏗️", "Operates forklifts to move goods.",                               2),
            ("Mechanic",                        .transportation, 52_000, "🔧", "Repairs vehicles and machinery.",                                  4),
            ("Aircraft Maintenance Technician", .transportation, 68_000, "🛩️", "Inspects, services, and repairs aircraft.",                       4),
            ("Air Traffic Controller",          .transportation, 130_000, "🗼", "Directs aircraft safely through airspace and runways.",          4),
            ("First Officer",                   .transportation, 95_000, "🧑‍✈️", "Co-pilots commercial flights alongside the captain.",          5),
            ("Pilot",                           .transportation, 155_000, "✈️", "Operates aircraft for passenger or cargo flights.",              5),
            ("Airline Captain",                 .transportation, 205_000, "👨‍✈️", "Commands the flight deck of commercial airliners.",            5),

            // Logistics — planning and management of the supply chain
            ("Dispatcher",                      .logistics,    46_000, "📡", "Routes drivers and crews and tracks deliveries.",                   3),
            ("Logistics Coordinator",           .logistics,    52_000, "🗒️", "Schedules shipments and coordinates carriers.",                    4),
            ("Warehouse Manager",               .logistics,    66_000, "🏬", "Runs a warehouse's staff, inventory, and throughput.",             4),
            ("Fleet Manager",                   .logistics,    74_000, "🚛", "Manages a fleet of vehicles, maintenance, and routing.",           5),
            ("Supply Chain Manager",            .logistics,    98_000, "🔗", "Optimizes sourcing, inventory, and distribution end-to-end.",      5),

            // Law / Public Services
            ("Lawyer",                          .law,         125_000, "⚖️", "Provides legal advice and represents clients.",                    7),
            ("Paralegal",                       .law,          48_000, "📑", "Assists lawyers with research and documentation.",                  4),
            ("Judge",                           .law,         155_000, "👨‍⚖️", "Presides over court proceedings and rulings.",                   7),
            // Public Services — three tracks, each climbed by seniority:
            // Law Enforcement (Police Officer), Firefighting/Rescue (Firefighter),
            // and Municipal Services (Municipal Worker). Entry rungs here; the
            // Senior/Lead rungs live in the seniority ladders below.
            ("Police Officer",                  .publicServices,67_000,"👮", "Enforces laws and protects the public on patrol.",                3),
            ("Firefighter",                     .publicServices,57_000,"🔥", "Responds to fires, accidents, and rescue emergencies.",            3),
            ("Municipal Worker",                .publicServices,40_000,"🧹", "Keeps the city running — sanitation, parks, roads, and facilities.", 2),
            ("Security Guard",                  .publicServices,32_000,"🛡️", "Protects property and ensures public safety.",                     3),

            // Science
            // Science — two tracks: a Lab Technician trade ladder and a
            // doctorate-gated Research Scientist ladder (Senior/Lead/Principal
            // rungs live in the seniority ladders below).
            ("Lab Technician",                  .science,      42_000, "🧪", "Runs lab tests, preps samples, and records results.",              4),
            ("Research Scientist",              .science,      90_000, "🔬", "Designs and runs experiments to answer scientific questions.",     7),

            // Engineering
            ("Architect",                       .engineering,  88_000, "📐", "Designs building plans and structures.",                           5),
            ("Civil Engineer",                  .engineering,  88_000, "🛣️", "Designs infrastructure and public works.",                         5),
            ("Mechanical Engineer",             .engineering,  84_000, "⚙️", "Designs mechanical systems and machinery.",                        5),
            ("Electrical Engineer",             .engineering,  86_000, "🔋", "Designs electrical systems and circuits.",                         5),
            ("Chemical Engineer",               .engineering,  82_000, "🧪", "Applies chemistry to industrial processes.",                       5),
            ("Aerospace Engineer",              .engineering, 115_000, "🚀", "Designs aircraft, spacecraft, and propulsion systems.",            5),

            // Design
            ("Graphic Artist",                  .design,       50_000, "🎨", "Creates visual artwork for media.",                                4),
            ("UX/UI Designer",                  .design,       82_000, "🖥️", "Designs user interfaces and experiences.",                         5),
            ("Fashion Designer",                .design,       55_000, "👗", "Designs clothing collections and sells to buyers.",                4),

            // Media / Writing / Broadcast
            ("Content Writer",                  .showBusiness,        44_000, "✍️", "Creates written content for various channels.",                    4),
            ("Journalist",                      .showBusiness,        48_000, "📰", "Reports news and stories for media outlets.",                      5),
            ("Photographer",                    .showBusiness,        40_000, "📷", "Takes photos for commercial and personal use.",                    3),
            ("TV Presenter",                    .showBusiness,        70_000, "📺", "Presents television programs and live segments.",                  5),
            ("News Anchor",                     .showBusiness,        95_000, "🎙️", "Anchors television news broadcasts.",                              5),
            ("Video Editor",                    .showBusiness,        55_000, "🎬", "Cuts and assembles footage for film, TV, and online.",             4),
            ("Social Media Manager",            .showBusiness,        58_000, "📱", "Runs brand presence and campaigns across social platforms.",       5),

            // Sports / Fitness
            ("Personal Trainer",                .showBusiness,       40_000, "🏋️", "Coaches clients one-on-one toward their fitness goals.",            3),
            ("Fitness Instructor",              .showBusiness,       34_000, "🤸", "Leads group exercise and gym classes.",                            2),

            // Agriculture
            ("Farmhand",                        .agriculture,  28_000, "🧑‍🌾", "Plants, harvests, and tends crops and livestock.",               1),
            ("Farmer",                          .agriculture,  32_000, "🚜", "Operates agricultural production and livestock.",                  2),

            // Arts / Creative
            ("Painter (Artist)",                .showBusiness,         32_000, "🎨", "Creates original artwork for sale or exhibition.",                 1),
            ("Musician",                        .showBusiness,         34_000, "🎵", "Performs or composes music professionally.",                       1),
            ("Actor",                           .showBusiness,         38_000, "🎭", "Performs in theater, film, or television.",                        1),
            ("Dancer",                          .showBusiness,         35_000, "💃", "Performs choreographed routines on stage and screen.",             1),

            ("Animator",                        .design,       65_000, "🎞️", "Creates 2D/3D animation for studios and clients.",                 4),
            ("Interior Designer",               .design,       60_000, "🛋️", "Designs and styles indoor spaces for clients.",                    4),

            // Gaming — the studios that make video games (art, design, engineering)
            ("Game QA Tester",                  .gaming,       45_000, "🔍", "Hunts bugs and verifies gameplay before release.",                 3),
            ("3D Modeler",                      .gaming,       58_000, "🧊", "Sculpts characters, props, and environments as 3D assets.",        4),
            ("Game Animator",                   .gaming,       62_000, "🎞️", "Brings characters and creatures to life in motion.",               4),
            ("3D Artist",                       .gaming,       64_000, "🎨", "Creates textured, lit 3D art for games.",                          4),
            ("Level Designer",                  .gaming,       68_000, "🗺️", "Builds and balances the game's levels and pacing.",                4),
            ("Narrative Designer",              .gaming,       72_000, "✍️", "Writes the story, characters, and branching dialogue.",            5),
            ("Game Designer",                   .gaming,       78_000, "🎮", "Designs mechanics, systems, and the player experience.",           5),
            ("Technical Artist",                .gaming,       92_000, "🛠️", "Bridges art and code — shaders, tools, and pipelines.",            5),
            ("Gameplay Programmer",             .gaming,       98_000, "💻", "Codes game systems, mechanics, and engine features.",              5),
            ("Game Producer",                   .gaming,      105_000, "📋", "Coordinates team, schedule, and scope to ship the game.",          5),
        ]

        // MARK: - Compose final list

        var extras: [Job] = []
        for (title, cat, income, icon, summary, eqf) in titles {
            extras.append(fullJob(id: title, category: cat, income: income, icon: icon, summary: summary, minEQF: eqf))
        }

        // MARK: - Seniority ladders
        // Explicit (id, category, income, icon, summary, minEQF, minYears) so the
        // same role appears at multiple seniority levels with realistic salary
        // and experience progression. Hard-skill requirements are inherited from
        // the base role via `baseTitle(...)`.
        let seniorityTitles: [(String, JobCategory, Int, String, String, Int, Int)] = [
            // Technology
            ("Junior Software Engineer",     .technology,    78_000, "💻", "Entry-level developer learning the codebase and shipping small features.",        5, 0),
            ("Senior Software Engineer",     .technology,   155_000, "💻", "Owns major systems, mentors peers, and drives technical direction.",             5, 5),
            ("Staff Software Engineer",      .technology,   200_000, "💻", "Sets engineering strategy across teams and unblocks complex initiatives.",       6, 9),
            ("Principal Software Engineer",  .technology,   245_000, "💻", "Top-of-ladder IC; defines architecture for the whole organization.",            6, 12),
            ("Junior Data Analyst",          .technology,    62_000, "📊", "Builds basic dashboards and runs ad-hoc queries under supervision.",              4, 0),
            ("Senior Data Analyst",          .technology,   118_000, "📊", "Owns analytical workstreams and partners with leadership on decisions.",          5, 4),
            ("Junior Data Scientist",        .technology,    95_000, "📈", "Builds and validates models under senior data-science guidance.",                 5, 0),
            ("Senior Systems Administrator", .technology,   110_000, "🖧",  "Architects infrastructure and leads incident response.",                          4, 5),

            // Design
            ("Junior UX/UI Designer",        .design,        60_000, "🖥️", "Produces wireframes and visual assets under senior direction.",                  4, 0),
            ("Senior UX/UI Designer",        .design,       120_000, "🖥️", "Leads end-to-end design of major product surfaces.",                              5, 5),
            ("Lead UX/UI Designer",          .design,       155_000, "🖥️", "Sets design vision and mentors the design team.",                                 5, 8),
            ("Junior Graphic Artist",        .design,        36_000, "🎨", "Produces assets to spec under art-director review.",                              3, 0),
            ("Senior Graphic Artist",        .design,        72_000, "🎨", "Owns visual identity work and directs junior artists.",                           4, 4),

            // Engineering disciplines
            ("Junior Civil Engineer",        .engineering,   64_000, "🛣️", "Drafts plans and supports senior engineers on site.",                             5, 0),
            ("Senior Civil Engineer",        .engineering,  125_000, "🛣️", "Leads infrastructure projects and signs off on designs.",                         5, 6),
            ("Junior Mechanical Engineer",   .engineering,   62_000, "⚙️", "Assists in design and analysis of mechanical components.",                        5, 0),
            ("Senior Mechanical Engineer",   .engineering,  120_000, "⚙️", "Owns mechanical design projects end-to-end.",                                     5, 6),
            ("Junior Electrical Engineer",   .engineering,   64_000, "🔋", "Supports design and testing of electrical systems.",                              5, 0),
            ("Senior Electrical Engineer",   .engineering,  122_000, "🔋", "Leads electrical-system architecture for complex products.",                      5, 6),

            // Business / Finance
            ("Junior Accountant",            .administration, 52_000, "📒", "Books transactions and supports month-end close.",                                4, 0),
            ("Senior Accountant",            .administration,105_000, "📒", "Owns ledger areas and supervises junior accountants.",                            5, 4),
            ("Junior Financial Analyst",     .business,      68_000, "💹", "Builds forecasting models with senior oversight.",                                5, 0),
            ("Senior Financial Analyst",     .business,     140_000, "💹", "Partners with executives on capital planning and strategy.",                      5, 5),
            ("Junior Business Analyst",      .business,      58_000, "📈", "Gathers requirements and documents processes.",                                   4, 0),
            ("Senior Business Analyst",      .business,     115_000, "📈", "Leads cross-functional analysis and drives recommendations.",                     5, 4),
            ("Junior Marketing Specialist",  .business,      46_000, "📣", "Executes campaigns under direction from senior marketers.",                       4, 0),
            ("Senior Marketing Specialist",  .business,      94_000, "📣", "Owns marketing programs and reports on impact.",                                  5, 4),
            ("Marketing Director",           .business,     145_000, "📣", "Leads the marketing function and brand strategy.",                                5, 8),
            ("Senior Project Manager",       .business,     145_000, "📋", "Manages portfolios of projects and senior stakeholders.",                         5, 7),
            ("Senior Sales Manager",         .business,     150_000, "📈", "Runs regional sales orgs and hits aggressive targets.",                           5, 7),
            ("Junior Management Consultant", .business,      85_000, "🧠", "Runs analysis workstreams on client engagements under a lead consultant.",        5, 0),
            ("Junior Investment Banker",     .business,     110_000, "🏦", "Analyst building models and pitch decks on live deals under senior bankers.",     5, 0),

            // Law
            ("Junior Paralegal",             .law,           38_000, "📑", "Files documents and supports research for senior staff.",                         3, 0),
            ("Senior Paralegal",             .law,           65_000, "📑", "Manages caseload research and trains junior paralegals.",                         4, 4),
            ("Managing Partner",             .law,          220_000, "⚖️", "Equity partner driving client relationships and firm strategy — the top of the law track.", 7, 8),

            // Health
            ("Senior Registered Nurse",      .health,       110_000, "🩺", "Experienced floor nurse mentoring newer staff.",                                  5, 5),
            ("Charge Registered Nurse",      .health,       130_000, "🩺", "Coordinates the nursing shift and triages escalations — the top of the floor-nursing ladder.", 5, 8),
            ("Nurse Practitioner",           .health,       125_000, "🥼", "Advanced-practice nurse who diagnoses, treats, and prescribes with autonomy.",     6, 2),

            // Science — Laboratory track (base "Lab Technician")
            ("Senior Lab Technician",        .science,       58_000, "🧪", "Leads lab testing and trains junior technicians.",                                4, 5),
            ("Lead Lab Technician",          .science,       74_000, "🔬", "Runs the lab's daily operations, safety, and quality.",                           5, 9),
            // Science — Research track (base "Research Scientist", doctorate-gated)
            ("Junior Research Scientist",    .science,       72_000, "🔬", "Early-career scientist running experiments under a senior lead.",                 7, 0),
            ("Senior Research Scientist",    .science,      145_000, "🔬", "Leads research programs and publishes original work.",                            7, 6),
            ("Principal Research Scientist", .science,      195_000, "🔬", "Sets research agenda for the lab and supervises projects.",                       7, 10),

            // Hospitality (chef ladder)
            ("Sous Chef",                    .hospitality,   65_000, "👨‍🍳", "Second-in-command in the kitchen, runs daily service.",                          4, 3),
            ("Head Chef",                    .hospitality,   92_000, "👨‍🍳", "Owns menu, sourcing, and kitchen leadership.",                                   4, 6),
            ("Executive Chef",               .hospitality,  140_000, "👨‍🍳", "Oversees multiple kitchens and culinary brand.",                                 4, 10),

            // Public Services — Law Enforcement track (base "Police Officer")
            ("Senior Police Officer",        .publicServices, 95_000, "👮", "Veteran officer leading patrols and mentoring recruits.",                         3, 5),
            ("Lead Police Officer",          .publicServices,130_000, "🚓", "Commands a precinct and sets policing strategy.",                                 4, 12),
            // Public Services — Firefighting / Rescue track (base "Firefighter")
            ("Senior Firefighter",           .publicServices, 85_000, "🚒", "Experienced firefighter leading a crew on emergency calls.",                      3, 6),
            ("Lead Firefighter",             .publicServices,120_000, "🚒", "Commands a fire station and emergency operations.",                               4, 12),
            // Public Services — Municipal Services track (base "Municipal Worker")
            ("Senior Municipal Worker",      .publicServices, 55_000, "🧰", "Seasoned public-works hand running crews and equipment.",                         2, 5),
            ("Lead Municipal Worker",        .publicServices, 72_000, "🏛️", "Supervises municipal crews, budgets, and city services.",                         3, 10),

            // Construction trades
            ("Master Electrician",           .construction,  92_000, "🔌", "Licensed master responsible for jobs and apprentices.",                            4, 5),
            ("Master Plumber",               .construction,  88_000, "🚰", "Licensed master plumber leading complex installations.",                           4, 5),
            ("Master Carpenter",             .construction,  76_000, "🪚", "Master tradesperson on bespoke and large-scale builds.",                           4, 6),

            // Education — Tutor track (base "Tutor", accessible)
            ("Senior Tutor",                 .education,      46_000, "📖", "Experienced tutor running group sessions and mentoring tutors.",                  4, 5),
            ("Lead Tutor",                   .education,      60_000, "📖", "Runs a tutoring center's staff, curriculum, and clients.",                        5, 9),
            // Education — Teacher track (base "Teacher", degree-gated)
            ("Senior Teacher",               .education,      66_000, "📚", "Veteran teacher mentoring staff and leading a department.",                       5, 6),
            ("Lead Teacher",                 .education,      92_000, "🍎", "Heads the school's academics and leads the teaching staff.",                      6, 11),

            // Creative leadership
            ("Art Director",                 .showBusiness,          100_000, "🖼️", "Sets the visual direction for campaigns, films, or publications.",                5, 8),
            ("Editor-in-Chief",              .showBusiness,         135_000, "🗞️", "Leads a publication's editorial vision and newsroom.",                            5, 10),

            // Gaming — art, design, and engineering ladders inside a studio
            ("Senior 3D Artist",             .gaming,         95_000, "🎨", "Owns key art and sets the visual bar for the team.",                              4, 5),
            ("Art Director (Games)",         .gaming,        145_000, "🖌️", "Directs the art team and defines the game's whole look.",                         5, 8),
            ("Senior Game Designer",         .gaming,        115_000, "🎮", "Owns major game systems and mentors designers.",                                  5, 5),
            ("Lead Game Designer",           .gaming,        150_000, "🎮", "Sets the design vision for the entire title.",                                    5, 9),
            ("Senior Gameplay Programmer",   .gaming,        150_000, "💻", "Owns complex gameplay systems and mentors engineers.",                            5, 5),
            ("Lead Gameplay Programmer",     .gaming,        190_000, "💻", "Leads the gameplay engineering team and its architecture.",                       5, 9),

            // C-suite — the top of the business, tech, and medical tracks
            ("Chief Medical Officer",        .health,        300_000, "🏥", "Sets clinical strategy and quality across a health system.",                      7, 12),
            ("Chief Technology Officer",     .technology,    320_000, "🧠", "Owns technology strategy for the whole organization.",                            6, 12),
            ("Chief Executive Officer",      .business,      400_000, "👔", "Leads the entire company and answers to the board.",                              6, 15),

            // MARK: Added rungs so every professional track has ≥3 levels.
            // Prefixed rungs gate on same-track (per-role) experience; the
            // Director/Partner capstones stay reachable on broad industry years.
            // Tech — junior entry beneath the Systems Administrator ladder
            ("Junior Systems Administrator", .technology,    62_000, "🖧",  "Maintains servers and accounts under senior guidance.",                           4, 0),
            // Business — top rung / sales leadership capstone
            ("Lead Project Manager",         .business,     175_000, "📋", "Heads the PMO and the organization's most critical programs.",                    5, 10),
            ("Sales Director",               .business,     175_000, "📈", "Owns the entire sales organization and revenue strategy.",                        5, 10),
            // Law — associate → senior associate → partner
            ("Senior Lawyer",                .law,          170_000, "⚖️", "Senior associate leading cases and mentoring junior lawyers.",                    7, 6),
            // Trades — apprentice entry beneath the journeyman base role and master
            ("Apprentice Electrician",       .construction,  40_000, "🔌", "Trains on the job toward a journeyman electrician license.",                       3, 0),
            ("Apprentice Plumber",           .construction,  40_000, "🚰", "Learns the plumbing trade under a licensed plumber.",                             3, 0),
            ("Apprentice Carpenter",         .construction,  34_000, "🪚", "Learns carpentry on site under a master carpenter.",                              3, 0),
            // Medicine — attending rung between resident physician and CMO
            ("Senior Physician",             .health,       280_000, "🩺", "Attending physician supervising residents and complex cases.",                    7, 5),
        ]

        for (title, cat, income, icon, summary, eqf, years) in seniorityTitles {
            extras.append(fullJob(id: title, category: cat, income: income, icon: icon, summary: summary, minEQF: eqf, minYears: years))
        }

        // MARK: - Ventures (concrete, industry-specific founder plays)
        // Each venture is a real business idea in a real industry, not a generic
        // "startup". They're one-off founder bets — no auto-climbing ladder — and
        // you run one at a time (it becomes your occupation until you sell out or
        // go bankrupt; see `Player.foundVenture` and the Boardroom). What flags a
        // role as a venture is its `targetCapital` (`Job.isEntrepreneurial`), not
        // its category — so each keeps its true industry category, which means
        // your relevant work experience *in that field* feeds the launch odds
        // (`Job.founderSuccessProbability` weights experience + soft-skill fit
        // over raw capital). Founders aren't gated on degrees (`minEQF: 0`); the
        // gate is the years of industry experience the idea demands.
        // (id, category, income, icon, summary, minYears, targetCapital)
        let ventures: [(String, JobCategory, Int, String, String, Int, Int)] = [
            ("Specialty Coffee Roastery", .retail,       46_000, "☕", "Source, roast, and sell your own beans through a café and online.",        1,  30_000),
            ("Boutique Fitness Studio",   .health,       52_000, "🏋️", "Run your own small-group training studio and build a member community.",   2,  35_000),
            ("Farm-to-Table Restaurant",  .hospitality,  60_000, "🍽️", "Open a seasonal restaurant sourcing straight from local growers.",         3,  80_000),
            ("Indie Game Studio",         .gaming,       85_000, "🎮", "Bootstrap a small studio and ship an original game to players.",           3,  55_000),
            ("Property Development Firm",  .construction,110_000, "🏗️", "Buy, build, and sell property — financing projects and managing crews.",   4, 120_000),
            ("SaaS App Startup",          .technology,  120_000, "💻", "Build a subscription software product and grow it toward a real raise.",   3,  60_000),
        ]
        for (title, cat, income, icon, summary, years, capital) in ventures {
            extras.append(fullJob(id: title, category: cat, income: income, icon: icon, summary: summary, minEQF: 0, minYears: years, targetCapital: capital))
        }

        var all: [Job] = [rn, lightDriver]
        all.append(contentsOf: extras)

        return all
    }

    /// Role pictogram keyed by base title — for surfacing a role's own industry
    /// icon in places that only hold the title string (e.g. the Experience list,
    /// which is keyed by `Job.baseTitle`). Deterministic, so it's built once.
    static let iconByBaseTitle: [String: String] = {
        var map: [String: String] = [:]
        for job in allJobs() where map[job.baseTitle] == nil {
            map[job.baseTitle] = job.icon
        }
        return map
    }()
}

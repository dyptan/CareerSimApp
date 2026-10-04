import Foundation

enum TrainingRequirementResult {
    case ok
    case blocked(reason: String)
}

// MARK: - Hard skills model

struct HardSkills: Codable, Hashable {
    /// Professional credentials the player has earned — certifications and
    /// licences alike, each a `Training`. A plain set: trainings carry no
    /// proficiency level (you either hold the credential or you don't).
    var trainings: Set<Training> = []

    init(trainings: Set<Training> = []) {
        self.trainings = trainings
    }
}

/// One soft-skill axis and its player-facing metadata. `SoftSkills.allAxes`
/// is the single source of truth: the struct's stored properties, the hire
/// scorer, the education admission machinery, and every UI list are all derived
/// from it. To add a new soft skill: add a stored property to `SoftSkills`,
/// add one entry here, and add one `Int.random` line to `Player.init`.
struct SoftSkillAxis: Identifiable {
    let keyPath: WritableKeyPath<SoftSkills, Int>
    /// The ability's name ("Inventor", "Leader") in the player's language. Stored as a
    /// resource so the table below stays a plain list of literals.
    private let labelResource: LocalizedStringResource
    let pictogram: String
    /// One resource per paragraph / bullet: the introduction first, then one line per place the
    /// skill counts (jobs, schools, grades, promotions, ventures, contests, what builds it).
    private let descriptionLines: [LocalizedStringResource]
    /// Whether this axis counts toward a job's hire-probability "fit" score.
    var isScored: Bool = true

    init(keyPath: WritableKeyPath<SoftSkills, Int>, label: LocalizedStringResource, pictogram: String,
         description: [LocalizedStringResource], isScored: Bool = true) {
        self.keyPath = keyPath
        self.labelResource = label
        self.pictogram = pictogram
        self.descriptionLines = description
        self.isScored = isScored
    }

    var label: String { String(localized: labelResource) }

    /// The skill's info tip: what it is, then where it counts — jobs, schools,
    /// grades, promotions, ventures, contests — and what builds it. Keep it in
    /// step with the catalogues when those change.
    var description: String {
        let lines = descriptionLines.map { String(localized: $0) }
        guard let intro = lines.first else { return "" }
        return lines.count > 1 ? intro + "\n\n" + lines.dropFirst().joined(separator: "\n") : intro
    }

    var id: String { String(labelResource.key) }
}

struct SoftSkills: Codable, Hashable {
    var analyticalReasoningAndProblemSolving: Int = 0
    var creativityAndInsightfulThinking: Int = 0
    var communicationAndNetworking: Int = 0
    var persuasionAndNegotiation: Int = 0
    var leadershipAndInfluence: Int = 0
    var visionaryThinkingAndAmbition: Int = 0
    var carefulnessAndAttentionToDetail: Int = 0
    var tinkeringAndFingerPrecision: Int = 0
    var spacialNavigationAndOrientation: Int = 0
    var resilienceAndEndurance: Int = 0
    var stressResistanceAndEmotionalRegulation: Int = 0
    var empathyAndInterpersonalCare: Int = 0
    var collaborationAndTeamwork: Int = 0
    var timeManagementAndPlanning: Int = 0
    var selfDisciplineAndPerseverance: Int = 0
    static let allAxes: [SoftSkillAxis] = [
        .init(keyPath: \.analyticalReasoningAndProblemSolving, label: LocalizedStringResource("Inventor", comment: "Name of a skill (ability) the player builds, shown next to a pictogram and used as a playful job-like title. The skill: Working problems out: spotting patterns and breaking a puzzle into steps."), pictogram: "💡", description: [  // i18n:ignore translator comment
            "Working problems out: spotting patterns and breaking a puzzle into steps.",
            "💼 Jobs: doctors, lawyers, judges, data scientists, engineers, financial analysts.",
            "🎓 Schools: Technology, Engineering, Science, Business and Law degrees look for it.",
            "📝 Grades: one of the four skills your high-school grade is built on.",
            "🏅 Contests: chess, coding, maths, science and quiz contests.",
            "🌱 Build it: Mathematics, Science, Coding, Chess, History & Geography, E-Sports."
        ]),
        .init(keyPath: \.creativityAndInsightfulThinking, label: LocalizedStringResource("Creator", comment: "Name of a skill (ability) the player builds, shown next to a pictogram and used as a playful job-like title. The skill: Coming up with new ideas and seeing things in fresh ways."), pictogram: "🎨", description: [  // i18n:ignore translator comment
            "Coming up with new ideas and seeing things in fresh ways.",
            "💼 Jobs: art directors, designers, architects, animators, game designers, photographers, marketers.",
            "🎓 Schools: Arts and Design degrees.",
            "🚀 Projects: most creative projects lean on it.",
            "🏅 Contests: music, art, photography, dance, cooking, writing and science fairs.",
            "🌱 Build it: Music, Drawing & Painting, Photography, Cooking, Dance, Science, Reading & Writing."
        ]),
        .init(keyPath: \.communicationAndNetworking, label: LocalizedStringResource("Influencer", comment: "Name of a skill (ability) the player builds, shown next to a pictogram and used as a playful job-like title. The skill: Talking, writing, listening and presenting — getting ideas across so people get them."), pictogram: "📢", description: [  // i18n:ignore translator comment
            "Talking, writing, listening and presenting — getting ideas across so people get them.",
            "💼 Jobs: one of the most-asked skills — journalists, TV presenters, interpreters, sales and marketing directors, every chief executive.",
            "🎓 Schools: most degree fields weigh it — Arts, Design, Business, Education, Health, Law, Science, Service.",
            "⬆️ Promotions: the top rung of a ladder asks for more of it.",
            "💰 Boardroom: part of your pitch in an investment round.",
            "🌱 Build it: Debate, Foreign Languages, Reading & Writing, Music, Dance, Photography, History & Geography."
        ]),
        .init(keyPath: \.persuasionAndNegotiation, label: LocalizedStringResource("Persuader", comment: "Name of a skill (ability) the player builds, shown next to a pictogram and used as a playful job-like title. The skill: Convincing people, negotiating deals and closing a sale."), pictogram: "💬", description: [  // i18n:ignore translator comment
            "Convincing people, negotiating deals and closing a sale.",
            "💼 Jobs: sales, real estate, insurance, lawyers, managing partners, chief executives.",
            "🚀 Ventures: one of the two founder traits behind every venture's odds.",
            "💰 Boardroom: the skill investors weigh most in an investment round, and key to selling shares.",
            "🌱 Build it: Debate, Student Council."
        ]),
        .init(keyPath: \.leadershipAndInfluence, label: LocalizedStringResource("Leader", comment: "Name of a skill (ability) the player builds, shown next to a pictogram and used as a playful job-like title. The skill: Helping a group decide and act together."), pictogram: "👑", description: [  // i18n:ignore translator comment
            "Helping a group decide and act together.",
            "💼 Jobs: managers, directors and every chief officer — the CEO seat asks for the most.",
            "⬆️ Promotions: from the second rung up, every ladder asks for more of it — often the skill holding a promotion back.",
            "💰 Boardroom: part of your pitch in an investment round.",
            "🌱 Build it: Student Council; later, some courses."
        ]),
        .init(keyPath: \.visionaryThinkingAndAmbition, label: LocalizedStringResource("Visionary", comment: "Name of a skill (ability) the player builds, shown next to a pictogram and used as a playful job-like title. The skill: Ambition and initiative: imagining big goals, betting on yourself, and acting before there's a playbook."), pictogram: "🔭", description: [  // i18n:ignore translator comment
            "Ambition and initiative: imagining big goals, betting on yourself, and acting before there's a playbook.",
            "💼 Jobs: chief executives, CTOs, directors, and the founder of every venture.",
            "🚀 Ventures: one of the two founder traits behind every venture's odds.",
            "⬆️ Promotions: the top rung of a ladder asks for more of it.",
            "💰 Boardroom: part of your pitch in an investment round, and in selling shares.",
            "🏅 Contests: the biggest titles — Olympics, world finals, international prizes — ask for it.",
            "🌱 Build it: Student Council; later, some projects."
        ]),
        .init(keyPath: \.carefulnessAndAttentionToDetail, label: LocalizedStringResource("Detective", comment: "Name of a skill (ability) the player builds, shown next to a pictogram and used as a playful job-like title. The skill: Catching small mistakes and double-checking everything."), pictogram: "🔍", description: [  // i18n:ignore translator comment
            "Catching small mistakes and double-checking everything.",
            "💼 Jobs: the most-asked skill in the game — surgeons, pharmacists, accountants, nurses, inspectors, aircraft technicians.",
            "🎓 Schools: Technology, Engineering, Arts, Design, Health and Law degrees.",
            "📝 Grades: one of the four skills your high-school grade is built on.",
            "🏅 Contests: chess, coding, maths, science, writing, art, photography and cooking.",
            "🌱 Build it: Mathematics, Science, Coding, Chess, Reading & Writing, Drawing & Painting, Photography, Cooking, Tennis — and many courses."
        ]),
        .init(keyPath: \.tinkeringAndFingerPrecision, label: LocalizedStringResource("Fixer", comment: "Name of a skill (ability) the player builds, shown next to a pictogram and used as a playful job-like title. The skill: Working steadily and precisely with your hands."), pictogram: "🛠️", description: [  // i18n:ignore translator comment
            "Working steadily and precisely with your hands.",
            "💼 Jobs: surgeons, dentists, plumbers, carpenters, HVAC technicians, welders, machinists, mechanics.",
            "🎓 Schools: Technology and Engineering degrees.",
            "🏅 Contests: art, cooking and e-sports.",
            "🌱 Build it: Music, Drawing & Painting, Cooking, Gymnastics, E-Sports — and trade courses."
        ]),
        .init(keyPath: \.spacialNavigationAndOrientation, label: LocalizedStringResource("Navigator", comment: "Name of a skill (ability) the player builds, shown next to a pictogram and used as a playful job-like title. The skill: Picturing how shapes, spaces and machines fit together — and finding your way."), pictogram: "🧭", description: [  // i18n:ignore translator comment
            "Picturing how shapes, spaces and machines fit together — and finding your way.",
            "💼 Jobs: architects, pilots, engineers, surgeons, 3D artists, level designers, heavy-equipment operators.",
            "🎓 Schools: Engineering and Design degrees.",
            "🏅 Contests: team sports and geography contests.",
            "🌱 Build it: Skateboarding & BMX, History & Geography — and some courses."
        ]),
        .init(keyPath: \.resilienceAndEndurance, label: LocalizedStringResource("Athlete", comment: "Name of a skill (ability) the player builds, shown next to a pictogram and used as a playful job-like title. The skill: Physical stamina — long shifts on your feet, heavy work, and all weathers, indoors or out."), pictogram: "🏃", description: [  // i18n:ignore translator comment
            "Physical stamina — long shifts on your feet, heavy work, and all weathers, indoors or out.",
            "💼 Jobs: firefighters, paramedics, chefs, surgeons, builders, roofers, movers, farmers.",
            "🎓 Schools: Health, Sports and Agriculture degrees.",
            "🏅 Contests: every sports contest.",
            "🌱 Build it: any sport, and Dance."
        ]),
        .init(keyPath: \.stressResistanceAndEmotionalRegulation, label: LocalizedStringResource("Zen", comment: "Name of a skill (ability) the player builds, shown next to a pictogram and used as a playful job-like title. The skill: Staying calm and thinking clearly under pressure — when a mistake is costly and there's no time."), pictogram: "☯️", description: [  // i18n:ignore translator comment
            "Staying calm and thinking clearly under pressure — when a mistake is costly and there's no time.",
            "💼 Jobs: the high-stakes ones — surgeons and anesthesiologists ask the most, then paramedics, police, firefighters, pilots, chefs and chief executives.",
            "🎓 Schools: Education, Health and Service degrees.",
            "🏅 Contests: most of them, from races and matches to chess, olympiads and cook-offs — keeping your nerve wins titles.",
            "🌱 Build it: Swimming, Tennis, Martial Arts, Skateboarding & BMX, Chess, Drawing & Painting — and some courses."
        ]),
        .init(keyPath: \.empathyAndInterpersonalCare, label: LocalizedStringResource("Empath", comment: "Name of a skill (ability) the player builds, shown next to a pictogram and used as a playful job-like title. The skill: Sensing how others feel and responding with care."), pictogram: "🫶", description: [  // i18n:ignore translator comment
            "Sensing how others feel and responding with care.",
            "💼 Jobs: social workers, psychologists, nurses and care aides, childcare workers, physiotherapists, HR, customer service.",
            "🎓 Schools: Education, Health and Service degrees.",
            "🌱 Build it: Cooking, Foreign Languages — and care courses."
        ]),
        .init(keyPath: \.collaborationAndTeamwork, label: LocalizedStringResource("Teamplayer", comment: "Name of a skill (ability) the player builds, shown next to a pictogram and used as a playful job-like title. The skill: Sharing the work and pulling together with others."), pictogram: "🤝", description: [  // i18n:ignore translator comment
            "Sharing the work and pulling together with others.",
            "💼 Jobs: nearly every job asks — most of all pro players, firefighters, nurses, project managers and chief officers.",
            "🎓 Schools: Technology, Engineering, Business, Sports and Service degrees.",
            "🏅 Contests: team sports, e-sports and hackathons.",
            "🌱 Build it: Soccer, Basketball, Student Council."
        ]),
        .init(keyPath: \.timeManagementAndPlanning, label: LocalizedStringResource("Planner", comment: "Name of a skill (ability) the player builds, shown next to a pictogram and used as a playful job-like title. The skill: Organising your days and finishing things on time."), pictogram: "📅", description: [  // i18n:ignore translator comment
            "Organising your days and finishing things on time.",
            "💼 Jobs: project managers, event planners, dispatchers, logistics coordinators, and managers of every kind.",
            "🎓 Schools: most degree fields weigh it.",
            "📝 Grades: one of the four skills your high-school grade is built on.",
            "⬆️ Promotions: from the second rung up, every ladder asks for more of it.",
            "🌱 Build it: Science, Photography, History & Geography."
        ]),
        .init(keyPath: \.selfDisciplineAndPerseverance, label: LocalizedStringResource("Champion", comment: "Name of a skill (ability) the player builds, shown next to a pictogram and used as a playful job-like title. The skill: Sticking with hard work even when it's boring."), pictogram: "🏆", description: [  // i18n:ignore translator comment
            "Sticking with hard work even when it's boring.",
            "💼 Jobs: surgeons, research scientists, lawyers, judges, athletes, founders.",
            "🎓 Schools: Technology, Science and Sports degrees.",
            "📝 Grades: one of the four skills your high-school grade is built on.",
            "🏅 Contests: most sports, and music, dance, maths, coding and language contests.",
            "🌱 Build it: Running, Martial Arts, Gymnastics, Music, Dance, Coding, Mathematics, Foreign Languages."
        ]),
    ]

    /// Back-compat tuple view of `allAxes` used by views that iterate skills.
    static let skillNames: [(keyPath: WritableKeyPath<SoftSkills, Int>, label: String, pictogram: String, description: String)] =
        allAxes.map { ($0.keyPath, $0.label, $0.pictogram, $0.description) }

    private static let _labelMap: [AnyKeyPath: String] =
        Dictionary(uniqueKeysWithValues: allAxes.map { ($0.keyPath as AnyKeyPath, $0.label) })
    private static let _pictogramMap: [AnyKeyPath: String] =
        Dictionary(uniqueKeysWithValues: allAxes.map { ($0.keyPath as AnyKeyPath, $0.pictogram) })
    private static let _descriptionMap: [AnyKeyPath: String] =
        Dictionary(uniqueKeysWithValues: allAxes.map { ($0.keyPath as AnyKeyPath, $0.description) })

    static func label(forKeyPath keyPath: PartialKeyPath<SoftSkills>) -> String? {
        _labelMap[keyPath]
    }

    static func pictogram(forKeyPath keyPath: PartialKeyPath<SoftSkills>) -> String? {
        _pictogramMap[keyPath]
    }

    static func description(forKeyPath keyPath: PartialKeyPath<SoftSkills>) -> String? {
        _descriptionMap[keyPath]
    }
}


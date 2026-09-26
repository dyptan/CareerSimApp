import Foundation

enum TrainingRequirementResult {
    case ok
    case blocked(reason: String)
}

// MARK: - Hard skills model

struct HardSkills: Codable, Hashable {
    /// Professional credentials the player has earned — the former
    /// certifications and licences, now unified as `Training`. A plain set:
    /// trainings carry no proficiency level (you either hold the credential or
    /// you don't).
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
    let label: String
    let pictogram: String
    /// The skill's info tip: what it is, then where it counts — jobs, schools,
    /// grades, promotions, ventures, contests — and what builds it. Keep it in
    /// step with the catalogues when those change.
    let description: String
    /// Whether this axis counts toward a job's hire-probability "fit" score.
    var isScored: Bool = true

    var id: String { label }
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
        .init(keyPath: \.analyticalReasoningAndProblemSolving, label: "Inventor", pictogram: "💡", description: "Working problems out: spotting patterns and breaking a puzzle into steps.\n\n💼 Jobs: doctors, lawyers, judges, data scientists, engineers, financial analysts.\n🎓 Schools: Technology, Engineering, Science, Business and Law degrees look for it.\n📝 Grades: one of the four skills your high-school grade is built on.\n🏅 Contests: chess, coding, maths, science and quiz contests.\n🌱 Build it: Mathematics, Science, Coding, Chess, History & Geography, E-Sports."),
        .init(keyPath: \.creativityAndInsightfulThinking, label: "Creator", pictogram: "🎨", description: "Coming up with new ideas and seeing things in fresh ways.\n\n💼 Jobs: art directors, designers, architects, animators, game designers, musicians, photographers, marketers.\n🎓 Schools: Arts and Design degrees.\n🚀 Projects: most creative projects lean on it.\n🏅 Contests: music, art, photography, dance, cooking, writing and science fairs.\n🌱 Build it: Music, Drawing & Painting, Photography, Cooking, Dance, Science, Reading & Writing."),
        .init(keyPath: \.communicationAndNetworking, label: "Influencer", pictogram: "📢", description: "Talking, writing, listening and presenting — getting ideas across so people get them.\n\n💼 Jobs: one of the most-asked skills — actors, journalists, interpreters, sales and marketing directors, every chief executive.\n🎓 Schools: most degree fields weigh it — Arts, Design, Business, Education, Health, Law, Science, Service.\n⬆️ Promotions: the top rung of a ladder asks for more of it.\n💰 Boardroom: part of your pitch in an investment round.\n🌱 Build it: Debate, Foreign Languages, Reading & Writing, Music, Dance, Photography, History & Geography."),
        .init(keyPath: \.persuasionAndNegotiation, label: "Persuader", pictogram: "💬", description: "Convincing people, negotiating deals and closing a sale.\n\n💼 Jobs: sales, real estate, insurance, lawyers, managing partners, chief executives.\n🚀 Ventures: one of the two founder traits behind every venture's odds.\n💰 Boardroom: the skill investors weigh most in an investment round, and key to selling shares.\n🌱 Build it: Debate, Student Council."),
        .init(keyPath: \.leadershipAndInfluence, label: "Leader", pictogram: "👑", description: "Helping a group decide and act together.\n\n💼 Jobs: managers, directors and every chief officer — the CEO seat asks for the most.\n⬆️ Promotions: from the second rung up, every ladder asks for more of it — often the skill holding a promotion back.\n💰 Boardroom: part of your pitch in an investment round.\n🌱 Build it: Student Council; later, some courses."),
        .init(keyPath: \.visionaryThinkingAndAmbition, label: "Visionary", pictogram: "🔭", description: "Ambition and initiative: imagining big goals, betting on yourself, and acting before there's a playbook.\n\n💼 Jobs: chief executives, CTOs, directors, and the founder of every venture.\n🚀 Ventures: one of the two founder traits behind every venture's odds.\n⬆️ Promotions: the top rung of a ladder asks for more of it.\n💰 Boardroom: part of your pitch in an investment round, and in selling shares.\n🏅 Contests: the biggest titles — Olympics, world finals, international prizes — ask for it.\n🌱 Build it: Student Council; later, some projects."),
        .init(keyPath: \.carefulnessAndAttentionToDetail, label: "Detective", pictogram: "🔍", description: "Catching small mistakes and double-checking everything.\n\n💼 Jobs: the most-asked skill in the game — surgeons, pharmacists, accountants, nurses, inspectors, aircraft technicians.\n🎓 Schools: Technology, Engineering, Arts, Design, Health and Law degrees.\n📝 Grades: one of the four skills your high-school grade is built on.\n🏅 Contests: chess, coding, maths, science, writing, art, photography and cooking.\n🌱 Build it: Mathematics, Science, Coding, Chess, Reading & Writing, Drawing & Painting, Photography, Cooking, Tennis — and many courses."),
        .init(keyPath: \.tinkeringAndFingerPrecision, label: "Fixer", pictogram: "🛠️", description: "Working steadily and precisely with your hands.\n\n💼 Jobs: surgeons, dentists, plumbers, carpenters, HVAC technicians, welders, machinists, mechanics.\n🎓 Schools: Technology and Engineering degrees.\n🏅 Contests: art, cooking and e-sports.\n🌱 Build it: Music, Drawing & Painting, Cooking, Gymnastics, E-Sports — and trade courses."),
        .init(keyPath: \.spacialNavigationAndOrientation, label: "Navigator", pictogram: "🧭", description: "Picturing how shapes, spaces and machines fit together — and finding your way.\n\n💼 Jobs: architects, pilots, engineers, surgeons, 3D artists, level designers, heavy-equipment operators.\n🎓 Schools: Engineering and Design degrees.\n🏅 Contests: team sports and geography contests.\n🌱 Build it: Skateboarding & BMX, History & Geography — and some courses."),
        .init(keyPath: \.resilienceAndEndurance, label: "Athlete", pictogram: "🏃", description: "Physical stamina — long shifts on your feet, heavy work, and all weathers, indoors or out.\n\n💼 Jobs: firefighters, paramedics, chefs, surgeons, builders, roofers, movers, farmers.\n🎓 Schools: Health, Sports and Agriculture degrees.\n🏅 Contests: every sports contest.\n🌱 Build it: any sport, and Dance."),
        .init(keyPath: \.stressResistanceAndEmotionalRegulation, label: "Zen", pictogram: "☯️", description: "Staying calm and thinking clearly under pressure — when a mistake is costly and there's no time.\n\n💼 Jobs: the high-stakes ones — surgeons and anesthesiologists ask the most, then paramedics, police, firefighters, pilots, chefs and chief executives.\n🎓 Schools: Education, Health and Service degrees.\n🏅 Contests: most of them, from races and matches to chess, olympiads and cook-offs — keeping your nerve wins titles.\n🌱 Build it: Swimming, Tennis, Martial Arts, Skateboarding & BMX, Chess, Drawing & Painting — and some courses."),
        .init(keyPath: \.empathyAndInterpersonalCare, label: "Empath", pictogram: "🫶", description: "Sensing how others feel and responding with care.\n\n💼 Jobs: social workers, psychologists, nurses and care aides, childcare workers, physiotherapists, HR, customer service.\n🎓 Schools: Education, Health and Service degrees.\n🌱 Build it: Cooking, Foreign Languages — and care courses."),
        .init(keyPath: \.collaborationAndTeamwork, label: "Teamplayer", pictogram: "🤝", description: "Sharing the work and pulling together with others.\n\n💼 Jobs: nearly every job asks — most of all pro players, firefighters, nurses, project managers and chief officers.\n🎓 Schools: Technology, Engineering, Business, Sports and Service degrees.\n🏅 Contests: team sports, e-sports and hackathons.\n🌱 Build it: Soccer, Basketball, Student Council."),
        .init(keyPath: \.timeManagementAndPlanning, label: "Planner", pictogram: "📅", description: "Organising your days and finishing things on time.\n\n💼 Jobs: project managers, event planners, dispatchers, logistics coordinators, and managers of every kind.\n🎓 Schools: most degree fields weigh it.\n📝 Grades: one of the four skills your high-school grade is built on.\n⬆️ Promotions: from the second rung up, every ladder asks for more of it.\n🌱 Build it: Science, Photography, History & Geography."),
        .init(keyPath: \.selfDisciplineAndPerseverance, label: "Champion", pictogram: "🏆", description: "Sticking with hard work even when it's boring.\n\n💼 Jobs: surgeons, research scientists, musicians, lawyers, judges, athletes, founders.\n🎓 Schools: Technology, Science and Sports degrees.\n📝 Grades: one of the four skills your high-school grade is built on.\n🏅 Contests: most sports, and music, dance, maths, coding and language contests.\n🌱 Build it: Running, Martial Arts, Gymnastics, Music, Dance, Coding, Mathematics, Foreign Languages."),
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


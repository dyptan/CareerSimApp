// HardcodedJobs.swift
import Foundation

enum JobExamples {
    static func sampleJobs() -> [Job] {

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
                    analyticalReasoningAndProblemSolving: 3,
                    creativityAndInsightfulThinking: 1,
                    communicationAndNetworking: 5,
                    leadershipAndInfluence: 2,
                    visionaryThinkingAndAmbition: 1,
                    carefulnessAndAttentionToDetail: 5,
                    tinkeringAndFingerPrecision: 3,
                    spacialNavigationAndOrientation: 0,
                    resilienceAndEndurance: 4,
                    stressResistanceAndEmotionalRegulation: 5,
                    outdoorAndWeatherResilience: 0,
                    collaborationAndTeamwork: 4,
                    timeManagementAndPlanning: 3,
                    selfDisciplineAndPerseverance: 3,
                    presentationAndStorytelling: 2
                ),
                hardSkills: .init(portfolioItems: [], certifications: [], software: [], licenses: [])
            ),
            companyTier: .government,
            version: 6
        )

        let dev = Job(
            id: "Software Developer",
            category: .technology,
            income: 110_000,
            summary: "Designs and builds computer programs and applications.",
            icon: "💻",
            requirements: .init(
                education: .init(minEQF: 5, acceptedProfiles: [.technology, .engineering, .science]),
                softSkills: .init(
                    analyticalReasoningAndProblemSolving: 5,
                    creativityAndInsightfulThinking: 3,
                    communicationAndNetworking: 3,
                    leadershipAndInfluence: 1,
                    visionaryThinkingAndAmbition: 2,
                    carefulnessAndAttentionToDetail: 4,
                    tinkeringAndFingerPrecision: 2,
                    spacialNavigationAndOrientation: 0,
                    resilienceAndEndurance: 2,
                    stressResistanceAndEmotionalRegulation: 3,
                    outdoorAndWeatherResilience: 0,
                    collaborationAndTeamwork: 4,
                    timeManagementAndPlanning: 3,
                    selfDisciplineAndPerseverance: 4,
                    presentationAndStorytelling: 2
                ),
                hardSkills: .init(portfolioItems: [], certifications: [], software: [], licenses: [])
            ),
            companyTier: .enterprise,
            version: 6
        )

        let designer = Job(
            id: "Graphic Designer",
            category: .design,
            income: 53_000,
            summary: "Creates visual concepts and designs for advertisements, publications, or digital media.",
            icon: "🎨",
            requirements: .init(
                education: .init(minEQF: 4, acceptedProfiles: [.design, .arts]),
                softSkills: .init(
                    analyticalReasoningAndProblemSolving: 2,
                    creativityAndInsightfulThinking: 5,
                    communicationAndNetworking: 3,
                    leadershipAndInfluence: 1,
                    visionaryThinkingAndAmbition: 3,
                    carefulnessAndAttentionToDetail: 4,
                    tinkeringAndFingerPrecision: 2,
                    spacialNavigationAndOrientation: 3,
                    resilienceAndEndurance: 2,
                    stressResistanceAndEmotionalRegulation: 2,
                    outdoorAndWeatherResilience: 0,
                    collaborationAndTeamwork: 3,
                    timeManagementAndPlanning: 3,
                    selfDisciplineAndPerseverance: 3,
                    presentationAndStorytelling: 4
                ),
                hardSkills: .init(portfolioItems: [], certifications: [], software: [], licenses: [])
            ),
            companyTier: .smallBusiness,
            version: 6
        )

        let lightDriver = Job(
            id: "Light Truck Delivery Driver",
            category: .logistics,
            income: 42_000,
            summary: "Delivers goods locally using vans or small trucks.",
            icon: "🚐",
            requirements: .init(
                education: .init(minEQF: 3, acceptedProfiles: nil),
                softSkills: .init(
                    analyticalReasoningAndProblemSolving: 1,
                    creativityAndInsightfulThinking: 0,
                    communicationAndNetworking: 2,
                    leadershipAndInfluence: 0,
                    visionaryThinkingAndAmbition: 0,
                    carefulnessAndAttentionToDetail: 3,
                    tinkeringAndFingerPrecision: 1,
                    spacialNavigationAndOrientation: 3,
                    resilienceAndEndurance: 3,
                    stressResistanceAndEmotionalRegulation: 2,
                    outdoorAndWeatherResilience: 1,
                    collaborationAndTeamwork: 1,
                    timeManagementAndPlanning: 3,
                    selfDisciplineAndPerseverance: 2,
                    presentationAndStorytelling: 0
                ),
                hardSkills: .init(portfolioItems: [], certifications: [], software: [], licenses: [])
            ),
            companyTier: .mid,
            version: 6
        )

        // MARK: - Helpers

        // Realistic soft skill defaults per job category.
        // Every category now has non-zero values for stress, collaboration,
        // time management, self-discipline and presentation where they apply.
        func defaultSoft(for category: JobCategory) -> SoftSkills {
            switch category {

            case .technology, .engineering:
                return .init(
                    analyticalReasoningAndProblemSolving: 4,
                    creativityAndInsightfulThinking: 2,
                    communicationAndNetworking: 2,
                    leadershipAndInfluence: 1,
                    visionaryThinkingAndAmbition: 2,
                    carefulnessAndAttentionToDetail: 4,
                    tinkeringAndFingerPrecision: 2,
                    spacialNavigationAndOrientation: 1,
                    resilienceAndEndurance: 2,
                    stressResistanceAndEmotionalRegulation: 3,
                    outdoorAndWeatherResilience: 0,
                    collaborationAndTeamwork: 3,
                    timeManagementAndPlanning: 3,
                    selfDisciplineAndPerseverance: 4,
                    presentationAndStorytelling: 2
                )

            case .health, .education:
                return .init(
                    analyticalReasoningAndProblemSolving: 3,
                    creativityAndInsightfulThinking: 1,
                    communicationAndNetworking: 4,
                    leadershipAndInfluence: 2,
                    visionaryThinkingAndAmbition: 1,
                    carefulnessAndAttentionToDetail: 4,
                    tinkeringAndFingerPrecision: 1,
                    spacialNavigationAndOrientation: 0,
                    resilienceAndEndurance: 4,
                    stressResistanceAndEmotionalRegulation: 4,
                    outdoorAndWeatherResilience: 0,
                    collaborationAndTeamwork: 4,
                    timeManagementAndPlanning: 3,
                    selfDisciplineAndPerseverance: 3,
                    presentationAndStorytelling: 3
                )

            case .service, .hospitality, .retail, .tourism:
                return .init(
                    analyticalReasoningAndProblemSolving: 1,
                    creativityAndInsightfulThinking: 2,
                    communicationAndNetworking: 4,
                    leadershipAndInfluence: 1,
                    visionaryThinkingAndAmbition: 1,
                    carefulnessAndAttentionToDetail: 2,
                    tinkeringAndFingerPrecision: 0,
                    spacialNavigationAndOrientation: 1,
                    resilienceAndEndurance: 3,
                    stressResistanceAndEmotionalRegulation: 3,
                    outdoorAndWeatherResilience: 0,
                    collaborationAndTeamwork: 3,
                    timeManagementAndPlanning: 2,
                    selfDisciplineAndPerseverance: 2,
                    presentationAndStorytelling: 3
                )

            case .construction, .manufacturing, .automotive:
                return .init(
                    analyticalReasoningAndProblemSolving: 2,
                    creativityAndInsightfulThinking: 1,
                    communicationAndNetworking: 1,
                    leadershipAndInfluence: 1,
                    visionaryThinkingAndAmbition: 1,
                    carefulnessAndAttentionToDetail: 3,
                    tinkeringAndFingerPrecision: 4,
                    spacialNavigationAndOrientation: 3,
                    resilienceAndEndurance: 4,
                    stressResistanceAndEmotionalRegulation: 2,
                    outdoorAndWeatherResilience: 2,
                    collaborationAndTeamwork: 2,
                    timeManagementAndPlanning: 2,
                    selfDisciplineAndPerseverance: 2,
                    presentationAndStorytelling: 1
                )

            case .design, .arts, .media, .fashion:
                return .init(
                    analyticalReasoningAndProblemSolving: 2,
                    creativityAndInsightfulThinking: 5,
                    communicationAndNetworking: 3,
                    leadershipAndInfluence: 1,
                    visionaryThinkingAndAmbition: 3,
                    carefulnessAndAttentionToDetail: 3,
                    tinkeringAndFingerPrecision: 2,
                    spacialNavigationAndOrientation: 2,
                    resilienceAndEndurance: 2,
                    stressResistanceAndEmotionalRegulation: 2,
                    outdoorAndWeatherResilience: 0,
                    collaborationAndTeamwork: 3,
                    timeManagementAndPlanning: 3,
                    selfDisciplineAndPerseverance: 3,
                    presentationAndStorytelling: 4
                )

            case .business, .law, .humanities, .science:
                return .init(
                    analyticalReasoningAndProblemSolving: 4,
                    creativityAndInsightfulThinking: 2,
                    communicationAndNetworking: 4,
                    leadershipAndInfluence: 3,
                    visionaryThinkingAndAmbition: 2,
                    carefulnessAndAttentionToDetail: 3,
                    tinkeringAndFingerPrecision: 0,
                    spacialNavigationAndOrientation: 0,
                    resilienceAndEndurance: 2,
                    stressResistanceAndEmotionalRegulation: 3,
                    outdoorAndWeatherResilience: 0,
                    collaborationAndTeamwork: 3,
                    timeManagementAndPlanning: 3,
                    selfDisciplineAndPerseverance: 3,
                    presentationAndStorytelling: 3
                )

            case .logistics:
                return .init(
                    analyticalReasoningAndProblemSolving: 2,
                    creativityAndInsightfulThinking: 1,
                    communicationAndNetworking: 2,
                    leadershipAndInfluence: 1,
                    visionaryThinkingAndAmbition: 1,
                    carefulnessAndAttentionToDetail: 3,
                    tinkeringAndFingerPrecision: 1,
                    spacialNavigationAndOrientation: 4,
                    resilienceAndEndurance: 3,
                    stressResistanceAndEmotionalRegulation: 2,
                    outdoorAndWeatherResilience: 1,
                    collaborationAndTeamwork: 2,
                    timeManagementAndPlanning: 3,
                    selfDisciplineAndPerseverance: 2,
                    presentationAndStorytelling: 1
                )

            case .agriculture, .maritime:
                return .init(
                    analyticalReasoningAndProblemSolving: 1,
                    creativityAndInsightfulThinking: 1,
                    communicationAndNetworking: 1,
                    leadershipAndInfluence: 1,
                    visionaryThinkingAndAmbition: 2,
                    carefulnessAndAttentionToDetail: 2,
                    tinkeringAndFingerPrecision: 2,
                    spacialNavigationAndOrientation: 2,
                    resilienceAndEndurance: 5,
                    stressResistanceAndEmotionalRegulation: 2,
                    outdoorAndWeatherResilience: 3,
                    collaborationAndTeamwork: 2,
                    timeManagementAndPlanning: 2,
                    selfDisciplineAndPerseverance: 3,
                    presentationAndStorytelling: 0
                )

            default:
                return .init(
                    analyticalReasoningAndProblemSolving: 1,
                    creativityAndInsightfulThinking: 1,
                    communicationAndNetworking: 2,
                    leadershipAndInfluence: 0,
                    visionaryThinkingAndAmbition: 0,
                    carefulnessAndAttentionToDetail: 2,
                    tinkeringAndFingerPrecision: 0,
                    spacialNavigationAndOrientation: 0,
                    resilienceAndEndurance: 2,
                    stressResistanceAndEmotionalRegulation: 2,
                    outdoorAndWeatherResilience: 0,
                    collaborationAndTeamwork: 2,
                    timeManagementAndPlanning: 2,
                    selfDisciplineAndPerseverance: 1,
                    presentationAndStorytelling: 1
                )
            }
        }

        func defaultHard(for title: String, category: JobCategory) -> HardSkills {
            return .init(portfolioItems: [], certifications: [], software: [], licenses: [])
        }

        func companyTierFor(income: Int, category: JobCategory) -> CompanyTier {
            switch category {
            case .publicServices, .education:
                return .government
            case .health:
                // High-earning health roles (surgeons, dentists) may work privately
                return income >= 130_000 ? .enterprise : .government
            case .arts:
                // Most artists and performers are self-employed or freelance
                return .selfEmployed
            case .agriculture:
                // Farmers and fishers are typically self-employed or family operations
                return income >= 60_000 ? .mid : .selfEmployed
            case .service, .construction where income < 50_000:
                // Local tradespeople and small service workers
                return .smallBusiness
            default:
                if income >= 100_000 { return .enterprise }
                if income >= 60_000  { return .mid }
                if income >= 38_000  { return .smallBusiness }
                return .startup
            }
        }

        func fullJob(id: String, category: JobCategory, income: Int, icon: String, summary: String, minEQF: Int) -> Job {
            let soft = defaultSoft(for: category)
            let hard = defaultHard(for: id, category: category)
            let edu = Job.Requirements.Education(minEQF: minEQF, acceptedProfiles: nil)
            let req = Job.Requirements(education: edu, softSkills: soft, hardSkills: hard)
            return Job(id: id, category: category, income: income, summary: summary, icon: icon, requirements: req, companyTier: companyTierFor(income: income, category: category), version: 6)
        }

        // MARK: - Job titles
        // (id, category, income, icon, summary, minEQF)
        // EQF: 1=Primary, 2=Middle, 3=High School, 4=Vocational, 5=Bachelor, 6=Master, 7=Doctorate
        let titles: [(String, JobCategory, Int, String, String, Int)] = [
            // Service / Retail / Hospitality
            ("Retail Salesperson",              .service,      30_000, "🛍️", "Sells products directly to customers.",                           3),
            ("Cashier",                         .service,      26_000, "💳", "Handles customer payments and transactions.",                      2),
            ("Office Clerk",                    .service,      33_000, "🗂️", "Performs general administrative duties.",                          3),
            ("Customer Service Representative", .service,      36_000, "☎️", "Assists customers with inquiries and support.",                    3),
            ("Waiter/Waitress",                 .service,      24_000, "🍽️", "Serves food and beverages to customers.",                          2),
            ("Food Preparation Worker",         .service,      25_000, "🍳", "Prepares ingredients and supports kitchen staff.",                  2),
            ("Security Guard",                  .service,      32_000, "🛡️", "Protects property and ensures safety.",                           3),
            ("Janitor/Cleaner",                 .service,      34_000, "🧹", "Maintains cleanliness of buildings and facilities.",               1),
            ("Receptionist",                    .service,      33_000, "📞", "Greets visitors and manages front-desk tasks.",                    3),
            ("Chef/Cook",                       .service,      52_000, "👨‍🍳", "Prepares meals in restaurants or institutions.",                  4),
            ("Baker",                           .service,      32_000, "🥐", "Bakes bread, pastries, and other goods.",                          3),
            ("Hairdresser/Barber",              .service,      32_000, "💇", "Cuts and styles hair for clients.",                                 4),
            ("Beautician/Cosmetologist",        .service,      30_000, "💄", "Provides beauty treatments and services.",                         4),
            ("Hotel Manager",                   .service,      72_000, "🏨", "Oversees hotel operations and staff.",                             5),
            ("Event Planner",                   .service,      55_000, "🎉", "Organizes events and logistics.",                                  5),
            ("Flight Attendant",                .service,      48_000, "🛫", "Ensures passenger safety and comfort.",                            3),
            ("Translator",                      .service,      48_000, "🌐", "Converts text between languages.",                                 5),
            ("Interpreter",                     .service,      52_000, "🗣️", "Provides live language interpretation.",                           5),

            // Education
            ("Elementary School Teacher",       .education,    47_000, "🏫", "Teaches basic subjects to children.",                              5),
            ("Secondary School Teacher",        .education,    50_000, "📚", "Teaches specialized subjects to teens.",                           5),

            // Health
            ("Physician",                       .health,      220_000, "🩺", "Diagnoses and treats illnesses.",                                  7),
            ("Pharmacist",                      .health,      132_000, "💊", "Dispenses medications and advises patients.",                      6),
            ("Medical Assistant",               .health,       37_000, "🩺", "Supports clinical staff with patient care.",                       4),
            ("Nursing Aide",                    .health,       30_000, "🛏️", "Assists patients with daily living tasks.",                        3),
            ("Personal Care Aide",              .health,       29_000, "🧑‍⚕️", "Assists clients with daily living activities.",                 3),
            ("Dental Assistant",                .health,       38_000, "🦷", "Supports dental professionals during procedures.",                  4),
            ("Dentist",                         .health,      160_000, "🦷", "Diagnoses and treats dental conditions.",                          7),
            ("Physiotherapist",                 .health,       65_000, "🤸", "Provides rehabilitation and physical therapy.",                    6),
            ("Occupational Therapist",          .health,       62_000, "🧰", "Helps patients regain daily living skills.",                       6),
            ("Psychologist",                    .health,       90_000, "🧠", "Studies behavior and provides therapy.",                           7),
            ("Paramedic",                       .health,       52_000, "🚑", "Provides emergency medical care.",                                 4),
            ("Veterinarian",                    .health,      105_000, "🐾", "Cares for animal health and treatments.",                          7),

            // Social
            ("Social Worker",                   .service,      48_000, "🤝", "Supports vulnerable individuals and families.",                    5),
            ("Counselor",                       .service,      56_000, "🗣️", "Provides mental health and guidance services.",                    6),

            // Technology
            ("Software Engineer",               .technology,  115_000, "💻", "Designs and implements software systems.",                         5),
            ("Data Analyst",                    .technology,   85_000, "📊", "Analyzes data to inform decisions.",                               5),
            ("Systems Administrator",           .technology,   80_000, "🖧",  "Maintains IT infrastructure.",                                     4),
            ("IT Support Specialist",           .technology,   52_000, "🛠️", "Provides technical help desk support.",                            4),
            ("Software Tester/QA",              .technology,   68_000, "🔍", "Tests software for defects and quality.",                          4),

            // Business / Finance
            ("Accountant",                      .business,     72_000, "📒", "Prepares financial records and statements.",                       5),
            ("Bookkeeper",                      .business,     44_000, "🧾", "Maintains financial transaction records.",                         4),
            ("Financial Analyst",               .business,     95_000, "💹", "Analyzes financial performance and forecasts.",                    5),
            ("Sales Manager",                   .business,     98_000, "📈", "Leads sales teams and strategies.",                                5),
            ("Marketing Specialist",            .business,     64_000, "📣", "Creates and runs marketing campaigns.",                            5),
            ("Human Resources Specialist",      .business,     62_000, "🧑‍💼", "Manages hiring and employee relations.",                        5),
            ("Recruiter",                       .business,     58_000, "🔎", "Finds and screens candidates for roles.",                          4),
            ("Project Manager",                 .business,     98_000, "📋", "Plans and oversees projects to completion.",                       5),
            ("Business Analyst",                .business,     80_000, "📈", "Analyzes business needs and recommends solutions.",                 5),
            ("Entrepreneur/Founder",            .business,     65_000, "🚀", "Starts and grows new businesses.",                                 4),

            // Construction / Trades
            ("Construction Laborer",            .construction, 36_000, "🏗️", "Performs physical tasks on construction sites.",                   2),
            ("Electrician",                     .construction, 62_000, "🔌", "Installs and repairs electrical systems.",                         4),
            ("Plumber",                         .construction, 60_000, "🚰", "Installs and repairs plumbing systems.",                           4),
            ("Carpenter",                       .construction, 52_000, "🪚", "Builds and repairs wooden structures.",                            4),
            ("Painter (Construction)",          .construction, 36_000, "🎨", "Paints buildings and interior spaces.",                            2),
            ("Mechanic",                        .manufacturing,52_000, "🔧", "Repairs vehicles and machinery.",                                  4),
            ("Automotive Technician",           .manufacturing,50_000, "🚗", "Diagnoses and services vehicles.",                                 4),

            // Logistics / Transport
            ("Truck Driver",                    .logistics,    50_000, "🚚", "Transports goods over long distances.",                            3),
            ("Bus Driver",                      .logistics,    42_000, "🚌", "Operates passenger buses on scheduled routes.",                    3),
            ("Taxi Driver",                     .logistics,    32_000, "🚕", "Provides on-demand passenger transport.",                          2),
            ("Warehouse Worker",                .logistics,    34_000, "📦", "Picks, packs, and moves warehouse inventory.",                     2),
            ("Forklift Operator",               .logistics,    36_000, "🏗️", "Operates forklifts to move goods.",                               2),

            // Aviation
            ("Pilot",                           .aviation,    155_000, "✈️", "Operates aircraft for passenger or cargo flights.",               5),

            // Law / Public Services
            ("Lawyer",                          .law,         125_000, "⚖️", "Provides legal advice and represents clients.",                    7),
            ("Paralegal",                       .law,          48_000, "📑", "Assists lawyers with research and documentation.",                  4),
            ("Judge",                           .law,         155_000, "👨‍⚖️", "Presides over court proceedings and rulings.",                   7),
            ("Police Officer",                  .publicServices,67_000,"👮", "Enforces laws and protects the public.",                           3),
            ("Firefighter",                     .publicServices,57_000,"🔥", "Responds to fires and emergencies.",                               3),

            // Science
            ("Research Scientist",              .science,      95_000, "🔬", "Conducts scientific experiments and studies.",                     7),
            ("Lab Technician",                  .science,      44_000, "🧪", "Supports laboratory testing and analysis.",                        4),
            ("Biotechnologist",                 .science,      82_000, "🧬", "Works on biological product development.",                         6),
            ("Chemist",                         .science,      72_000, "⚗️", "Performs chemical analyses and research.",                         5),
            ("Environmental Scientist",         .science,      68_000, "🌍", "Studies environmental systems and impacts.",                       5),

            // Engineering
            ("Architect",                       .engineering,  88_000, "📐", "Designs building plans and structures.",                           6),
            ("Civil Engineer",                  .engineering,  88_000, "🛣️", "Designs infrastructure and public works.",                         5),
            ("Mechanical Engineer",             .engineering,  84_000, "⚙️", "Designs mechanical systems and machinery.",                        5),
            ("Electrical Engineer",             .engineering,  86_000, "🔋", "Designs electrical systems and circuits.",                         5),
            ("Chemical Engineer",               .engineering,  82_000, "🧪", "Applies chemistry to industrial processes.",                       5),

            // Design
            ("Graphic Artist",                  .design,       50_000, "🎨", "Creates visual artwork for media.",                                4),
            ("UX/UI Designer",                  .design,       82_000, "🖥️", "Designs user interfaces and experiences.",                         5),
            ("Industrial Designer",             .design,       72_000, "🛠️", "Designs physical products and systems.",                           5),
            ("UX Researcher",                   .design,       75_000, "🔎", "Studies user behavior to inform design.",                          5),

            // Media / Writing
            ("Content Writer",                  .media,        44_000, "✍️", "Creates written content for various channels.",                    4),
            ("Journalist",                      .media,        48_000, "📰", "Reports news and stories for media outlets.",                      5),
            ("Photographer",                    .media,        40_000, "📷", "Takes photos for commercial and personal use.",                    3),

            // Agriculture
            ("Landscaper",                      .agriculture,  30_000, "🌿", "Maintains gardens and outdoor spaces.",                            1),
            ("Farmer",                          .agriculture,  32_000, "🚜", "Operates agricultural production and livestock.",                  2),
            ("Fisher",                          .agriculture,  30_000, "🎣", "Catches and processes fish and seafood.",                          1),

            // Arts / Creative
            ("Painter (Artist)",                .arts,         32_000, "🎨", "Creates original artwork for sale or exhibition.",                 1),
            ("Musician",                        .arts,         34_000, "🎵", "Performs or composes music professionally.",                       1),
            ("Actor",                           .arts,         38_000, "🎭", "Performs in theater, film, or television.",                        1),
        ]

        // MARK: - Compose final list

        var extras: [Job] = []
        for (title, cat, income, icon, summary, eqf) in titles {
            if title == "Registered Nurse" || title == "Graphic Designer" { continue }
            extras.append(fullJob(id: title, category: cat, income: income, icon: icon, summary: summary, minEQF: eqf))
        }

        var all: [Job] = [rn, dev, designer, lightDriver]
        all.append(contentsOf: extras)

        var counter = 1
        while all.count < 100 {
            let placeholder = fullJob(id: "Job Placeholder \(counter)", category: .service, income: 30_000, icon: "🧾", summary: "Placeholder job entry.", minEQF: 2)
            all.append(placeholder)
            counter += 1
        }

        return all
    }
}

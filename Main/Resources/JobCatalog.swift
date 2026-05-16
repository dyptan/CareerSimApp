import Foundation

enum JobCatalog {
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
                    outdoorAndWeatherResilience: 0,
                    collaborationAndTeamwork: 3,
                    timeManagementAndPlanning: 2,
                    selfDisciplineAndPerseverance: 2,
                    presentationAndStorytelling: 1
                ),
                hardSkills: .init(portfolioItems: [], certifications: [], licenses: [.nurse])
            )
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
                    analyticalReasoningAndProblemSolving: 3,
                    creativityAndInsightfulThinking: 2,
                    communicationAndNetworking: 2,
                    leadershipAndInfluence: 0,
                    visionaryThinkingAndAmbition: 1,
                    carefulnessAndAttentionToDetail: 3,
                    tinkeringAndFingerPrecision: 1,
                    spacialNavigationAndOrientation: 0,
                    resilienceAndEndurance: 1,
                    stressResistanceAndEmotionalRegulation: 2,
                    outdoorAndWeatherResilience: 0,
                    collaborationAndTeamwork: 3,
                    timeManagementAndPlanning: 2,
                    selfDisciplineAndPerseverance: 3,
                    presentationAndStorytelling: 1
                ),
                hardSkills: .init(portfolioItems: [.app], certifications: [], licenses: [])
            )
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
                    analyticalReasoningAndProblemSolving: 1,
                    creativityAndInsightfulThinking: 4,
                    communicationAndNetworking: 2,
                    leadershipAndInfluence: 0,
                    visionaryThinkingAndAmbition: 2,
                    carefulnessAndAttentionToDetail: 3,
                    tinkeringAndFingerPrecision: 1,
                    spacialNavigationAndOrientation: 2,
                    resilienceAndEndurance: 1,
                    stressResistanceAndEmotionalRegulation: 1,
                    outdoorAndWeatherResilience: 0,
                    collaborationAndTeamwork: 2,
                    timeManagementAndPlanning: 2,
                    selfDisciplineAndPerseverance: 2,
                    presentationAndStorytelling: 3
                ),
                hardSkills: .init(portfolioItems: [.paintingPortfolio], certifications: [], licenses: [])
            )
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
                hardSkills: .init(portfolioItems: [], certifications: [], licenses: [.drivers])
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
                    leadershipAndInfluence: 0,
                    visionaryThinkingAndAmbition: 0,
                    carefulnessAndAttentionToDetail: 1,
                    tinkeringAndFingerPrecision: 0,
                    spacialNavigationAndOrientation: 0,
                    resilienceAndEndurance: 2,
                    stressResistanceAndEmotionalRegulation: 2,
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

            case .design, .arts, .media, .fashion:
                return .init(
                    analyticalReasoningAndProblemSolving: 1,
                    creativityAndInsightfulThinking: 4,
                    communicationAndNetworking: 2,
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

            case .business, .law, .humanities, .science:
                return .init(
                    analyticalReasoningAndProblemSolving: 3,
                    creativityAndInsightfulThinking: 1,
                    communicationAndNetworking: 3,
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

            case .logistics:
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

        // Hard requirements that are intrinsic to the role — legally required
        // licences or industry-standard certs every employer expects, regardless
        // of company tier. Tier-specific extras are layered on at runtime by
        // `Job.effectiveRequirements`.
        // Strips known seniority prefixes so a "Senior Software Engineer"
        // posting still inherits hard-skill expectations from "Software Engineer".
        func baseTitle(_ title: String) -> String {
            let prefixes = [
                "Junior ", "Mid-Level ", "Senior ", "Lead ",
                "Principal ", "Staff ", "Head ", "Sous ",
                "Executive ", "Master ", "Charge ", "Postdoctoral "
            ]
            for p in prefixes where title.hasPrefix(p) {
                return String(title.dropFirst(p.count))
            }
            return title
        }

        func defaultHard(for title: String, category: JobCategory) -> HardSkills {
            switch baseTitle(title) {
            // Drivers / transport
            case "Light Truck Delivery Driver", "Taxi Driver":
                return HardSkills(licenses: [.drivers])
            case "Truck Driver", "Bus Driver":
                return HardSkills(licenses: [.cdl])
            case "Pilot":
                return HardSkills(licenses: [.commercialPilot])

            // Trades — licensed by law in most jurisdictions
            case "Electrician":
                return HardSkills(licenses: [.electrician])
            case "Plumber":
                return HardSkills(licenses: [.plumber])
            case "Architect":
                return HardSkills(licenses: [.architect])
            case "Civil Engineer", "Mechanical Engineer", "Electrical Engineer", "Chemical Engineer":
                return HardSkills(licenses: [.professionalEngineer])
            case "Mechanic", "Automotive Technician":
                return HardSkills(certifications: [.ase])

            // Health — licences + entry-level certs
            case "Registered Nurse":
                return HardSkills(licenses: [.nurse])
            case "Paramedic":
                return HardSkills(certifications: [.emt])
            case "Medical Assistant":
                return HardSkills(certifications: [.medicalAssistant])
            case "Dental Assistant":
                return HardSkills(certifications: [.dentalAssistant])
            case "Nursing Aide", "Personal Care Aide":
                return HardSkills(certifications: [.cna])

            // Law / public services
            case "Lawyer", "Judge":
                return HardSkills(licenses: [.bar])
            case "Paralegal":
                return HardSkills(certifications: [.paralegal])
            case "Firefighter":
                return HardSkills(certifications: [.emt])
            case "Security Guard":
                return HardSkills(licenses: [.securityGuard])

            // Service / hospitality
            case "Hairdresser/Barber", "Beautician/Cosmetologist":
                return HardSkills(certifications: [.cosmetology])
            case "Flight Attendant":
                return HardSkills(certifications: [.flightAttendantCert])
            case "Chef/Cook":
                return HardSkills(portfolioItems: [.recipeBook], certifications: [.culinaryDiploma])

            // Education — small/private schools want to see a sample lesson plan
            case "Elementary School Teacher", "Secondary School Teacher":
                return HardSkills(portfolioItems: [.lessonPlan], certifications: [.teachingCertificate])

            // Tech / IT — entry roles realistically open with a cert; agencies also expect a portfolio
            case "IT Support Specialist":
                return HardSkills(certifications: [.comptiaA])
            case "Software Engineer":
                return HardSkills(portfolioItems: [.library])
            case "Software Tester/QA":
                return HardSkills(portfolioItems: [.app])

            // Design — smaller studios hire on portfolio
            case "UX/UI Designer":
                return HardSkills(portfolioItems: [.website])
            case "UX Researcher":
                return HardSkills(portfolioItems: [.presentation])
            case "Industrial Designer":
                return HardSkills(portfolioItems: [.presentation])
            case "Graphic Artist":
                return HardSkills(portfolioItems: [.paintingPortfolio])

            // Visual arts / music
            case "Painter (Artist)":
                return HardSkills(portfolioItems: [.paintingPortfolio])
            case "Musician":
                return HardSkills(portfolioItems: [.musicAlbum])
            case "Photographer":
                return HardSkills(portfolioItems: [.photoPortfolio])

            // Writing / research — clips, drafts, published papers
            case "Content Writer", "Journalist":
                return HardSkills(portfolioItems: [.paper])
            case "Research Scientist":
                return HardSkills(portfolioItems: [.paper])

            // Agriculture — pesticides require a state applicator licence
            case "Farmer":
                return HardSkills(licenses: [.pesticideApplicator])

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
            case "Entrepreneur/Founder":
                return 2
            case "Judge":
                return 10
            case "Lawyer":
                return 2
            case "Physician", "Dentist", "Veterinarian", "Psychologist":
                return 2
            case "Pilot":
                return 3
            case "Research Scientist":
                return 3
            case "Architect":
                return 4
            default:
                return 0
            }
        }

        func fullJob(id: String, category: JobCategory, income: Int, icon: String, summary: String, minEQF: Int, minYears: Int? = nil) -> Job {
            let soft = defaultSoft(for: category)
            let hard = defaultHard(for: id, category: category)
            let edu = Job.Requirements.Education(minEQF: minEQF, acceptedProfiles: nil)
            let req = Job.Requirements(
                education: edu,
                softSkills: soft,
                hardSkills: hard,
                minYearsExperience: minYears ?? defaultExperience(for: id)
            )
            return Job(id: id, category: category, income: income, summary: summary, icon: icon, requirements: req)
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
            ("Medical Assistant",               .health,       37_000, "🩺", "Supports clinical staff with patient care.",                       3),
            ("Nursing Aide",                    .health,       30_000, "🛏️", "Assists patients with daily living tasks.",                        3),
            ("Personal Care Aide",              .health,       29_000, "🧑‍⚕️", "Assists clients with daily living activities.",                 3),
            ("Dental Assistant",                .health,       38_000, "🦷", "Supports dental professionals during procedures.",                  3),
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
            ("IT Support Specialist",           .technology,   52_000, "🛠️", "Provides technical help desk support.",                            3),
            ("Software Tester/QA",              .technology,   68_000, "🔍", "Tests software for defects and quality.",                          3),

            // Business / Finance
            ("Accountant",                      .business,     72_000, "📒", "Prepares financial records and statements.",                       5),
            ("Bookkeeper",                      .business,     44_000, "🧾", "Maintains financial transaction records.",                         3),
            ("Financial Analyst",               .business,     95_000, "💹", "Analyzes financial performance and forecasts.",                    5),
            ("Sales Manager",                   .business,     98_000, "📈", "Leads sales teams and strategies.",                                5),
            ("Marketing Specialist",            .business,     64_000, "📣", "Creates and runs marketing campaigns.",                            5),
            ("Human Resources Specialist",      .business,     62_000, "🧑‍💼", "Manages hiring and employee relations.",                        5),
            ("Recruiter",                       .business,     58_000, "🔎", "Finds and screens candidates for roles.",                          3),
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
            ("Paralegal",                       .law,          48_000, "📑", "Assists lawyers with research and documentation.",                  3),
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

        // MARK: - Seniority ladders
        // Explicit (id, category, income, icon, summary, minEQF, minYears) so
        // the same role appears at multiple seniority levels with realistic
        // salary and experience progression. Hard-skill requirements are
        // inherited from the base role via `baseTitle(...)`.
        let seniorityTitles: [(String, JobCategory, Int, String, String, Int, Int)] = [
            // Technology
            ("Junior Software Engineer",     .technology,    78_000, "💻", "Entry-level developer learning the codebase and shipping small features.",        5, 0),
            ("Senior Software Engineer",     .technology,   155_000, "💻", "Owns major systems, mentors peers, and drives technical direction.",             5, 5),
            ("Staff Software Engineer",      .technology,   200_000, "💻", "Sets engineering strategy across teams and unblocks complex initiatives.",       6, 9),
            ("Principal Software Engineer",  .technology,   245_000, "💻", "Top-of-ladder IC; defines architecture for the whole organization.",            6, 12),
            ("Junior Data Analyst",          .technology,    62_000, "📊", "Builds basic dashboards and runs ad-hoc queries under supervision.",              5, 0),
            ("Senior Data Analyst",          .technology,   118_000, "📊", "Owns analytical workstreams and partners with leadership on decisions.",          5, 4),
            ("Senior Systems Administrator", .technology,   110_000, "🖧",  "Architects infrastructure and leads incident response.",                          4, 5),

            // Design
            ("Junior UX/UI Designer",        .design,        60_000, "🖥️", "Produces wireframes and visual assets under senior direction.",                  5, 0),
            ("Senior UX/UI Designer",        .design,       120_000, "🖥️", "Leads end-to-end design of major product surfaces.",                              5, 5),
            ("Lead UX/UI Designer",          .design,       155_000, "🖥️", "Sets design vision and mentors the design team.",                                 5, 8),
            ("Junior Graphic Artist",        .design,        36_000, "🎨", "Produces assets to spec under art-director review.",                              4, 0),
            ("Senior Graphic Artist",        .design,        72_000, "🎨", "Owns visual identity work and directs junior artists.",                           4, 4),

            // Engineering disciplines
            ("Junior Civil Engineer",        .engineering,   64_000, "🛣️", "Drafts plans and supports senior engineers on site.",                             5, 0),
            ("Senior Civil Engineer",        .engineering,  125_000, "🛣️", "Leads infrastructure projects and signs off on designs.",                         5, 6),
            ("Junior Mechanical Engineer",   .engineering,   62_000, "⚙️", "Assists in design and analysis of mechanical components.",                        5, 0),
            ("Senior Mechanical Engineer",   .engineering,  120_000, "⚙️", "Owns mechanical design projects end-to-end.",                                     5, 6),
            ("Junior Electrical Engineer",   .engineering,   64_000, "🔋", "Supports design and testing of electrical systems.",                              5, 0),
            ("Senior Electrical Engineer",   .engineering,  122_000, "🔋", "Leads electrical-system architecture for complex products.",                      5, 6),

            // Business / Finance
            ("Junior Accountant",            .business,      52_000, "📒", "Books transactions and supports month-end close.",                                5, 0),
            ("Senior Accountant",            .business,     105_000, "📒", "Owns ledger areas and supervises junior accountants.",                            5, 4),
            ("Junior Financial Analyst",     .business,      68_000, "💹", "Builds forecasting models with senior oversight.",                                5, 0),
            ("Senior Financial Analyst",     .business,     140_000, "💹", "Partners with executives on capital planning and strategy.",                      5, 5),
            ("Junior Business Analyst",      .business,      58_000, "📈", "Gathers requirements and documents processes.",                                   5, 0),
            ("Senior Business Analyst",      .business,     115_000, "📈", "Leads cross-functional analysis and drives recommendations.",                     5, 4),
            ("Junior Marketing Specialist",  .business,      46_000, "📣", "Executes campaigns under direction from senior marketers.",                       5, 0),
            ("Senior Marketing Specialist",  .business,      94_000, "📣", "Owns marketing programs and reports on impact.",                                  5, 4),
            ("Marketing Director",           .business,     145_000, "📣", "Leads the marketing function and brand strategy.",                                5, 8),
            ("Senior Project Manager",       .business,     145_000, "📋", "Manages portfolios of projects and senior stakeholders.",                         5, 7),
            ("Senior Sales Manager",         .business,     150_000, "📈", "Runs regional sales orgs and hits aggressive targets.",                           5, 7),

            // Law
            ("Junior Paralegal",             .law,           38_000, "📑", "Files documents and supports research for senior staff.",                         3, 0),
            ("Senior Paralegal",             .law,           65_000, "📑", "Manages caseload research and trains junior paralegals.",                         3, 4),
            ("Senior Lawyer (Partner)",      .law,          220_000, "⚖️", "Equity partner driving client relationships and firm strategy.",                  7, 8),

            // Health
            ("Senior Registered Nurse",      .health,       110_000, "🩺", "Experienced floor nurse mentoring newer staff.",                                  5, 5),
            ("Charge Nurse",                 .health,       130_000, "🩺", "Coordinates the nursing shift and triages escalations.",                          5, 8),

            // Science
            ("Postdoctoral Researcher",      .science,       62_000, "🔬", "Time-limited research role following doctoral studies.",                          7, 0),
            ("Senior Research Scientist",    .science,      145_000, "🔬", "Leads research programs and publishes original work.",                            7, 6),
            ("Principal Research Scientist", .science,      195_000, "🔬", "Sets research agenda for the lab and supervises projects.",                       7, 10),

            // Hospitality (chef ladder)
            ("Sous Chef",                    .service,       65_000, "👨‍🍳", "Second-in-command in the kitchen, runs daily service.",                          4, 3),
            ("Head Chef",                    .service,       92_000, "👨‍🍳", "Owns menu, sourcing, and kitchen leadership.",                                   4, 6),
            ("Executive Chef",               .service,      140_000, "👨‍🍳", "Oversees multiple kitchens and culinary brand.",                                 4, 10),

            // Public services
            ("Police Sergeant",              .publicServices, 88_000, "👮", "Supervises a squad of officers in the field.",                                    3, 5),
            ("Police Lieutenant",            .publicServices,110_000, "👮", "Commands a precinct shift and oversees sergeants.",                               3, 10),
            ("Fire Captain",                 .publicServices, 90_000, "🚒", "Leads a firefighting crew on emergency response.",                                3, 8),

            // Construction trades
            ("Master Electrician",           .construction,  92_000, "🔌", "Licensed master responsible for jobs and apprentices.",                            4, 5),
            ("Master Plumber",               .construction,  88_000, "🚰", "Licensed master plumber leading complex installations.",                           4, 5),
            ("Master Carpenter",             .construction,  76_000, "🪚", "Master tradesperson on bespoke and large-scale builds.",                           4, 6),
        ]

        for (title, cat, income, icon, summary, eqf, years) in seniorityTitles {
            extras.append(fullJob(id: title, category: cat, income: income, icon: icon, summary: summary, minEQF: eqf, minYears: years))
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

// HardcodedJobs.swift
import Foundation

enum JobExamples {
    static func sampleJobs() -> [Job] {
        // Start with the existing example jobs
        let rn = Job(
            id: "Registered Nurse",
            category: .health,
            income: 72_000,
            summary: "Provides patient care, administers medication, and coordinates with medical teams.",
            icon: "🩺",
            requirements: .init(
                education: .init(minEQF: 6, acceptedProfiles: [.health, .science]),
                softSkills: .init(
                    analyticalReasoningAndProblemSolving: 3,
                    creativityAndInsightfulThinking: 0,
                    communicationAndNetworking: 5,
                    leadershipAndInfluence: 1,
                    courageAndRiskTolerance: 1,
                    carefulnessAndAttentionToDetail: 5,
                    tinkeringAndFingerPrecision: 2,
                    spacialNavigationAndOrientation: 0,
                    resilienceAndEndurance: 4,
                    stressResistanceAndEmotionalRegulation: 0,
                    outdoorAndWeatherResilience: 0,
                    patienceAndPerseverance: 0,
                    collaborationAndTeamwork: 0,
                    timeManagementAndPlanning: 0,
                    selfDisciplineAndPerseverance: 0,
                    presentationAndStorytelling: 0
                ),
                hardSkills: .init(
                    portfolioItems: [],
                    certifications: [],
                    software: [],
                    licenses: []
                )
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
                    communicationAndNetworking: 2,
                    leadershipAndInfluence: 0,
                    courageAndRiskTolerance: 1,
                    carefulnessAndAttentionToDetail: 4,
                    tinkeringAndFingerPrecision: 0,
                    spacialNavigationAndOrientation: 0,
                    resilienceAndEndurance: 2,
                    stressResistanceAndEmotionalRegulation: 0,
                    outdoorAndWeatherResilience: 0,
                    patienceAndPerseverance: 0,
                    collaborationAndTeamwork: 0,
                    timeManagementAndPlanning: 0,
                    selfDisciplineAndPerseverance: 0,
                    presentationAndStorytelling: 0
                ),
                hardSkills: .init(
                    portfolioItems: [],
                    certifications: [],
                    software: [],
                    licenses: []
                )
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
                education: .init(minEQF: 4, acceptedProfiles: nil),
                softSkills: .init(
                    analyticalReasoningAndProblemSolving: 1,
                    creativityAndInsightfulThinking: 5,
                    communicationAndNetworking: 2,
                    leadershipAndInfluence: 0,
                    courageAndRiskTolerance: 1,
                    carefulnessAndAttentionToDetail: 4,
                    tinkeringAndFingerPrecision: 2,
                    spacialNavigationAndOrientation: 3,
                    resilienceAndEndurance: 1,
                    stressResistanceAndEmotionalRegulation: 0,
                    outdoorAndWeatherResilience: 0,
                    patienceAndPerseverance: 0,
                    collaborationAndTeamwork: 0,
                    timeManagementAndPlanning: 0,
                    selfDisciplineAndPerseverance: 0,
                    presentationAndStorytelling: 0
                ),
                hardSkills: .init(
                    portfolioItems: [],
                    certifications: [],
                    software: [],
                    licenses: []
                )
            ),
            companyTier: .mid,
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
                    communicationAndNetworking: 1,
                    leadershipAndInfluence: 0,
                    courageAndRiskTolerance: 1,
                    carefulnessAndAttentionToDetail: 3,
                    tinkeringAndFingerPrecision: 1,
                    spacialNavigationAndOrientation: 3,
                    resilienceAndEndurance: 3,
                    stressResistanceAndEmotionalRegulation: 0,
                    outdoorAndWeatherResilience: 0,
                    patienceAndPerseverance: 0,
                    collaborationAndTeamwork: 0,
                    timeManagementAndPlanning: 0,
                    selfDisciplineAndPerseverance: 0,
                    presentationAndStorytelling: 0
                ),
                hardSkills: .init(
                    portfolioItems: [],
                    certifications: [],
                    software: [],
                    licenses: []
                )
            ),
            companyTier: .mid,
            version: 6
        )

        // Additional hardcoded job titles (minimal entries).
        // We'll create a list of 100 jobs in total by adding many concise Job instances.

        // Helper that builds a full Job with detailed softSkills and hardSkills
        func defaultSoft(for category: JobCategory) -> SoftSkills {
            switch category {
            case .technology, .engineering:
                return .init(
                    analyticalReasoningAndProblemSolving: 5,
                    creativityAndInsightfulThinking: 3,
                    communicationAndNetworking: 2,
                    leadershipAndInfluence: 1,
                    courageAndRiskTolerance: 1,
                    carefulnessAndAttentionToDetail: 4,
                    tinkeringAndFingerPrecision: 2,
                    spacialNavigationAndOrientation: 0,
                    resilienceAndEndurance: 2,
                    stressResistanceAndEmotionalRegulation: 0,
                    outdoorAndWeatherResilience: 0,
                    patienceAndPerseverance: 0,
                    collaborationAndTeamwork: 0,
                    timeManagementAndPlanning: 0,
                    selfDisciplineAndPerseverance: 0,
                    presentationAndStorytelling: 0
                )
            case .health, .education:
                return .init(
                    analyticalReasoningAndProblemSolving: 3,
                    creativityAndInsightfulThinking: 1,
                    communicationAndNetworking: 5,
                    leadershipAndInfluence: 2,
                    courageAndRiskTolerance: 2,
                    carefulnessAndAttentionToDetail: 5,
                    tinkeringAndFingerPrecision: 1,
                    spacialNavigationAndOrientation: 0,
                    resilienceAndEndurance: 4,
                    stressResistanceAndEmotionalRegulation: 0,
                    outdoorAndWeatherResilience: 0,
                    patienceAndPerseverance: 0,
                    collaborationAndTeamwork: 0,
                    timeManagementAndPlanning: 0,
                    selfDisciplineAndPerseverance: 0,
                    presentationAndStorytelling: 0
                )
            case .service, .hospitality, .retail, .tourism:
                return .init(
                    analyticalReasoningAndProblemSolving: 1,
                    creativityAndInsightfulThinking: 2,
                    communicationAndNetworking: 4,
                    leadershipAndInfluence: 1,
                    courageAndRiskTolerance: 1,
                    carefulnessAndAttentionToDetail: 2,
                    tinkeringAndFingerPrecision: 0,
                    spacialNavigationAndOrientation: 1,
                    resilienceAndEndurance: 3,
                    stressResistanceAndEmotionalRegulation: 0,
                    outdoorAndWeatherResilience: 0,
                    patienceAndPerseverance: 0,
                    collaborationAndTeamwork: 0,
                    timeManagementAndPlanning: 0,
                    selfDisciplineAndPerseverance: 0,
                    presentationAndStorytelling: 0
                )
            case .construction, .manufacturing, .automotive:
                return .init(
                    analyticalReasoningAndProblemSolving: 2,
                    creativityAndInsightfulThinking: 1,
                    communicationAndNetworking: 1,
                    leadershipAndInfluence: 1,
                    courageAndRiskTolerance: 2,
                    carefulnessAndAttentionToDetail: 3,
                    tinkeringAndFingerPrecision: 3,
                    spacialNavigationAndOrientation: 2,
                    resilienceAndEndurance: 4,
                    stressResistanceAndEmotionalRegulation: 0,
                    outdoorAndWeatherResilience: 0,
                    patienceAndPerseverance: 0,
                    collaborationAndTeamwork: 0,
                    timeManagementAndPlanning: 0,
                    selfDisciplineAndPerseverance: 0,
                    presentationAndStorytelling: 0
                )
            case .design, .arts, .media, .fashion:
                return .init(
                    analyticalReasoningAndProblemSolving: 2,
                    creativityAndInsightfulThinking: 5,
                    communicationAndNetworking: 3,
                    leadershipAndInfluence: 1,
                    courageAndRiskTolerance: 2,
                    carefulnessAndAttentionToDetail: 3,
                    tinkeringAndFingerPrecision: 2,
                    spacialNavigationAndOrientation: 1,
                    resilienceAndEndurance: 2,
                    stressResistanceAndEmotionalRegulation: 0,
                    outdoorAndWeatherResilience: 0,
                    patienceAndPerseverance: 0,
                    collaborationAndTeamwork: 0,
                    timeManagementAndPlanning: 0,
                    selfDisciplineAndPerseverance: 0,
                    presentationAndStorytelling: 0
                )
            case .business, .law, .humanities, .science:
                return .init(
                    analyticalReasoningAndProblemSolving: 4,
                    creativityAndInsightfulThinking: 2,
                    communicationAndNetworking: 4,
                    leadershipAndInfluence: 3,
                    courageAndRiskTolerance: 1,
                    carefulnessAndAttentionToDetail: 4,
                    tinkeringAndFingerPrecision: 0,
                    spacialNavigationAndOrientation: 0,
                    resilienceAndEndurance: 2,
                    stressResistanceAndEmotionalRegulation: 0,
                    outdoorAndWeatherResilience: 0,
                    patienceAndPerseverance: 0,
                    collaborationAndTeamwork: 0,
                    timeManagementAndPlanning: 0,
                    selfDisciplineAndPerseverance: 0,
                    presentationAndStorytelling: 0
                )
            case .logistics:
                return .init(
                    analyticalReasoningAndProblemSolving: 2,
                    creativityAndInsightfulThinking: 1,
                    communicationAndNetworking: 2,
                    leadershipAndInfluence: 1,
                    courageAndRiskTolerance: 1,
                    carefulnessAndAttentionToDetail: 3,
                    tinkeringAndFingerPrecision: 1,
                    spacialNavigationAndOrientation: 4,
                    resilienceAndEndurance: 3,
                    stressResistanceAndEmotionalRegulation: 0,
                    outdoorAndWeatherResilience: 0,
                    patienceAndPerseverance: 0,
                    collaborationAndTeamwork: 0,
                    timeManagementAndPlanning: 0,
                    selfDisciplineAndPerseverance: 0,
                    presentationAndStorytelling: 0
                )
            case .agriculture, .maritime:
                return .init(
                    analyticalReasoningAndProblemSolving: 1,
                    creativityAndInsightfulThinking: 1,
                    communicationAndNetworking: 1,
                    leadershipAndInfluence: 1,
                    courageAndRiskTolerance: 2,
                    carefulnessAndAttentionToDetail: 2,
                    tinkeringAndFingerPrecision: 1,
                    spacialNavigationAndOrientation: 1,
                    resilienceAndEndurance: 5,
                    stressResistanceAndEmotionalRegulation: 0,
                    outdoorAndWeatherResilience: 0,
                    patienceAndPerseverance: 0,
                    collaborationAndTeamwork: 0,
                    timeManagementAndPlanning: 0,
                    selfDisciplineAndPerseverance: 0,
                    presentationAndStorytelling: 0
                )
            default:
                return .init(
                    analyticalReasoningAndProblemSolving: 1,
                    creativityAndInsightfulThinking: 1,
                    communicationAndNetworking: 1,
                    leadershipAndInfluence: 0,
                    courageAndRiskTolerance: 0,
                    carefulnessAndAttentionToDetail: 1,
                    tinkeringAndFingerPrecision: 0,
                    spacialNavigationAndOrientation: 0,
                    resilienceAndEndurance: 1,
                    stressResistanceAndEmotionalRegulation: 0,
                    outdoorAndWeatherResilience: 0,
                    patienceAndPerseverance: 0,
                    collaborationAndTeamwork: 0,
                    timeManagementAndPlanning: 0,
                    selfDisciplineAndPerseverance: 0,
                    presentationAndStorytelling: 0
                )
            }
        }

        func defaultHard(for title: String, category: JobCategory) -> HardSkills {
            // Local variables changed to sets but unused for now
            let certs: Set<String> = []
            let licenses: Set<String> = []
            let software: Set<String> = []
            let portfolioItems: Set<String> = []

            // Return with empty sets matching new initializer
            return .init(portfolioItems: [], certifications: [], software: [], licenses: [])
        }

        func companyTierFor(income: Int, category: JobCategory) -> CompanyTier {
            if category == .publicServices || category == .education || category == .health { return .government }
            if income >= 100_000 { return .enterprise }
            if income >= 60_000 { return .mid }
            return .startup
        }

        func fullJob(id: String, category: JobCategory, income: Int, icon: String, summary: String, minEQF: Int) -> Job {
            let soft = defaultSoft(for: category)
            let hard = defaultHard(for: id, category: category)
            let edu = Job.Requirements.Education(minEQF: minEQF, acceptedProfiles: nil)
            let req = Job.Requirements(education: edu, softSkills: soft, hardSkills: hard)
            return Job(id: id, category: category, income: income, summary: summary, icon: icon, requirements: req, companyTier: companyTierFor(income: income, category: category), version: 6)
        }

        // List of common job titles (expanded to reach roughly 100 entries)
        let titles: [(String, JobCategory, Int, String, String, Int)] = [
            ("Retail Salesperson", .service, 28_000, "🛍️", "Sells products directly to customers.", 2),
            ("Cashier", .service, 24_000, "💳", "Handles customer payments and transactions.", 2),
            ("Office Clerk", .service, 30_000, "🗂️", "Performs general administrative duties.", 2),
            ("Customer Service Representative", .service, 35_000, "☎️", "Assists customers with inquiries and support.", 3),
            ("Waiter/Waitress", .service, 22_000, "🍽️", "Serves food and beverages to customers.", 2),
            ("Food Preparation Worker", .service, 23_000, "🍳", "Prepares ingredients and supports kitchen staff.", 2),
            ("Security Guard", .service, 30_000, "🛡️", "Protects property and ensures safety.", 2),
            ("Janitor/Cleaner", .service, 25_000, "🧹", "Maintains cleanliness of buildings and facilities.", 1),
            ("Elementary School Teacher", .education, 45_000, "🏫", "Teaches basic subjects to children.", 5),
            ("Secondary School Teacher", .education, 48_000, "📚", "Teaches specialized subjects to teens.", 5),
            ("Registered Nurse", .health, 72_000, "🩺", "[duplicate placeholder]", 6),
            ("Physician", .health, 160_000, "🩺", "Diagnoses and treats illnesses.", 7),
            ("Pharmacist", .health, 120_000, "💊", "Dispenses medications and advises patients.", 6),
            ("Medical Assistant", .health, 35_000, "🩺", "Supports clinical staff with patient care.", 3),
            ("Nursing Aide", .health, 28_000, "🛏️", "Assists patients with daily living tasks.", 2),
            ("Software Engineer", .technology, 115_000, "💻", "Designs and implements software systems.", 5),
            ("Data Analyst", .technology, 85_000, "📊", "Analyzes data to inform decisions.", 5),
            ("Systems Administrator", .technology, 80_000, "🖧", "Maintains IT infrastructure.", 4),
            ("IT Support Specialist", .technology, 50_000, "🛠️", "Provides technical help desk support.", 3),
            ("Software Tester/QA", .technology, 65_000, "🔍", "Tests software for defects and quality.", 4),
            ("Accountant", .business, 70_000, "📒", "Prepares financial records and statements.", 5),
            ("Bookkeeper", .business, 40_000, "🧾", "Maintains financial transaction records.", 3),
            ("Financial Analyst", .business, 95_000, "💹", "Analyzes financial performance and forecasts.", 5),
            ("Receptionist", .service, 28_000, "📞", "Greets visitors and manages front-desk tasks.", 2),
            ("Construction Laborer", .construction, 35_000, "🏗️", "Performs physical tasks on construction sites.", 2),
            ("Electrician", .construction, 60_000, "🔌", "Installs and repairs electrical systems.", 3),
            ("Plumber", .construction, 58_000, "🚰", "Installs and repairs plumbing systems.", 3),
            ("Carpenter", .construction, 50_000, "🪚", "Builds and repairs wooden structures.", 2),
            ("Truck Driver", .logistics, 45_000, "🚚", "Transports goods over long distances.", 2),
            ("Bus Driver", .logistics, 40_000, "🚌", "Operates passenger buses on scheduled routes.", 2),
            ("Taxi Driver", .logistics, 30_000, "🚕", "Provides on-demand passenger transport.", 1),
            ("Pilot", .aviation, 130_000, "✈️", "Operates aircraft for passenger or cargo flights.", 6),
            ("Flight Attendant", .service, 45_000, "🛫", "Ensures passenger safety and comfort.", 3),
            ("Hotel Manager", .service, 65_000, "🏨", "Oversees hotel operations and staff.", 4),
            ("Event Planner", .service, 50_000, "🎉", "Organizes events and logistics.", 4),
            ("Sales Manager", .business, 95_000, "📈", "Leads sales teams and strategies.", 5),
            ("Marketing Specialist", .business, 60_000, "📣", "Creates and runs marketing campaigns.", 4),
            ("Human Resources Specialist", .business, 58_000, "🧑‍💼", "Manages hiring and employee relations.", 4),
            ("Recruiter", .business, 55_000, "🔎", "Finds and screens candidates for roles.", 3),
            ("Warehouse Worker", .logistics, 27_000, "📦", "Picks, packs, and moves warehouse inventory.", 1),
            ("Forklift Operator", .logistics, 34_000, "🏗️", "Operates forklifts to move goods.", 2),
            ("Mechanic", .manufacturing, 48_000, "🔧", "Repairs vehicles and machinery.", 3),
            ("Automotive Technician", .manufacturing, 46_000, "🚗", "Diagnoses and services vehicles.", 3),
            ("Chef/Cook", .service, 38_000, "👨‍🍳", "Prepares meals in restaurants or institutions.", 2),
            ("Baker", .service, 30_000, "🥐", "Bakes bread, pastries, and other goods.", 2),
            ("Graphic Artist", .design, 48_000, "🎨", "Creates visual artwork for media.", 4),
            ("UX/UI Designer", .design, 80_000, "🖥️", "Designs user interfaces and experiences.", 5),
            ("Industrial Designer", .design, 70_000, "🛠️", "Designs physical products and systems.", 5),
            ("Painter (Construction)", .construction, 32_000, "🎨", "Paints buildings and interior spaces.", 1),
            ("Landscaper", .agriculture, 29_000, "🌿", "Maintains gardens and outdoor spaces.", 1),
            ("Farmer", .agriculture, 30_000, "🚜", "Operates agricultural production and livestock.", 2),
            ("Fisher", .agriculture, 28_000, "🎣", "Catches and processes fish and seafood.", 1),
            ("Hairdresser/Barber", .service, 28_000, "💇", "Cuts and styles hair for clients.", 2),
            ("Beautician/Cosmetologist", .service, 27_000, "💄", "Provides beauty treatments and services.", 2),
            ("Personal Care Aide", .health, 26_000, "🧑‍⚕️", "Assists clients with daily living activities.", 1),
            ("Dental Assistant", .health, 34_000, "🦷", "Supports dental professionals during procedures.", 3),
            ("Dentist", .health, 140_000, "🦷", "Diagnoses and treats dental conditions.", 7),
            ("Physiotherapist", .health, 60_000, "🤸", "Provides rehabilitation and physical therapy.", 6),
            ("Occupational Therapist", .health, 58_000, "🧰", "Helps patients regain daily living skills.", 6),
            ("Social Worker", .service, 45_000, "🤝", "Supports vulnerable individuals and families.", 5),
            ("Counselor", .service, 50_000, "🗣️", "Provides mental health and guidance services.", 5),
            ("Psychologist", .health, 75_000, "🧠", "Studies behavior and provides therapy.", 6),
            ("Lawyer", .law, 120_000, "⚖️", "Provides legal advice and represents clients.", 7),
            ("Paralegal", .law, 45_000, "📑", "Assists lawyers with research and documentation.", 4),
            ("Judge", .law, 150_000, "👨‍⚖️", "Presides over court proceedings and rulings.", 7),
            ("Police Officer", .service, 55_000, "👮", "Enforces laws and protects the public.", 3),
            ("Firefighter", .service, 50_000, "🔥", "Responds to fires and emergencies.", 3),
            ("Paramedic", .health, 48_000, "🚑", "Provides emergency medical care.", 4),
            ("Veterinarian", .health, 85_000, "🐾", "Cares for animal health and treatments.", 6),
            ("Research Scientist", .science, 85_000, "🔬", "Conducts scientific experiments and studies.", 6),
            ("Lab Technician", .science, 40_000, "🧪", "Supports laboratory testing and analysis.", 3),
            ("Biotechnologist", .science, 78_000, "🧬", "Works on biological product development.", 6),
            ("Chemist", .science, 70_000, "⚗️", "Performs chemical analyses and research.", 6),
            ("Environmental Scientist", .science, 65_000, "🌍", "Studies environmental systems and impacts.", 5),
            ("Architect", .engineering, 85_000, "📐", "Designs building plans and structures.", 6),
            ("Civil Engineer", .engineering, 88_000, "🛣️", "Designs infrastructure and public works.", 6),
            ("Mechanical Engineer", .engineering, 82_000, "⚙️", "Designs mechanical systems and machinery.", 6),
            ("Electrical Engineer", .engineering, 84_000, "🔋", "Designs electrical systems and circuits.", 6),
            ("Chemical Engineer", .engineering, 80_000, "🧪", "Applies chemistry to industrial processes.", 6),
            ("Project Manager", .business, 95_000, "📋", "Plans and oversees projects to completion.", 5),
            ("Business Analyst", .business, 78_000, "📈", "Analyzes business needs and recommends solutions.", 5),
            ("Entrepreneur/Founder", .business, 60_000, "🚀", "Starts and grows new businesses.", 4),
            ("Content Writer", .media, 42_000, "✍️", "Creates written content for various channels.", 3),
            ("Journalist", .media, 44_000, "📰", "Reports news and stories for media outlets.", 4),
            ("Photographer", .media, 38_000, "📷", "Takes photos for commercial and personal use.", 3),
            ("Translator", .service, 40_000, "🌐", "Converts text between languages.", 4),
            ("Interpreter", .service, 45_000, "🗣️", "Provides live language interpretation.", 4),
            ("Graphic Designer", .design, 53_000, "🎨", "[duplicate placeholder]", 4),
            ("UX Researcher", .design, 72_000, "🔎", "Studies user behavior to inform design.", 5),
            ("Painter (Artist)", .arts, 30_000, "🎨", "Creates original artwork for sale or exhibition.", 1),
            ("Musician", .arts, 32_000, "🎵", "Performs or composes music professionally.", 1),
            ("Actor", .arts, 35_000, "🎭", "Performs in theater, film, or television.", 1)
        ]

        // Build Job instances from the titles list using fullJob builder
        var extras: [Job] = []
        for (title, cat, income, icon, summary, eqf) in titles {
            // Avoid duplicating the exact Registered Nurse and Graphic Designer already defined
            if title == "Registered Nurse" || title == "Graphic Designer" {
                continue
            }
            // map some previously-incorrect categories to valid ones (defensive)
            var category = cat
            switch cat {
            case .service: category = .service
            default: break
            }
            extras.append(fullJob(id: title, category: category, income: income, icon: icon, summary: summary, minEQF: eqf))
        }

        // Compose final list (keep original examples first)
        var all: [Job] = [rn, dev, designer, lightDriver]
        all.append(contentsOf: extras)

        // If we have fewer than 100 jobs, add generic placeholders until reaching 100
        var counter = 1
        while all.count < 100 {
            let placeholder = fullJob(id: "Job Placeholder \(counter)", category: .service, income: 30_000, icon: "🧾", summary: "Placeholder job entry.", minEQF: 2)
            all.append(placeholder)
            counter += 1
        }

        return all
    }
}

enum JobCategory: String, CaseIterable, Identifiable, Codable {
    case engineering = "Engineering"
    /// Entertainment and the spotlight: performing arts, media/creators, and
    /// professional sports — merged from the former Arts, Media, and Sports.
    case showBusiness = "Show Business"
    case publicServices = "Public Services"
    case health = "Health"
    case technology = "Technology"
    case education = "Education"
    case agriculture = "Agriculture"
    case design = "Design"
    case gaming = "Gaming"
    case language = "Language"
    case tourism = "Tourism"
    case law = "Law"
    case business = "Business"
    case construction = "Construction"
    case automotive = "Automotive"
    case aviation = "Aviation"
    case maritime = "Maritime"
    case logistics = "Logistics"
    case retail = "Retail"
    case science = "Science"
    case hospitality = "Hospitality"
    case fashion = "Fashion"
    case service = "Personal Services"
    case manufacturing = "Manufacturing"
    case finance = "Finance"
    case entrepreneurship = "Entrepreneurship"
    case transportation = "Transportation"
    case administration = "Administration"

    var id: String { rawValue }

    /// Maximum fractional swing above or below the base salary in a single year.
    /// e.g. 0.5 means actual pay can range from 50 % to 150 % of the base.
    var salaryVariance: Double {
        switch self {
        case .entrepreneurship:
            return 0.55   // founder income swings wildly with the venture
        case .showBusiness, .fashion:
            return 0.50   // heavily project-based / performance-driven
        case .technology, .engineering, .aviation, .science, .gaming:
            return 0.40   // bonuses, stock, market swings
        case .business, .law, .finance:
            return 0.40
        case .construction, .manufacturing, .automotive, .maritime:
            return 0.30   // seasonal and contract variability
        case .agriculture, .logistics, .transportation, .retail, .service, .hospitality, .tourism:
            return 0.30
        case .health, .education, .publicServices:
            return 0.10   // salaried / regulated
        default:
            return 0.20
        }
    }

    /// Cyclical, discretionary-spending sectors that are hit hardest in a bear
    /// market: travel, dining, entertainment, and consumer retail are the first
    /// budgets households and advertisers cut. Used to freeze hiring in these
    /// industries during an economic downturn (see `Player.applyEconomicTurmoil`).
    var isCyclical: Bool {
        switch self {
        case .hospitality, .tourism, .retail, .showBusiness, .fashion, .entrepreneurship:
            return true
        default:
            return false
        }
    }

    /// Safety-critical / regulated fields with a low tolerance for risk, where a
    /// role's certifications are a HARD hiring requirement at *every* employer
    /// (not just formal ones) — you can't legally or safely practise without the
    /// credential. Required licences are always enforced regardless; this adds
    /// the certification gate for these fields. Other fields hire on demonstrated
    /// portfolio work instead (see `Job.hardSkillsMet`).
    var requiresCredentials: Bool {
        switch self {
        case .health, .transportation, .aviation, .maritime,
             .law, .publicServices, .construction:
            return true
        default:
            return false
        }
    }

    /// Professions where a formal degree is legally or practically mandatory to
    /// practise — you can't be a doctor, lawyer, engineer, scientist, or teacher
    /// without the qualification, so education stays a HARD hiring gate here. In
    /// every other field a degree only improves the odds (it's folded into the
    /// hire-probability score via `Job.educationFitTerm`) but never blocks an
    /// application — talent, portfolio, and experience can stand in for it.
    var educationIsMandatory: Bool {
        switch self {
        case .health, .law, .engineering, .science, .education:
            return true
        default:
            return false
        }
    }

    /// Other industries whose accumulated work experience *also* counts toward
    /// roles in this category. Business and Entrepreneurship credit each other:
    /// running your own venture builds the same commercial acumen a Business
    /// employer values, and years spent in Business roles read as founder
    /// experience when you set out on your own. See `Player.industryExperience`
    /// and `Job.relevantYears`.
    var creditedExperienceCategories: Set<JobCategory> {
        switch self {
        case .business:         return [.entrepreneurship]
        case .entrepreneurship: return [.business]
        default:                return []
        }
    }

    static func icon(for category: JobCategory) -> String {
        switch category {
        case .engineering: return "🧰"
        case .technology: return "💻"
        case .showBusiness: return "🎬"
        case .publicServices: return "🛟"
        case .health: return "🩺"
        case .education: return "📚"
        case .agriculture: return "🌾"
        case .design: return "🖌️"
        case .gaming: return "🎮"
        case .language: return "🗣️"
        case .tourism: return "🧳"
        case .law: return "⚖️"
        case .business: return "💼"
        case .construction: return "🏗️"
        case .automotive: return "🚗"
        case .aviation: return "✈️"
        case .maritime: return "🛳️"
        case .logistics: return "📦"
        case .retail: return "🛒"
        case .science: return "🔬"
        case .hospitality: return "🍽️"
        case .fashion: return "👗"
        case .service: return "🛎️"
        case .manufacturing: return "🧪"
        case .finance: return "💰"
        case .entrepreneurship: return "🚀"
        case .transportation: return "🚚"
        case .administration: return "🗂️"
        }
    }

    var persona: JobGroup {
        switch self {
        case .publicServices, .education, .health, .service:
            return .people
        case .engineering, .technology, .manufacturing:
            return .tools
        case .showBusiness:
            return .creative
        case .agriculture:
            return .outdoors
        case .design:
            return .creative
        case .gaming:
            return .creative
        case .language:
            return .people
        case .tourism:
            return .people
        case .law:
            return .people
        case .business:
            return .people
        case .construction:
            return .tools
        case .automotive:
            return .tools
        case .aviation:
            return .tools
        case .maritime:
            return .outdoors
        case .logistics:
            return .tools
        case .retail:
            return .people
        case .science:
            return .science
        case .hospitality:
            return .people
        case .fashion:
            return .creative
        case .finance:
            return .people
        case .entrepreneurship:
            return .people
        case .transportation:
            return .tools
        case .administration:
            return .people
        }
    }

    var description: String {
        switch self {
        case .publicServices:
            return "Keeping your town safe and running: police, firefighters, city services, security, and support for families."
        case .education:
            return "Teaching and learning with students, making school fun and helping minds grow."
        case .health:
            return "Keeping people healthy and safe: doctors, nurses, dentists, and helpers at clinics and hospitals."
        case .engineering:
            return "Designing and building things like bridges, machines, and robots. Lots of problem solving!"
        case .technology:
            return "Making apps, games, and computers work. Code, test, and create cool digital tools."
        case .showBusiness:
            return "Lights, camera, action! Performing, creating, and competing in the spotlight — acting, music, dance, film, TV, social media, and pro sports."
        case .agriculture:
            return "Farming, growing food, and taking care of animals. It's all about nurturing life."
        case .design:
            return "Make things look great and work well—like logos, apps, clothes, and rooms."
        case .gaming:
            return "Build video games: model 3D worlds, design mechanics, animate characters, and code the fun."
        case .language:
            return "Use words to connect people: translate, teach languages, write, and communicate."
        case .tourism:
            return "Help people explore new places: plan trips, guide tours, and make travel fun."
        case .law:
            return "Protect rights and follow rules: lawyers, judges, and helpers who know the law."
        case .business:
            return "Manage money, sell products, advise companies, and lead teams to succeed."
        case .construction:
            return "Build homes, roads, and cities with tools, machines, and teamwork."
        case .automotive:
            return "Work with cars and trucks: design, fix, and test vehicles."
        case .aviation:
            return "Fly and care for airplanes: pilots, mechanics, and air traffic helpers."
        case .maritime:
            return "Work on or near the sea: ships, ports, rescue, and caring for oceans."
        case .logistics:
            return "Move things where they need to go: plan routes, track packages, and manage warehouses."
        case .retail:
            return "Help customers find what they need in stores and online."
        case .science:
            return "Discover how the world works: labs, experiments, and new inventions."
        case .hospitality:
            return "Welcome and care for guests in hotels, restaurants, flights, and events to make their day great."
        case .fashion:
            return "Create clothing and styles, follow trends, and help people express themselves."
        case .service:
            return "Personal grooming and beauty services that help people look and feel their best."
        case .manufacturing:
            return "Make products from raw materials: factories, workshops, and artisans."
        case .finance:
            return "Manage money, investments, and financial risk: banks, markets, and accounting."
        case .entrepreneurship:
            return "Start your own business! Take a risk, build something new, and be your own boss."
        case .transportation:
            return "Move people and goods by road and air: drive, fly, operate, and keep vehicles running safely."
        case .administration:
            return "The back office every company needs: accounting, payroll, hiring, and keeping the place organized."
        }

    }

    var examples: String {
        switch self {
        case .publicServices:
            return "Police, firefighter, municipal worker, security guard, social worker"
        case .education:
            return "Tutor, teacher, department head"
        case .health:
            return "Doctor, nurse, dentist, paramedic, therapist"
        case .engineering:
            return "Civil, mechanical, electrical, robotics"
        case .technology:
            return "Developer, tester, security, data"
        case .showBusiness:
            return "Actor, musician, athlete, TV host, content creator, coach"
        case .agriculture:
            return "Agriculturist, horticulturist, livestock"
        case .design:
            return "Graphic, UI/UX, fashion, interior"
        case .gaming:
            return "3D modeller, game designer, animator, gameplay programmer"
        case .language:
            return "Translator, interpreter, language teacher"
        case .tourism:
            return "Tour guide, travel agent, event planner"
        case .law:
            return "Lawyer, paralegal, judge, legal assistant"
        case .business:
            return "Analyst, sales manager, consultant, translator"
        case .construction:
            return "Carpenter, electrician, plumber, site manager"
        case .automotive:
            return "Mechanic, auto designer, test driver"
        case .aviation:
            return "Pilot, flight attendant, aircraft mechanic"
        case .maritime:
            return "Sailor, marine engineer, coast guard"
        case .logistics:
            return "Dispatcher, supply chain, warehouse manager"
        case .retail:
            return "Sales associate, merchandiser, store manager"
        case .science:
            return "Lab technician, research scientist"
        case .hospitality:
            return "Chef, server, housekeeper, flight attendant, hotel manager"
        case .fashion:
            return "Fashion designer, stylist, tailor, merchandiser"
        case .service:
            return "Hairdresser, barber, beautician"
        case .manufacturing:
            return "Plumber, electrician, welder"
        case .finance:
            return "Banker, financial analyst, accountant, trader, actuary"
        case .entrepreneurship:
            return "Side hustler, small business owner, startup founder"
        case .transportation:
            return "Driver, pilot, aircraft mechanic, air traffic controller"
        case .administration:
            return "Accountant, HR specialist, recruiter, office manager"
        }
    }
}

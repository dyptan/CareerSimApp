/// The curated set of reputation buckets the game tracks fame in — a small,
/// fixed taxonomy distinct from the ~two dozen `JobCategory` industries. Every
/// fame source (competitions, spare-time projects, presenter roles, executive
/// wins) banks into one of these, and each job maps to one via
/// `JobCategory.fameCategory` so a reputation only helps hiring in its own
/// family. **Entertainment** merges the spotlight fields — performing arts,
/// media, and sports — into a single celebrity bucket.
enum FameCategory: String, CaseIterable, Identifiable, Codable {
    case entertainment = "Entertainment"
    case technology = "Technology"
    case arts = "Arts"
    case business = "Business"
    case science = "Science"

    var id: String { rawValue }

    /// Display pictogram for the bucket, shown on the fame shelf and in hiring
    /// odds breakdowns.
    var icon: String {
        switch self {
        case .entertainment: return "🎬"
        case .technology: return "💻"
        case .arts: return "🎨"
        case .business: return "💼"
        case .science: return "🔬"
        }
    }
}

/// Where a role is actually done — the day-to-day setting rather than the
/// industry. Lets the jobs list answer "what kind of work is this?", which
/// `JobCategory` alone can't: technology holds both a support desk and a data
/// centre, and hospitality holds both a waiter and a dishwasher.
///
/// Stated per role (see `JobCatalog.workSettingByBaseTitle`), never inferred
/// from a proxy such as the outdoor-resilience requirement — a soft-skill bar is
/// evidence about a role, not a statement of where it happens.
enum WorkSetting: String, CaseIterable, Identifiable, Codable {
    /// Desk and screen work: offices, studios, labs of the paperwork kind.
    case office = "Office"
    /// Hands-on and on your feet — building sites, kitchens, warehouses, farms,
    /// vehicles, wards where the work is physical rather than clerical.
    case field = "Field"
    /// The job *is* dealing with people face to face: serving, teaching, caring,
    /// selling, performing.
    case peopleFacing = "People-facing"

    var id: String { rawValue }

    /// Pictogram for filter chips and role rows.
    var pictogram: String {
        switch self {
        case .office: return "🗄️"
        case .field: return "🛠️"
        case .peopleFacing: return "🤝"
        }
    }

    /// One-line explanation for the filter's info hint.
    var blurb: String {
        switch self {
        case .office: return "Desk work — planning, analysing, designing, writing."
        case .field: return "Hands-on work — building, fixing, driving, growing, cooking."
        case .peopleFacing: return "Working directly with people — serving, teaching, caring, performing."
        }
    }
}

enum JobCategory: String, CaseIterable, Identifiable, Codable {
    case engineering = "Engineering"
    /// Entertainment and the spotlight: performing arts, media/creators, and
    /// professional sports.
    case showBusiness = "Show Business"
    case publicServices = "Public Services"
    case health = "Health"
    case technology = "Technology"
    case education = "Education"
    case agriculture = "Agriculture"
    case design = "Design"
    case law = "Law"
    case business = "Business"
    case construction = "Construction"
    case retail = "Retail"
    case science = "Science"
    case hospitality = "Hospitality"
    case service = "Personal Services"
    case manufacturing = "Manufacturing"
    /// No jobs carry this category — ventures keep their real industry. It is
    /// the experience bucket a founder's years accrue into (see
    /// `Player.advanceYear` and `creditedExperienceCategories`), which is why it
    /// stays even though the jobs list never shows it.
    case entrepreneurship = "Entrepreneurship"
    case transportation = "Transportation"
    case administration = "Administration"

    var id: String { rawValue }

    /// The fame bucket this industry belongs to, or `nil` for fields where a
    /// public reputation doesn't move the hiring needle (trades, services,
    /// regulated/blue-collar work). Fame is earned and spent in these five
    /// curated buckets rather than per job category (see `FameCategory` and
    /// `Player.fameHireBonus`): tech/engineering build **Technology**
    /// fame, business/finance/retail/entrepreneurship/administration build
    /// **Business**, science/health/education build **Science**,
    /// design/fashion/language build **Arts**, and the spotlight fields
    /// (show business, which already folds in the performing arts and sports)
    /// build **Entertainment**.
    var fameCategory: FameCategory? {
        switch self {
        case .technology, .engineering:
            return .technology
        case .business, .retail, .entrepreneurship, .administration:
            return .business
        case .science, .health, .education:
            return .science
        case .design:
            return .arts
        case .showBusiness:
            return .entertainment
        default:
            return nil
        }
    }

    /// Maximum fractional swing above or below the base salary in a single year.
    /// e.g. 0.5 means actual pay can range from 50 % to 150 % of the base.
    var salaryVariance: Double {
        switch self {
        case .entrepreneurship:
            return 0.55   // founder income swings wildly with the venture
        case .showBusiness:
            return 0.50   // heavily project-based / performance-driven
        case .technology, .engineering, .science:
            return 0.40   // bonuses, stock, market swings
        case .business, .law:
            return 0.40
        case .construction, .manufacturing:
            return 0.30   // seasonal and contract variability
        case .agriculture, .transportation, .retail, .service, .hospitality:
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
        case .hospitality, .retail, .showBusiness, .entrepreneurship:
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
        case .health, .transportation, .law, .publicServices, .construction:
            return true
        default:
            return false
        }
    }

    /// Professions where a formal degree is legally or practically mandatory to
    /// practise — you can't be a doctor, lawyer, engineer, scientist, or teacher
    /// without the qualification, so education stays a HARD hiring gate here. In
    /// every other field a degree only improves the odds (it's folded into the
    /// hire-probability score via `Job.educationFactor`) but never blocks an
    /// application — talent, portfolio, and experience can stand in for it.
    var educationIsMandatory: Bool {
        switch self {
        case .health, .law, .engineering, .science, .education:
            return true
        default:
            return false
        }
    }

    /// Years that count toward this field: its own plus the industries it
    /// credits (see `creditedExperienceCategories`). The single definition —
    /// `Player.industryExperience` and `CareerEvent.canPresent` both read it, so
    /// a founder's years count the same way when applying for a Business role
    /// and when taking the stage at a Business event.
    func creditedYears(in experience: [JobCategory: Int]) -> Int {
        let own = experience[self] ?? 0
        return creditedExperienceCategories.reduce(own) { total, other in
            total + (experience[other] ?? 0)
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
        case .law: return "⚖️"
        case .business: return "💼"
        case .construction: return "🏗️"
        case .retail: return "🛒"
        case .science: return "🔬"
        case .hospitality: return "🍽️"
        case .service: return "🛎️"
        case .manufacturing: return "🏭"
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
        case .law:
            return .people
        case .business:
            return .people
        case .construction:
            return .tools
        case .retail:
            return .people
        case .science:
            return .science
        case .hospitality:
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
            return "Make things look great and work well — logos, apps, clothes, rooms, and the worlds and characters in video games."
        case .law:
            return "Protect rights and follow rules: lawyers, judges, and helpers who know the law."
        case .business:
            return "Manage money, sell products, advise companies, and lead teams to succeed."
        case .construction:
            return "Build homes, roads, and cities with tools, machines, and teamwork."
        case .retail:
            return "Help customers find what they need in stores and online."
        case .science:
            return "Discover how the world works: labs, experiments, and new inventions."
        case .hospitality:
            return "Welcome and care for guests in hotels, restaurants, flights, and events to make their day great."
        case .service:
            return "Personal grooming and beauty services that help people look and feel their best."
        case .manufacturing:
            return "Make products from raw materials: factories, workshops, and artisans."
        case .entrepreneurship:
            return "Start your own business! Take a risk, build something new, and be your own boss."
        case .transportation:
            return "Move people and goods by road and air: drive, fly, operate, keep vehicles running safely, and plan the routes and warehouses behind it."
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
            return "Developer, tester, security, data, gameplay programming"
        case .showBusiness:
            return "Actor, musician, athlete, TV host, content creator, coach"
        case .agriculture:
            return "Agriculturist, horticulturist, livestock"
        case .design:
            return "Graphic, UI/UX, fashion, interior, 3D modelling, game design"
        case .law:
            return "Lawyer, paralegal, judge, legal assistant"
        case .business:
            return "Analyst, sales manager, consultant, translator"
        case .construction:
            return "Carpenter, electrician, plumber, site manager"
        case .retail:
            return "Sales associate, merchandiser, store manager"
        case .science:
            return "Lab technician, research scientist"
        case .hospitality:
            return "Chef, server, housekeeper, flight attendant, hotel manager"
        case .service:
            return "Hairdresser, barber, beautician"
        case .manufacturing:
            return "Machinist, welder, machine operator, quality inspector"
        case .entrepreneurship:
            return "Side hustler, small business owner, startup founder"
        case .transportation:
            return "Driver, pilot, aircraft mechanic, air traffic controller, dispatcher, warehouse manager"
        case .administration:
            return "Accountant, HR specialist, payroll, office manager"
        }
    }
}

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
        case .office: return L("Desk work — planning, analysing, designing, writing.")
        case .field: return L("Hands-on work — building, fixing, driving, growing, cooking.")
        case .peopleFacing: return L("Working directly with people — serving, teaching, caring, performing.")
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

    /// Employer-to-employer spread on a posting's pay: each year's posting is
    /// priced within ± this share of the catalogue median (see `Job.init`).
    /// Nothing the player is offered reads it — listings show the median and an
    /// offer is built from it (`Job.offeredSalary`), and a promotion pays from
    /// the rung's catalogue median — so it only colours the raw postings.
    /// Project-driven show business and founders' incomes swing wider.
    var salaryVariance: Double {
        switch self {
        case .entrepreneurship, .showBusiness:
            return 0.25
        default:
            return 0.10
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
    /// `Player.industryExperience` and `Player.presentOdds` both read it, so
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

    var description: String {
        switch self {
        case .publicServices:
            return L("Keeping your town safe and running: police, firefighters, city services, security, and support for families.")
        case .education:
            return L("Teaching and learning with students, making school fun and helping minds grow.")
        case .health:
            return L("Keeping people healthy and safe: doctors, nurses, dentists, and helpers at clinics and hospitals.")
        case .engineering:
            return L("Designing and building things like bridges, machines, and robots. Lots of problem solving!")
        case .technology:
            return L("Making apps, games, and computers work. Code, test, and create cool digital tools.")
        case .showBusiness:
            return L("Lights, camera, action! Performing, creating, and competing in the spotlight — acting, music, dance, film, TV, social media, and pro sports.")
        case .agriculture:
            return L("Farming, growing food, and taking care of animals. It's all about nurturing life.")
        case .design:
            return L("Make things look great and work well — logos, apps, clothes, rooms, and the worlds and characters in video games.")
        case .law:
            return L("Protect rights and follow rules: lawyers, judges, and helpers who know the law.")
        case .business:
            return L("Manage money, sell products, advise companies, and lead teams to succeed.")
        case .construction:
            return L("Build homes, roads, and cities with tools, machines, and teamwork.")
        case .retail:
            return L("Help customers find what they need in stores and online.")
        case .science:
            return L("Discover how the world works: labs, experiments, and new inventions.")
        case .hospitality:
            return L("Welcome and care for guests in hotels, restaurants, flights, and events to make their day great.")
        case .service:
            return L("Personal grooming and beauty services that help people look and feel their best.")
        case .manufacturing:
            return L("Make products from raw materials: factories, workshops, and artisans.")
        case .entrepreneurship:
            return L("Start your own business! Take a risk, build something new, and be your own boss.")
        case .transportation:
            return L("Move people and goods by road and air: drive, fly, operate, keep vehicles running safely, and plan the routes and warehouses behind it.")
        case .administration:
            return L("The back office every company needs: accounting, payroll, hiring, and keeping the place organized.")
        }
    }
}



/// The sector of the economy an employer trades in — *what the business sells*,
/// as distinct from `JobCategory`, which is what the worker actually does.
///
/// The two are genuinely different axes and one cannot stand in for the other: a
/// mechanical engineer, a lawyer and a designer are all `.engineering`, `.law`
/// and `.design` respectively whichever sector employs them, and a single sector
/// employs all three. Modelling the economy on `JobCategory` meant a downturn in
/// "Design" — which is not a market anyone trades in — instead of a downturn in
/// advertising or in carmaking.
///
/// Every posting states its sector (see `Job.industry`), and this is the unit the
/// cycle runs on: `Player.industryTrend` is keyed by `Industry`, not by category.
enum Industry: String, CaseIterable, Identifiable, Codable {
    case software = "Software & Internet"
    case hardware = "Computing Hardware"
    case telecom = "Telecoms"
    case automotive = "Automotive"
    case aerospaceDefense = "Aerospace & Defence"
    case energy = "Energy & Utilities"
    case finance = "Banking & Finance"
    case healthcare = "Healthcare"
    case pharmaBiotech = "Pharma & Biotech"
    case education = "Education"
    case government = "Government & Public Sector"
    case retailTrade = "Retail & Consumer"
    case hospitalityTourism = "Hospitality & Tourism"
    case mediaEntertainment = "Media & Entertainment"
    case construction = "Construction & Property"
    case agriFood = "Agriculture & Food"
    case logistics = "Transport & Logistics"
    case manufacturing = "Industrial Manufacturing"
    case professionalServices = "Professional Services"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .software:             return "💾"
        case .hardware:             return "🖥️"
        case .telecom:              return "📡"
        case .automotive:           return "🚗"
        case .aerospaceDefense:     return "✈️"
        case .energy:               return "⚡"
        case .finance:              return "🏦"
        case .healthcare:           return "🏥"
        case .pharmaBiotech:        return "💊"
        case .education:            return "🏫"
        case .government:           return "🏛️"
        case .retailTrade:          return "🛒"
        case .hospitalityTourism:   return "🏨"
        case .mediaEntertainment:   return "🎬"
        case .construction:         return "🏗️"
        case .agriFood:             return "🌾"
        case .logistics:            return "🚚"
        case .manufacturing:        return "🏭"
        case .professionalServices: return "📁"
        }
    }

    /// Cyclical, discretionary-spending sectors hit hardest in a bear market.
    var isCyclical: Bool { beta > 1.0 }

    /// The fame bucket a reputation made in this sector belongs to. Mirrors
    /// `JobCategory.fameCategory` on the sector axis, so a project can ride the
    /// markets it would make its name in (see `Player.climate(forFame:)`).
    var fameCategory: FameCategory? {
        switch self {
        case .software, .hardware, .telecom:
            return .technology
        case .finance, .retailTrade, .professionalServices:
            return .business
        case .healthcare, .pharmaBiotech, .education:
            return .science
        case .mediaEntertainment:
            return .entertainment
        default:
            return nil
        }
    }

    /// What this industry promotes on, as weights that sum to 1:
    ///
    /// * **performance** — how well you do the job you hold (your skill fit for it);
    /// * **readiness** — how ready you are for the next level up (your skill fit
    ///   for the next rung, where leadership and planning start to count);
    /// * **seniority** — time in the role.
    ///
    /// Modelled on how each sector actually decides. The public sector,
    /// utilities and the unionised trades run on time-in-grade and seniority
    /// lists; software and finance use levelling committees that promote people
    /// already working at the next level; consulting and law are up-or-out on
    /// readiness; entertainment and retail reward results. See
    /// `Player.promotionOdds`.
    var promotionCulture: (performance: Double, readiness: Double, seniority: Double) {
        switch self {
        case .government:           return (0.25, 0.20, 0.55)
        case .education:            return (0.25, 0.20, 0.55)
        case .logistics:            return (0.30, 0.15, 0.55)
        case .energy:               return (0.30, 0.20, 0.50)
        case .manufacturing:        return (0.30, 0.20, 0.50)
        case .automotive:           return (0.30, 0.20, 0.50)
        case .construction:         return (0.35, 0.20, 0.45)
        case .healthcare:           return (0.35, 0.25, 0.40)
        case .aerospaceDefense:     return (0.30, 0.30, 0.40)
        case .agriFood:             return (0.40, 0.20, 0.40)
        case .telecom:              return (0.35, 0.30, 0.35)
        case .pharmaBiotech:        return (0.40, 0.35, 0.25)
        case .hardware:             return (0.40, 0.35, 0.25)
        case .retailTrade:          return (0.45, 0.30, 0.25)
        case .hospitalityTourism:   return (0.45, 0.30, 0.25)
        case .software:             return (0.45, 0.40, 0.15)
        case .finance:              return (0.40, 0.45, 0.15)
        case .professionalServices: return (0.35, 0.50, 0.15)
        case .mediaEntertainment:   return (0.55, 0.30, 0.15)
        }
    }

    /// One line on how this industry promotes, for the promotion-odds hint.
    var promotionCultureBlurb: String {
        let c = promotionCulture
        if c.seniority >= 0.45 {
            return L("In \(displayName), the years you've worked there count the most.")
        }
        if c.readiness >= 0.45 {
            return L("In \(displayName), being ready for the next job counts the most.")
        }
        if c.performance >= 0.45 {
            return L("In \(displayName), doing your current job well counts the most.")
        }
        return L("In \(displayName), doing well, being ready and years worked all count about the same.")
    }

    /// How much of the national cycle this sector transmits — its beta. 1.0 moves
    /// with the economy; above 1 amplifies it, below 1 damps it. It also scales
    /// the sector's yearly layoff risk (see `Player.layoffRisk(for:)`).
    ///
    /// Ranked on the 2007–09 record and JOLTS layoff rates: housing and capital
    /// goods fall first and hardest (construction lost ~16% of its jobs), then
    /// the discretionary trades; people fall ill, children go to school and the
    /// bins get collected in every economy, so public payrolls barely notice.
    var beta: Double {
        switch self {
        case .construction:
            return 1.8   // housing and capital projects stop first
        case .manufacturing, .automotive:
            return 1.5   // capital goods and big-ticket purchases
        case .logistics, .hospitalityTourism, .mediaEntertainment:
            return 1.3   // freight volumes, travel and advertising budgets
        case .retailTrade:
            return 1.2
        case .software, .hardware, .professionalServices:
            return 1.1
        case .finance, .aerospaceDefense:
            return 1.0
        case .pharmaBiotech, .energy, .agriFood, .telecom:
            return 0.6   // people still take their medicine and heat their homes
        case .healthcare, .education, .government:
            return 0.3   // defensive: funded through the cycle
        }
    }

    /// How much this sector moves on its *own* account, independent of the
    /// national cycle — a platform shift, a drug approval, an oil shock, a hit
    /// franchise. Beta says how a sector rides the economy; this says how much of
    /// its fortune has nothing to do with the economy at all.
    ///
    /// The two are genuinely separate: government has a low beta *and* low
    /// idiosyncratic swing (dull in every weather), whereas pharma also has a low
    /// beta but a high one — it ignores the cycle and lives on its own pipeline.
    var volatility: Double {
        switch self {
        case .software, .pharmaBiotech, .mediaEntertainment:
            return 1.6   // platform shifts, pipelines and hits, cycle or no cycle
        case .hardware, .energy, .aerospaceDefense:
            return 1.3   // capex cycles and commodity prices of their own
        case .government, .education:
            return 0.3   // budgets move slowly and for their own reasons
        case .healthcare, .agriFood, .retailTrade, .logistics:
            return 0.7
        default:
            return 1.0
        }
    }
}

/// How an industry is doing this year — the player-facing face of
/// `Player.industryTrend`. Every industry sits in one of these bands, and the
/// band is what the odds actually read: a boom is a genuinely easier year to be
/// hired and promoted in, a slump a genuinely harder one.
///
/// The bands are deliberately coarse. The underlying trend is a continuous
/// random walk, but a player can act on "Technology is booming" in a way they
/// cannot act on "Technology is at +0.62".
enum IndustryClimate: String, CaseIterable, Identifiable, Codable {
    case boom = "Booming"
    case growth = "Growing"
    case steady = "Steady"
    case slowdown = "Slowing"
    case slump = "Slump"

    var id: String { rawValue }

    /// Bucket a continuous trend (-1...1) into its band.
    init(trend: Double) {
        switch trend {
        case 0.55...:            self = .boom
        case 0.20..<0.55:        self = .growth
        case (-0.20)..<0.20:     self = .steady
        case (-0.55)..<(-0.20):  self = .slowdown
        default:                 self = .slump
        }
    }

    var icon: String {
        switch self {
        case .boom:     return "🚀"
        case .growth:   return "📈"
        case .steady:   return "➖"
        case .slowdown: return "📉"
        case .slump:    return "🧊"
        }
    }

    /// Multiplier on a founder's income this year: customers spend freely in a
    /// boom and pull back hard in a slump.
    var revenueFactor: Double {
        switch self {
        case .boom:     return 1.25
        case .growth:   return 1.10
        case .steady:   return 1.00
        case .slowdown: return 0.85
        case .slump:    return 0.65
        }
    }

    /// Multiplier on hire odds for a role in this industry. A slump does not
    /// close a field — someone is always hired somewhere — it just makes the
    /// same application a worse bet: JOLTS 2007–09 hires fell ~28%, openings
    /// ~50% (and a slump also withdraws some postings outright; see
    /// `GameConstants.slumpPostingWithdrawalChance`).
    var hireFactor: Double {
        switch self {
        case .boom:     return 1.30
        case .growth:   return 1.12
        case .steady:   return 1.00
        case .slowdown: return 0.88
        case .slump:    return 0.70
        }
    }

    /// Multiplier on the annual promotion odds. Employers hand out titles when
    /// the order book is full and hold them back when it isn't — Pave: growing
    /// firms promote 18.3% a year, flat ones 14.9%, shrinking ones 11.5% — but
    /// even a slump only thins promotions (see `Player.promotionOdds`).
    var promotionFactor: Double {
        switch self {
        case .boom:     return 1.25
        case .growth:   return 1.10
        case .steady:   return 1.00
        case .slowdown: return 0.85
        case .slump:    return 0.60
        }
    }

    /// Multiplier on the yearly layoff risk of a job in this industry (see
    /// `Player.layoffRisk(for:)`). BLS displacement runs ~1.5% of the employed a
    /// year in calm times and ~2.3× that in the worst recession since the war.
    var layoffFactor: Double {
        switch self {
        case .boom:     return 0.6
        case .growth:   return 0.8
        case .steady:   return 1.0
        case .slowdown: return 1.6
        case .slump:    return 2.5
        }
    }

    /// Multiplier on a spare-time project's success odds in this field. A
    /// project needs an audience with money and attention to spare, so the cycle
    /// reaches it too — more gently than a payroll, which is why the spread here
    /// is narrower than `hireFactor`'s.
    var projectFactor: Double {
        switch self {
        case .boom:     return 1.20
        case .growth:   return 1.08
        case .steady:   return 1.00
        case .slowdown: return 0.88
        case .slump:    return 0.70
        }
    }

    /// Whether employers in this industry have paused merit raises — a slump.
    /// Promotions still happen, just less often (`promotionFactor`).
    var pausesMeritRaises: Bool { self == .slump }

    /// One line for the Macroeconomics panel.
    var blurb: String {
        switch self {
        case .boom:     return L("Business is great! Lots of hiring — a great year to apply for a job.")
        case .growth:   return L("Growing. It's easier than usual to find a job.")
        case .steady:   return L("Steady — not growing or shrinking. Chances are normal.")
        case .slowdown: return L("Slowing down. Fewer jobs and promotions, and more people losing their jobs.")
        case .slump:    return L("Having a hard time. Some jobs disappear, pay stops growing, and more people lose their jobs.")
        }
    }
}

import Foundation

/// The hire odds JobDetail would display to a given kind of player, sampled
/// over many fresh players (random starting skills, random starting economy).
enum Snapshot {
    struct Stat {
        let title: String
        let category: JobCategory
        let income: Int
        let minEQF: Int
        let minYears: Int
        var odds: [Double] = []
        var steadyOdds: [Double] = []
        var fit: [Double] = []
        var eduFactor: [Double] = []
    }

    /// A fresh player as ModeSelectionView.start leaves them, optionally aged
    /// past school with a degree added.
    static func freshPlayer(_ difficulty: Difficulty, age: Int, degree: Education?) -> Player {
        let p = Player()
        p.difficulty = difficulty
        p.configureStart(age: min(age, 18))
        if age > 18 { p.age = age }
        if let degree { p.degrees.append(degree) }
        p.regenerateAvailableJobs()
        return p
    }

    /// Samples the odds for every salaried posting, JobDetail-style (the
    /// posting at base salary, the requested salary left at the offer,
    /// `job.offeredSalary(for:)`).
    static func sample(_ n: Int, make: () -> Player) -> [Stat] {
        var stats: [String: Stat] = [:]
        for _ in 0..<n {
            let p = make()
            for posting in p.availableJobs where !posting.isEntrepreneurial {
                let job = posting.atBaseSalary()
                let odds = job.hireProbability(for: p, requestedSalary: Double(job.offeredSalary(for: p)))
                var s = stats[job.id] ?? Stat(title: job.id, category: job.category, income: job.income,
                                              minEQF: job.requirements.education.minEQF,
                                              minYears: job.requirements.minYearsExperience)
                s.odds.append(odds)
                s.fit.append(job.softSkillFit(for: p))
                s.eduFactor.append(job.educationFactor(for: p))
                stats[job.id] = s
            }
            // The same player in a perfectly steady economy (every climate ×1.0).
            let saved = p.industryTrend
            for sector in Industry.allCases { p.industryTrend[sector] = 0 }
            for posting in p.availableJobs where !posting.isEntrepreneurial {
                let job = posting.atBaseSalary()
                stats[job.id]?.steadyOdds.append(job.hireProbability(for: p, requestedSalary: Double(job.offeredSalary(for: p))))
            }
            p.industryTrend = saved
        }
        return Array(stats.values)
    }

    static let eduLabel = ["–", "Primary", "Middle", "HS", "Vocational", "Bachelor", "Master", "Doctorate"]

    static func render(_ stats: [Stat], top: Int = 15, highlight: [String] = ["Software Engineer"]) -> String {
        let ranked = stats.sorted { mean($0.odds) > mean($1.odds) }
        var rows: [[String]] = []
        func row(_ s: Stat, rank: String) -> [String] {
            [rank, s.title, s.category.rawValue, money(Double(s.income)),
             eduLabel[min(max(s.minEQF, 0), 7)] + (s.minYears > 0 ? " + \(s.minYears)y" : ""),
             pct(mean(s.odds), digits: 0), pct(percentile(s.odds, 0.9), digits: 0),
             pct(mean(s.steadyOdds), digits: 0), num(mean(s.fit)), num(mean(s.eduFactor))]
        }
        for (i, s) in ranked.prefix(top).enumerated() { rows.append(row(s, rank: "\(i + 1)")) }
        for title in highlight where !ranked.prefix(top).contains(where: { $0.title == title }) {
            if let i = ranked.firstIndex(where: { $0.title == title }) { rows.append(row(ranked[i], rank: "\(i + 1)")) }
        }
        return table(["#", "Posting", "Category", "Pay", "Expects", "Odds mean", "Odds p90",
                      "Odds (steady economy)", "Skill fit", "Edu ×"], rows)
    }

    /// Mean admission odds (InstitutionTiersView's figure) across every field,
    /// for a set of 18-year-olds.
    static func admissionRow(_ label: String, _ players: [Player]) -> [String] {
        func avg(_ level: Level.Stage, _ tier: EducationTier) -> String {
            var xs: [Double] = []
            for p in players {
                for profile in TertiaryProfile.allCases {
                    if level == .Vocational && !profile.allowsVocational { continue }
                    if tier == .elite && !profile.isWhiteCollar { continue }
                    xs.append(Education(level, profile: profile, tier: tier).admissionProbability(player: p))
                }
            }
            return pct(mean(xs), digits: 0)
        }
        return [label, "\(players.count)", num(mean(players.map(\.highSchoolGPA))),
                avg(.Vocational, .community), avg(.Bachelor, .community), avg(.Bachelor, .state), avg(.Bachelor, .elite)]
    }

    static func run(samples: Int) -> String {
        var out = ""
        // Admission odds at 18, by how the childhood was spent.
        func grownUp(_ difficulty: Difficulty, _ policy: () -> Policy) -> Player {
            let g = Game(difficulty: difficulty, startAge: 7)
            let pol = policy()
            while g.player.age < 18 { pol.act(g) }
            return g.player
        }
        let n = max(50, samples / 4)
        out += "#### Admission odds at 18 (mean over every field; Real Life)\n\n"
        out += table(["18-year-old", "N", "GPA", "Vocational · community", "Bachelor · community", "Bachelor · state", "Bachelor · elite"], [
            admissionRow("Fresh start at 18", (0..<samples).map { _ in freshPlayer(.middleClass, age: 18, degree: nil) }),
            admissionRow("Typical childhood from 7", (0..<n).map { _ in grownUp(.middleClass) { TypicalPolicy() } }),
            admissionRow("Advisor childhood from 7", (0..<n).map { _ in grownUp(.middleClass) { AdvisorPolicy() } }),
        ]) + "\n"

        out += "#### Fresh 18-year-old high-school graduate — Real Life (\(samples) samples)\n\n"
        let hs = sample(samples) { freshPlayer(.middleClass, age: 18, degree: nil) }
        out += render(hs) + "\n"

        out += "#### Fresh 18-year-old high-school graduate — Relaxed (\(samples) samples)\n\n"
        let hsRelaxed = sample(samples) { freshPlayer(.comfortable, age: 18, degree: nil) }
        out += render(hsRelaxed, top: 10) + "\n"

        // The field's entry rungs are always listed, so a graduate's odds for
        // the job their degree leads to show even when unskilled work outranks it.
        let entryRungs: [TertiaryProfile: [String]] = [
            .technology: ["Junior Software Engineer", "Junior Data Analyst", "Software Engineer"],
            .business: ["Junior Business Analyst", "Junior Financial Analyst", "Junior Investment Banker"],
            .health: ["Registered Nurse", "Medical Assistant"],
        ]
        for profile in [TertiaryProfile.technology, .business, .health] {
            out += "#### Fresh 22-year-old with a state-tier Bachelor's in \(profile.rawValue) — Real Life (\(samples) samples)\n\n"
            let s = sample(samples) {
                freshPlayer(.middleClass, age: 22, degree: Education(.Bachelor, profile: profile, tier: .state))
            }
            out += render(s, highlight: entryRungs[profile] ?? ["Software Engineer"]) + "\n"
        }

        // What a diligent kid who followed the advisor from age 7 faces at 18.
        let kidSamples = max(50, samples / 4)
        out += "#### 18-year-old who followed the advisor from age 7 — Real Life (\(kidSamples) samples)\n\n"
        let kids = sample(kidSamples) {
            let g = Game(difficulty: .middleClass, startAge: 7)
            let policy = AdvisorPolicy()
            while g.player.age < 18 { policy.act(g) }
            // Measured before any age-18 choice: the posting list they open at 18.
            // (A kid the advisor put to work at 14–17 keeps that job, so its
            // experience counts here exactly as it would in the game.)
            return g.player
        }
        out += render(kids) + "\n"
        return out
    }
}

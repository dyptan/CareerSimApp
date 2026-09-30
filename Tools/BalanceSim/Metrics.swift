import Foundation

// MARK: - Statistics helpers

func percentile(_ values: [Double], _ q: Double) -> Double {
    guard !values.isEmpty else { return .nan }
    let s = values.sorted()
    let pos = q * Double(s.count - 1)
    let lo = Int(pos.rounded(.down)), hi = Int(pos.rounded(.up))
    return s[lo] + (s[hi] - s[lo]) * (pos - Double(lo))
}

func mean(_ values: [Double]) -> Double {
    values.isEmpty ? .nan : values.reduce(0, +) / Double(values.count)
}

func share(_ flags: [Bool]) -> Double {
    flags.isEmpty ? .nan : Double(flags.filter { $0 }.count) / Double(flags.count)
}

func money(_ v: Double) -> String {
    guard v.isFinite else { return "–" }
    let a = abs(v), sign = v < 0 ? "-" : ""
    if a >= 1_000_000 { return "\(sign)$\(String(format: "%.2f", a / 1_000_000))M" }
    if a >= 1_000 { return "\(sign)$\(String(format: "%.0f", a / 1_000))k" }
    return "\(sign)$\(String(format: "%.0f", a))"
}

func pct(_ v: Double, digits: Int = 1) -> String {
    guard v.isFinite else { return "–" }
    return String(format: "%.\(digits)f%%", v * 100)
}

func num(_ v: Double, digits: Int = 2) -> String {
    guard v.isFinite else { return "–" }
    return String(format: "%.\(digits)f", v)
}

func table(_ header: [String], _ rows: [[String]]) -> String {
    var out = "| " + header.joined(separator: " | ") + " |\n"
    out += "|" + header.map { _ in "---" }.joined(separator: "|") + "|\n"
    for r in rows { out += "| " + r.joined(separator: " | ") + " |\n" }
    return out
}

// MARK: - Scenario results

struct Scenario {
    let difficulty: Difficulty
    let policy: String
    let startAge: Int
    var lives: Int
    var country: Country = .default

    /// US scenarios keep their old labels, so earlier baselines still line up.
    var label: String {
        "\(difficulty.title) · \(policy) · \(startAge)" + (country == .default ? "" : " · \(country.title)")
    }
}

struct ScenarioResult {
    let scenario: Scenario
    let records: [LifeRecord]
    let seconds: Double

    var label: String { scenario.label }

    func values(_ f: (LifeRecord) -> Int) -> [Double] { records.map { Double(f($0)) } }
    func optValues(_ f: (LifeRecord) -> Int?) -> [Double] { records.compactMap { f($0).map(Double.init) } }
}

enum EduBucket: Int, CaseIterable {
    case highSchool, vocational, bachelor, master, doctorate
    init(eqf: Int) {
        switch eqf {
        case ...3: self = .highSchool
        case 4: self = .vocational
        case 5: self = .bachelor
        case 6: self = .master
        default: self = .doctorate
        }
    }
    var label: String {
        switch self {
        case .highSchool: return "None/HS"
        case .vocational: return "Vocational"
        case .bachelor: return "Bachelor"
        case .master: return "Master"
        case .doctorate: return "Doctorate"
        }
    }
}

// MARK: - Markdown report

enum Report {
    static func wealth(_ results: [ScenarioResult]) -> String {
        let rows = results.map { r -> [String] in
            let nw = r.values { $0.finalNetWorth }
            return [r.label, "\(r.records.count)",
                    money(percentile(nw, 0.10)), money(percentile(nw, 0.50)), money(mean(nw)), money(percentile(nw, 0.90)),
                    pct(share(r.records.map { $0.finalNetWorth >= 1_000_000 })),
                    pct(share(r.records.map { $0.finalNetWorth <= 0 })),
                    String(format: "%.0f", percentile(r.values { $0.finalScore }, 0.5))]
        }
        return table(["Scenario", "Lives", "NW p10", "NW median", "NW mean", "NW p90", "≥ $1M", "≤ $0", "Median score"], rows)
    }

    static func earnings(_ results: [ScenarioResult]) -> String {
        let rows = results.map { r -> [String] in
            let e = r.values { $0.salaryEarnings }
            let other = r.values { $0.otherIncome }
            let loan30 = r.values { $0.studentLoanAt30 }
            let borrowers = loan30.filter { $0 > 0 }
            return [r.label, money(percentile(e, 0.5)), money(percentile(e, 0.9)), money(mean(other)),
                    money(percentile(loan30, 0.5)), pct(Double(borrowers.count) / Double(max(1, loan30.count))),
                    money(percentile(borrowers, 0.5)),
                    num(percentile(r.optValues { $0.ageFirstJob }, 0.5), digits: 0),
                    pct(share(r.records.map { $0.ageFirstJob == nil }))]
        }
        return table(["Scenario", "Lifetime pay median", "Lifetime pay p90", "Other income mean",
                      "Student loan @30 median", "Owing @30", "Loan @30 median (borrowers)",
                      "Median age first job", "Never worked"], rows)
    }

    static func education(_ results: [ScenarioResult]) -> String {
        let header = ["Scenario"] + EduBucket.allCases.map { "\($0.label): share · median pay" }
        let rows = results.map { r -> [String] in
            var row = [r.label]
            for b in EduBucket.allCases {
                let inBucket = r.records.filter { EduBucket(eqf: $0.highestEQF) == b }
                let s = Double(inBucket.count) / Double(max(1, r.records.count))
                let med = percentile(inBucket.map { Double($0.salaryEarnings) }, 0.5)
                row.append(inBucket.isEmpty ? "0%" : "\(pct(s, digits: 0)) · \(money(med))")
            }
            return row
        }
        return table(header, rows)
    }

    static func schooling(_ results: [ScenarioResult]) -> String {
        let rows = results.map { r -> [String] in
            let recs = r.records
            let appsPerLife = mean(recs.map { Double($0.schoolApplications) })
            let totalApps = recs.reduce(0) { $0 + $1.schoolApplications }
            let totalAdmit = recs.reduce(0) { $0 + $1.schoolAdmissions }
            return [r.label,
                    pct(share(recs.map { $0.highestEQF >= 4 })),
                    pct(share(recs.map { $0.highestEQF >= 5 })),
                    pct(share(recs.map { $0.highestEQF >= 6 })),
                    pct(share(recs.map { $0.highestEQF >= 7 })),
                    num(percentile(recs.map(\.gpa), 0.5)),
                    num(appsPerLife), totalApps == 0 ? "–" : pct(Double(totalAdmit) / Double(totalApps)),
                    num(mean(recs.map { Double($0.trainings) })),
                    num(mean(recs.map { Double($0.studyWhileWorkingYears) })),
                    underQualified(recs)]
        }
        return table(["Scenario", "≥ Vocational", "≥ Bachelor", "≥ Master", "Doctorate",
                      "HS GPA median", "School apps/life", "Admit rate", "Courses/life", "Yrs paid while enrolled",
                      "No-degree lives in a degree-level job at 45"], rows)
    }

    /// Among lives with no tertiary qualification at 45 that hold a job then,
    /// the share whose job expects a bachelor's or more.
    static func underQualified(_ recs: [LifeRecord]) -> String {
        let pool = recs.filter { $0.eqfAt45 <= 3 && $0.jobAt45MinEQF != nil }
        guard !pool.isEmpty else { return "–" }
        let hits = pool.filter { ($0.jobAt45MinEQF ?? 0) >= 5 }.count
        return "\(pct(Double(hits) / Double(pool.count))) of \(pool.count)"
    }

    static func salaries(_ results: [ScenarioResult]) -> String {
        let rows = results.map { r -> [String] in
            var row = [r.label]
            for a in [25, 35, 45, 55] {
                let paid = r.records.compactMap { $0.salaryAt[a] }.map(Double.init)
                let emp = r.records.compactMap { $0.employedAt[a] }
                row.append("\(money(percentile(paid, 0.5))) / \(money(percentile(paid, 0.9))) (\(pct(share(emp), digits: 0)))")
            }
            let peaks = r.records.filter { $0.peakSalary > 0 }.map { Double($0.peakSalary) }
            row.append("\(money(percentile(peaks, 0.5))) / \(money(percentile(peaks, 0.9)))")
            let tracked = r.records.reduce(0) { $0 + $1.yearsTracked }
            let unemployed = r.records.reduce(0) { $0 + $1.yearsUnemployed }
            let studying = r.records.reduce(0) { $0 + $1.yearsStudying }
            row.append(pct(Double(unemployed) / Double(max(1, tracked))))
            row.append(pct(Double(studying) / Double(max(1, tracked))))
            return row
        }
        return table(["Scenario", "Age 25 med / p90 (employed)", "Age 35", "Age 45", "Age 55",
                      "Peak med / p90", "Yrs 22–64 jobless", "Yrs 22–64 studying (unpaid)"], rows)
    }

    static func ladders(_ results: [ScenarioResult]) -> String {
        let rows = results.map { r -> [String] in
            let recs = r.records
            let founded = recs.reduce(0) { $0 + $1.venturesFounded }
            let folds = recs.reduce(0) { $0 + $1.ventureFolds }
            return [r.label,
                    pct(share(recs.map(\.everTopLeadership))),
                    num(percentile(recs.compactMap { $0.ageTopLeadership.map(Double.init) }, 0.5), digits: 0),
                    pct(share(recs.map(\.everExecutive))),
                    pct(share(recs.map(\.everChief))),
                    pct(share(recs.map(\.everStar)), digits: 2),
                    pct(share(recs.map(\.everScreenStar)), digits: 2),
                    pct(share(recs.map(\.everProAthlete)), digits: 2),
                    r.scenario.startAge < 18 ? pct(share(recs.map(\.juniorChampionBy18))) : "–",
                    pct(share(recs.map(\.everFounder))),
                    founded == 0 ? "–" : "\(pct(Double(folds) / Double(founded))) of \(founded)",
                    pct(share(recs.map(\.everRegulated))),
                    pct(share(recs.map(\.everDoctorateJob)))]
        }
        return table(["Scenario", "Top leadership (isTopLeadership)", "Median age reached", "Exec seat (non-founder)",
                      "\"Chief …\" seat", "Show-biz star (any)", "…screen/music title", "Pro athlete", "Junior Champion by 18", "Founder", "Venture folds",
                      "Ever in a health/law/eng/science/education-category job", "Ever in doctorate-level job"], rows)
    }

    static func dynamics(_ results: [ScenarioResult]) -> String {
        let rows = results.map { r -> [String] in
            let recs = r.records
            let apps = recs.reduce(0) { $0 + $1.applications }
            let hires = recs.reduce(0) { $0 + $1.hires }
            let tracked = recs.reduce(0) { $0 + $1.yearsTracked }
            let recession = recs.reduce(0) { $0 + $1.recessionYears }
            return [r.label,
                    num(mean(recs.map { Double($0.rungPromotions) })),
                    num(mean(recs.map { Double($0.raises) })),
                    num(mean(recs.map { Double($0.layoffs) })),
                    num(mean(recs.map { Double($0.hires) })),
                    num(mean(recs.map { Double($0.jobSwitches) })),
                    num(mean(recs.map { Double($0.applications) }), digits: 1),
                    apps == 0 ? "–" : pct(Double(hires) / Double(apps)),
                    money(mean(recs.map { Double($0.boardroomCash) })),
                    pct(Double(recession) / Double(max(1, tracked)))]
        }
        return table(["Scenario", "Rung promotions", "Merit-raise years", "Layoffs", "Hires",
                      "Job-to-job switches", "Applications", "Hire rate/app", "Boardroom cash mean",
                      "Recession yrs (22–64)"], rows)
    }

    static func simplifiedGoal(_ results: [ScenarioResult]) -> String {
        let rows = results.filter { $0.scenario.difficulty == .simplified }.map { r -> [String] in
            let ages = r.records.compactMap { $0.goalAge.map(Double.init) }
            return [r.label, pct(share(r.records.map { $0.goalAge != nil })),
                    num(percentile(ages, 0.5), digits: 0), num(percentile(ages, 0.1), digits: 0),
                    num(percentile(ages, 0.9), digits: 0)]
        }
        return table(["Scenario", "Reached goal (top leadership)", "Median age", "p10 age", "p90 age"], rows)
    }

    static func topJobs(_ results: [ScenarioResult]) -> String {
        func top(_ r: ScenarioResult, _ key: (LifeRecord) -> String?, _ n: Int = 5) -> String {
            var counts: [String: Int] = [:]
            for rec in r.records { counts[key(rec) ?? "(none)", default: 0] += 1 }
            return counts.sorted { $0.value > $1.value }.prefix(n)
                .map { "\($0.key) \(pct(Double($0.value) / Double(r.records.count), digits: 0))" }
                .joined(separator: ", ")
        }
        var out = ""
        for r in results {
            out += "- **\(r.label)**\n"
            out += "  - first job: " + top(r, { $0.firstJob }) + "\n"
            out += "  - at 25: " + top(r, { $0.jobAt25 }) + "\n"
            out += "  - at 45: " + top(r, { $0.jobAt45 }) + "\n"
            // Split by schooling, to see where each education level ends up.
            out += "  - at 45, HS or less: " + top(r, { $0.eqfAt45 <= 3 ? ($0.jobAt45 ?? "(none)") : "·other" }, 6) + "\n"
            out += "  - at 45, bachelor+: " + top(r, { $0.eqfAt45 >= 5 ? ($0.jobAt45 ?? "(none)") : "·other" }, 6) + "\n"
        }
        return out
    }

    static func actionMix(_ results: [ScenarioResult]) -> String {
        var out = ""
        for r in results {
            var counts: [String: Int] = [:]
            for rec in r.records { for (k, v) in rec.actionMix { counts[k, default: 0] += v } }
            let total = Double(counts.values.reduce(0, +))
            let top = counts.sorted { $0.value > $1.value }.prefix(8)
                .map { "\($0.key) \(pct(Double($0.value) / total, digits: 0))" }
            out += "- **\(r.label)**: " + top.joined(separator: ", ") + "\n"
        }
        return out
    }
}

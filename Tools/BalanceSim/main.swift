import Foundation

// Career Sim balance simulator — see README.md.
//
// Usage: balancesim [--lives N] [--young-lives N] [--snapshot N] [--threads N]
//                   [--only <substring>] [--no-snapshot] [--out FILE]

var lives = 600
var youngLives = 600
var snapshotSamples = 400
var threads = ProcessInfo.processInfo.activeProcessorCount
var only: String?
var runSnapshot = true
var outPath: String?

var args = Array(CommandLine.arguments.dropFirst())
while !args.isEmpty {
    let a = args.removeFirst()
    func next() -> String {
        guard !args.isEmpty else { fatalError("missing value for \(a)") }
        return args.removeFirst()
    }
    switch a {
    case "--lives": lives = Int(next())!
    case "--young-lives": youngLives = Int(next())!
    case "--snapshot": snapshotSamples = Int(next())!
    case "--threads": threads = max(1, Int(next())!)
    case "--only": only = next().lowercased()
    case "--no-snapshot": runSnapshot = false
    case "--out": outPath = next()
    case "-h", "--help":
        print("balancesim [--lives N] [--young-lives N] [--snapshot N] [--threads N] [--only substr] [--no-snapshot] [--out FILE]")
        exit(0)
    default: fatalError("unknown argument \(a)")
    }
}

var scenarios: [Scenario] = []
for policy in ["advisor", "typical", "passive", "striver"] {
    scenarios.append(Scenario(difficulty: .middleClass, policy: policy, startAge: 18, lives: lives))
}
// Starting at 18 the dreamer has no junior title, so this isolates the screen-star route.
scenarios.append(Scenario(difficulty: .middleClass, policy: "dreamer", startAge: 18, lives: lives))
for policy in ["advisor", "typical", "dreamer"] {
    scenarios.append(Scenario(difficulty: .middleClass, policy: policy, startAge: 7, lives: youngLives))
}
for policy in ["advisor", "typical"] {
    scenarios.append(Scenario(difficulty: .simplified, policy: policy, startAge: 7, lives: youngLives))
}
if let only { scenarios = scenarios.filter { $0.label.lowercased().contains(only) } }

/// Plays `scenario.lives` independent lives, spread over worker threads (each
/// life owns its own Player/AppUIState; the model keeps no shared mutable state).
func run(_ scenario: Scenario) -> ScenarioResult {
    let start = Date()
    var records = [LifeRecord?](repeating: nil, count: scenario.lives)
    let lock = NSLock()
    let chunk = max(1, (scenario.lives + threads - 1) / threads)
    DispatchQueue.concurrentPerform(iterations: threads) { worker in
        let lo = worker * chunk, hi = min(scenario.lives, lo + chunk)
        guard lo < hi else { return }
        var local: [(Int, LifeRecord)] = []
        for i in lo..<hi {
            let game = Game(difficulty: scenario.difficulty, startAge: scenario.startAge)
            game.play(makePolicy(scenario.policy))
            local.append((i, game.rec))
        }
        lock.lock()
        for (i, r) in local { records[i] = r }
        lock.unlock()
    }
    return ScenarioResult(scenario: scenario, records: records.compactMap { $0 },
                          seconds: Date().timeIntervalSince(start))
}

let wallStart = Date()
var results: [ScenarioResult] = []
for s in scenarios {
    let r = run(s)
    FileHandle.standardError.write("\(s.label): \(r.records.count) lives in \(String(format: "%.1f", r.seconds))s\n".data(using: .utf8)!)
    results.append(r)
}

var report = "# Career Sim balance baseline\n\n"
report += "Lives per scenario: \(lives) (start 18), \(youngLives) (start 7). Threads: \(threads). "
report += "Salaries in fixed 2026 USD; net worth = savings − student loan − venture loan, at age \(GameConstants.retirementAge).\n\n"
report += "## 1. Wealth at \(GameConstants.retirementAge)\n\n" + Report.wealth(results) + "\n"
report += "## 2. Lifetime gross pay, loans, first job\n\n" + Report.earnings(results) + "\n"
report += "## 3. Lifetime pay by highest education attained (share of lives · median lifetime pay)\n\n" + Report.education(results) + "\n"
report += "## 4. Degree attainment & schooling\n\n" + Report.schooling(results) + "\n"
report += "## 5. Salary trajectory (median / p90 among employed, employment rate in brackets)\n\n" + Report.salaries(results) + "\n"
report += "## 6. Competitive ladders\n\n" + Report.ladders(results) + "\n"
report += "## 7. Career dynamics (means per life)\n\n" + Report.dynamics(results) + "\n"
if results.contains(where: { $0.scenario.difficulty == .simplified }) {
    report += "## 8. Simplified goal\n\n" + Report.simplifiedGoal(results) + "\n"
}
report += "## 9. Most common first job, job at 25 and job at 45\n\n" + Report.topJobs(results) + "\n"
report += "## 10. Action mix (share of all years)\n\n" + Report.actionMix(results) + "\n"

if runSnapshot {
    let snapStart = Date()
    report += "## 11. Hire-odds snapshot (JobDetail odds at the default requested salary)\n\n"
    report += "Odds mean/p90 over random starting skills and a random starting economy; "
    report += "'steady economy' sets every industry climate to ×1.0. Skill fit = `Job.softSkillFit`, Edu × = `Job.educationFactor`.\n\n"
    report += Snapshot.run(samples: snapshotSamples)
    FileHandle.standardError.write("snapshot in \(String(format: "%.1f", Date().timeIntervalSince(snapStart)))s\n".data(using: .utf8)!)
}

let total = Date().timeIntervalSince(wallStart)
report += "\n_Total runtime: \(String(format: "%.0f", total))s._\n"
print(report)
if let outPath { try? report.write(toFile: outPath, atomically: true, encoding: .utf8) }

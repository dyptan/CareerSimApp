# BalanceSim — headless Monte Carlo life simulator

A balance-testing harness for Career Sim. It compiles the **real model layer**
(`Main/Models/*.swift` + `Main/Resources/JobCatalog.swift`) with plain `swiftc`,
plays thousands of complete lives with scripted policies, and prints markdown
tables of the outcomes (wealth, earnings, education, ladders, hire odds).

It never touches `Main/`, the tests or the Xcode project: the only SwiftUI
dependency the models have — `ActivityListView.offered` and
`ActivitiesView.availableTabs` — is re-declared in `ViewStubs.swift` with the
same bodies as the real views.

## Run

```sh
Tools/BalanceSim/run.sh                       # full baseline (~5 min on 12 cores)
Tools/BalanceSim/run.sh --lives 200 --young-lives 200 --snapshot 100   # quick pass
Tools/BalanceSim/run.sh --only "real life · advisor" --no-snapshot
Tools/BalanceSim/run.sh --out /tmp/baseline.md
```

`run.sh` builds to `$BALANCESIM_BIN` (default `$TMPDIR/balancesim`) and passes
its arguments through.

| Flag | Default | Meaning |
|---|---|---|
| `--lives N` | 600 | lives per start-at-18 scenario |
| `--young-lives N` | 600 | lives per start-at-7 scenario |
| `--snapshot N` | 400 | fresh players sampled for the hire-odds snapshot |
| `--threads N` | all cores | lives are independent and run in parallel |
| `--only S` | – | run only scenarios whose label contains `S` (case-insensitive) |
| `--no-snapshot` | – | skip the hire-odds / admission snapshot |
| `--out FILE` | – | also write the report to `FILE` |

The model uses the system RNG (it can't be seeded), so repeated runs differ by
sampling noise — about ±2 percentage points on shares at 600 lives.

## Fidelity

Every action goes through the same model calls, in the same order, as the view
that performs it in the app (see the header of `Harness.swift`):

- **Year loop** — `RootView.spendYear` → `Player.advanceYear(appUIState:)`, then
  RootView's `.onChange(of: player.age)` K-12 steps (ages 10/14/18) which live in
  the view. Start of game mirrors `ModeSelectionView.start`.
- **Jobs** — the Jobs sheet lists `player.availableJobs` minus ventures;
  `JobDetail` shows the posting `atBaseSalary()`, opens the salary slider at
  (and pays a posted-rate role) `job.offeredSalary(for:)`, disables Apply
  unless `allRequirementsMet`, then `applyForJob`.
  Administration roles keep the posting's own industry (the picker's default).
- **Education** — degrees listed from `offeredDegrees`, tiers as
  `InstitutionTiersView` builds them (Simplified: one community school), then
  `applyToSchool`; on admission the view's `enroll` drops the job, sets
  `currentEducation` and `yearsLeftToGraduation`. Tuition, graduation and loans
  then run inside `advanceYear`.
- **Courses/licences** — `TrainingRow.available` + its Take-button rules, then
  `attemptTraining`. **Activities** — `ActivityListView.offered` + `selectSport`.
- **Projects / Ventures / Boardroom** — `SideHustleRow`, `EntrepreneurshipView.launch`
  (one-tap stake) and `ExecutiveDecisionsView` (share sale at the slider's
  default, the fair value).
- Footer gating (`FooterView`) decides which sheets a policy may open.
- Every action spends the year, exactly like the app, so per-year limits hold
  by construction.

## Policies

| Policy | What it does |
|---|---|
| `advisor` | Each year acts on the top actionable `CareerAdvisor.tips` entry: applyNow → apply; train → the first missing course; study → the named degree at the `offeredDegrees` tier (state; community in Simplified); buildSkill → that activity; climb → the lever activity if named, else stay. No tip → the activity that best closes skill gaps for better-paid postings, else skip. |
| `typical` | A plausible average person: K-12 with an occasional hobby; at 18 goes to university with 40% probability (random field, state tier; rejected → community vocational; rejected → work); 15% of graduates try a master's; unemployed → best-odds posting paying at least a reservation wage (none/HS: any, vocational $35k, bachelor $45k, master+ $55k; falls back to best odds overall if that is under 15%); employed → every 2–4 years applies to the best-paid posting with odds ≥ 40% if one pays more; otherwise a hobby 15% of years. |
| `passive` | K-12, never studies, applies to the highest-odds posting whenever unemployed (from 18), otherwise skips. |
| `striver` | The advisor, plus the upside ladders it ignores: launches the best-paying venture once it has the expected industry years, ≥ 50% of the target stake within reach and ≥ 80% first-year survival (from 25, up to 3 ventures); raises rounds for scalable ventures; sells a founder stake after 6 years or a breakout; sells vested shares every year while in a hired executive seat. |
| `dreamer` | Soccer every school year (Junior Championship → pro "Player" ladder). With the junior title, applies up the Player ladder and stays there; otherwise (no title, or between contracts) holds the likeliest day job and spends every year on the Projects sheet chasing a Breakout Role, then starring in films. |

Scenarios: `advisor`, `typical`, `passive`, `striver` at 18 in Real Life and
Relaxed; `dreamer` at 18 in Real Life (no junior title possible, so it isolates
the screen-star route); `advisor`, `typical`, `dreamer` from 7 in Real Life;
`advisor`, `typical` from 7 in Simplified.

## Metrics

1. **Wealth at 65** — net worth (savings − student loan − venture loan)
   p10/median/mean/p90, share ≥ $1M and ≤ $0, median `leaderboardScore`.
2. **Lifetime gross pay** (pay actually banked by `advanceYear`; a layoff year
   banks `layoffYearPayShare` of it), project/endorsement income, student loan
   at 30, age at first job.
3. **Pay by highest education** — share of lives and median lifetime pay per
   bucket (none/HS, vocational, bachelor, master, doctorate).
4. **Schooling** — attainment, HS GPA, admissions, courses, years paid by a job
   while enrolled, and the share of no-degree 45-year-olds holding a job that
   expects a bachelor's or more.
5. **Salary trajectory** — pay at 25/35/45/55 (median/p90 among employed, with
   the employment rate), peak pay, share of ages 22–64 jobless or studying.
6. **Ladders** — ever reaching `isTopLeadership`, a non-founder `isExecutive`
   seat, a literal "Chief …" seat, a show-business star title (Breakout Role,
   Hit Record, Film Star, Headliner) or a Professional/Elite Player contract,
   the Player ladder at all, the Junior Champion title by 18, founding a
   venture (and the fold rate), any job in a health/law/engineering/science/
   education category (the categories where `educationIsMandatory`), a
   doctorate-level job.
7. **Career dynamics** — rung promotions, years with a merit (step) raise,
   layoffs, hires, job-to-job switches, applications and hire rate, Boardroom
   cash, and the share of years 22–64 lived in a declared recession.
8. **Simplified goal** — share reaching top leadership and at what age.
9. Most common first job / job at 25 / job at 45; 10. the action mix.
11. **Snapshots** — admission odds at 18 by upbringing, and the 15 postings
    with the highest `hireProbability` (at JobDetail's default ask, the offer
    `offeredSalary`) for a fresh 18-year-old HS graduate (Real Life and
    Relaxed), fresh 22-year-olds with a state Bachelor's in
    technology/business/health, and an 18-year-old raised
    by the advisor — Software Engineer is always shown for reference, and the
    graduates' tables also list their field's entry rungs.

## Files

- `main.swift` — arguments, scenario list, parallel runner, report assembly.
- `Harness.swift` — `Game`: one life driven through the UI flows; `LifeRecord`.
- `Policies.swift` — the five policies.
- `Metrics.swift` — statistics and the markdown tables.
- `Snapshot.swift` — hire-odds and admission snapshots.
- `ViewStubs.swift` — headless copies of the two view helpers the models call.
- `run.sh` — build + run.

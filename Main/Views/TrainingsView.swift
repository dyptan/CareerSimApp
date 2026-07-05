import SwiftUI

extension View {
    /// Toggle style appropriate for the current platform (.checkbox on macOS, .switch on iOS).
    @ViewBuilder
    func platformToggleStyle() -> some View {
        #if os(macOS)
        self.toggleStyle(.checkbox)
        #elseif os(iOS)
        self.toggleStyle(.switch)
        #else
        self
        #endif
    }
}

/// The **Trainings** page — the unified home for professional credentials, the
/// merger of the old Certifications and Licenses sheets. Every training is
/// earned the same way: it costs a fee and a spare-time slot, and a year's
/// attempt rolls a pass against `Training.passProbability` (soft skills set the
/// odds). Age, education, prerequisite trainings, and — for senior credentials —
/// work experience are hard gates on *attempting*; a blocked training shows why.
struct TrainingsView: View {
    @ObservedObject var player: Player

    @Binding var selectedTrainings: Set<Training>
    @Binding var selectedActivities: Set<String>

    private var currentStage: LifeStage { LifeStage.forAge(player.age) }

    private var sortedTrainings: [Training] {
        Training.allCases
            .filter { $0.stages.contains(currentStage) }
            .sorted { $0.friendlyName < $1.friendlyName }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if sortedTrainings.isEmpty {
                    Text("Professional trainings unlock as you get older and finish school.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    ForEach(sortedTrainings, id: \.rawValue) { training in
                        row(for: training)
                            .padding(.vertical, 4)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }

    @ViewBuilder
    private func row(for training: Training) -> some View {
        // Owned if already earned (locked / in hard skills) or passed this year.
        let isOwned = player.lockedTrainings.contains(training)
            || player.hardSkills.trainings.contains(training)
            || selectedTrainings.contains(training)
        let attemptedThisYear = player.attemptedTrainingIds.contains(training.rawValue)
        let atLimit = selectedActivities.count >= GameConstants.trainingActivitySlotCost
        let cost = training.cost
        let canAfford = player.savings >= cost

        let blockedReason: String? = {
            if case .blocked(let reason) = training.requirements(player) { return reason }
            return nil
        }()
        let gatesMet = blockedReason == nil
        let passChance = training.passProbability(for: player)
        // Can sit the exam: eligible, not already owned/attempted, slot free.
        // Affordability is NOT a gate — an unaffordable fee just goes into debt.
        let canAttempt = gatesMet && !isOwned && !attemptedThisYear && !atLimit

        // Soft skills that drive the pass odds, with the level each weighs in at —
        // surfaced in the info hint so the player knows what to build toward.
        let softSkillsHint: String = training.softSkillThresholds
            .map { pair in
                let label = SoftSkills.label(forKeyPath: pair.0) ?? ""
                let pic = SoftSkills.pictogram(forKeyPath: pair.0) ?? "🧩"
                return "\(pic) \(label) (weighs in at \(pair.1))"
            }
            .joined(separator: "\n")
        let hintMessage: String = softSkillsHint.isEmpty
            ? training.description
            : "\(training.description)\n\nSoft skills that set your pass odds:\n\n\(softSkillsHint)"

        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                InfoHint(title: "\(training.pictogram) \(training.friendlyName)", message: hintMessage)
                Text(training.friendlyName)
                    .font(.body)
                if training.isStatutory {
                    Text("licence")
                        .font(.caption2)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.blue.opacity(0.15), in: Capsule())
                }
                Spacer()
                if isOwned {
                    Text("✓ Earned")
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                }
            }

            Text(canAfford
                 ? "Cost $\(cost.formatted(.number)) (course + exam)"
                 : "Cost $\(cost.formatted(.number)) (course + exam) — paid on credit")
                .font(.caption)
                .foregroundStyle(canAfford ? Color.secondary : Color.orange)
                .padding(.leading, 8)

            // Pass odds (realistic mode only — simplified is a guaranteed pass).
            if !player.isSimplified && !isOwned {
                HStack(spacing: 6) {
                    Text("Pass chance:")
                    Spacer()
                    Text(gatesMet ? "\(Int((passChance * 100).rounded())) %" : "—")
                        .font(.subheadline.bold())
                        .foregroundStyle(passChance >= 0.6 ? .green : passChance >= 0.3 ? .orange : .red)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
            }

            if !isOwned {
                Button {
                    let passed = player.attemptTraining(training, into: &selectedTrainings, activities: &selectedActivities)
                    // Passing against long odds is worth a celebration.
                    if passed, passChance <= GameConstants.luckyAdmissionThreshold {
                        player.celebrationTrigger += 1
                    }
                } label: {
                    Text(attemptButtonLabel(attempted: attemptedThisYear, atLimit: atLimit, blockedReason: blockedReason))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canAttempt)
                .opacity(canAttempt ? 1.0 : 0.5)
                .padding(.top, 2)

                if attemptedThisYear {
                    Text("❌ Didn't pass this year — build the skills below and retry next year.")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.leading, 8)
                }
            }

            if !isOwned {
                let highestEQF = player.degrees.map(\.eqf).max() ?? 0
                VStack(alignment: .leading, spacing: 4) {
                    // Hard requirements — must all be met to sit the exam. Shown
                    // as met/unmet badges alongside the soft-skill odds below.
                    Text("Requirements")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                    RequirementRow(
                        label: "Age \(training.minAge)+",
                        emoji: "🎂",
                        style: .badge(isMet: player.age >= training.minAge)
                    )
                    if training.minEQF > 0 {
                        RequirementRow(
                            label: Education.Requirements(minEQF: training.minEQF).educationLabel(),
                            emoji: "🎓",
                            style: .badge(isMet: highestEQF >= training.minEQF)
                        )
                    }
                    ForEach(training.prerequisites, id: \.self) { prereq in
                        RequirementRow(
                            label: prereq.friendlyName,
                            emoji: prereq.pictogram,
                            style: .badge(isMet: player.hardSkills.trainings.contains(prereq))
                        )
                    }
                    if training.minYearsExperience > 0 {
                        RequirementRow(
                            label: "\(training.minYearsExperience) yrs work experience",
                            emoji: "💼",
                            style: .badge(isMet: player.totalYearsWorked >= training.minYearsExperience)
                        )
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func attemptButtonLabel(attempted: Bool, atLimit: Bool, blockedReason: String?) -> String {
        if blockedReason != nil { return "Requirements not met" }
        if attempted { return "Attempted this year" }
        if atLimit { return "Only \(GameConstants.trainingActivitySlotCost) activity per year" }
        return player.isSimplified ? "Take Training" : "Sit Exam"
    }
}

#Preview {
    struct Container: View {
        @State var selected: Set<Training> = []
        @State var acts: Set<String> = []
        @StateObject var player = Player()
        var body: some View {
            NavigationView {
                TrainingsView(player: player, selectedTrainings: $selected, selectedActivities: $acts)
            }
        }
    }
    return Container()
}

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
/// merger of the old Certifications and Licenses sheets. It shares its layout and
/// the single spare-time slot with Hobbies and Sports: picking a training this
/// year displaces any other activity. Once the hard gates are met the credential
/// is earned outright (no exam roll), and completing the course nudges the soft
/// skills it builds. Age, education, prerequisite trainings, and — for senior
/// credentials — work experience are the hard gates; a blocked training shows why.
struct TrainingsView: View {
    @ObservedObject var player: Player

    @Binding var selectedTrainings: Set<Training>
    @Binding var selectedActivities: Set<String>

    private var currentStage: LifeStage { LifeStage.forAge(player.age) }

    private var sortedTrainings: [Training] {
        Training.allCases
            .filter { $0.stages.contains(currentStage) }
            // Age is a visibility gate, not a disabled row: a training the player
            // is too young for simply doesn't appear until they can attempt it.
            .filter { player.age >= $0.minAge }
            .sorted { $0.friendlyName < $1.friendlyName }
    }

    var body: some View {
        VStack {
            HStack(spacing: 6) {
                Text("Training this year:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(selectedActivities.count)/\(GameConstants.trainingActivitySlotCost)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(
                        selectedActivities.count >= GameConstants.trainingActivitySlotCost
                            ? .red : .primary
                    )
            }
            Text("\(currentStage.displayName) — age \(player.age)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()

            ScrollView {
                VStack(spacing: 10) {
                    if sortedTrainings.isEmpty {
                        Text("Professional trainings unlock as you get older and finish school.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        ForEach(sortedTrainings, id: \.rawValue) { training in
                            row(for: training)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private func row(for training: Training) -> some View {
        // Earned in a prior year (permanent) vs. picked this year (reversible).
        let isEarned = player.lockedTrainings.contains(training)
            || player.hardSkills.trainings.contains(training)
        let isSelectedThisYear = selectedTrainings.contains(training)
        let atLimit = selectedActivities.count >= GameConstants.trainingActivitySlotCost

        let blockedReason: String? = {
            if case .blocked(let reason) = training.requirements(player) { return reason }
            return nil
        }()
        let gatesMet = blockedReason == nil
        // Can switch on only if eligible and the shared slot is free.
        let canToggleOn = gatesMet && !atLimit
        let isDisabled = isEarned || (!isSelectedThisYear && !canToggleOn)

        // Soft skills the completed course builds — surfaced in the hint.
        let boostsHint: String = training.softSkillBoosts
            .map { boost in
                let label = SoftSkills.label(forKeyPath: boost.keyPath) ?? ""
                let pic = SoftSkills.pictogram(forKeyPath: boost.keyPath) ?? "🧩"
                return "\(pic) \(label) (+\(boost.weight))"
            }
            .joined(separator: "\n")
        // Hard requirements — education, prerequisite trainings, and work
        // experience — shown in the hint as met/unmet (✅/❌) lines rather than
        // inline badges, so the row itself stays compact.
        let requirementsHint: String = {
            guard !isEarned else { return "" }
            let highestEQF = player.degrees.map(\.eqf).max() ?? 0
            var lines: [String] = []
            if training.minEQF > 0 {
                let met = highestEQF >= training.minEQF
                lines.append("\(met ? "✅" : "❌") 🎓 \(Education.Requirements(minEQF: training.minEQF).educationLabel())")
            }
            for prereq in training.prerequisites {
                let met = player.hardSkills.trainings.contains(prereq)
                lines.append("\(met ? "✅" : "❌") \(prereq.pictogram) \(prereq.friendlyName)")
            }
            if training.minYearsExperience > 0 {
                let fieldYears = training.field.map { player.experience[$0] ?? 0 } ?? player.totalYearsWorked
                let met = fieldYears >= training.minYearsExperience
                let expLabel = training.field.map { "\(training.minYearsExperience) yrs in \($0.rawValue)" }
                    ?? "\(training.minYearsExperience) yrs work experience"
                lines.append("\(met ? "✅" : "❌") 💼 \(expLabel)")
            }
            guard !lines.isEmpty else { return "" }
            return "\n\nRequirements:\n\n" + lines.joined(separator: "\n")
        }()
        let hintMessage: String = {
            let base = boostsHint.isEmpty
                ? training.description
                : "\(training.description)\n\nCompleting this course builds:\n\n\(boostsHint)"
            return base + requirementsHint
        }()

        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Toggle(
                    isOn: Binding(
                        get: { isEarned || isSelectedThisYear },
                        set: { isOn in
                            if isOn {
                                guard canToggleOn else { return }
                                player.attemptTraining(training, into: &selectedTrainings, activities: &selectedActivities)
                            } else {
                                player.cancelTraining(training, from: &selectedTrainings, activities: &selectedActivities)
                            }
                        }
                    )
                ) {
                    HStack(spacing: 6) {
                        Text("\(training.pictogram) \(training.friendlyName)")
                            .font(.body)
                        if training.isStatutory {
                            Text("licence")
                                .font(.caption2)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(Color.blue.opacity(0.15), in: Capsule())
                        }
                        if isEarned {
                            Text("✓ Earned")
                                .font(.caption.bold())
                                .foregroundStyle(.green)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .platformToggleStyle()
                .disabled(isDisabled)
                .opacity(isDisabled && !isEarned ? 0.5 : 1.0)
                .help(helpText(blockedReason: blockedReason, atLimit: atLimit, isSelected: isSelectedThisYear))

                InfoHint(title: "\(training.pictogram) \(training.friendlyName)", message: hintMessage)
            }

            // A concise lock reason for a blocked training; the full met/unmet
            // requirement breakdown lives in the info hint. Age isn't listed:
            // it's a visibility gate.
            if !isEarned, let blockedReason {
                Text("🔒 \(blockedReason)")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 24)
            }
        }
        .padding(5)
    }

    private func helpText(blockedReason: String?, atLimit: Bool, isSelected: Bool) -> String {
        if let blockedReason { return blockedReason }
        if atLimit && !isSelected {
            return "You can commit to one activity per year — drop your current pick first."
        }
        return ""
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

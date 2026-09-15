import SwiftUI

/// Second level of the education nav stack — everything this field of study
/// offers, in the order you would climb it: the degree levels (Vocational /
/// Bachelor / Master / Doctorate), each navigating into `InstitutionTiersView`,
/// then the professional courses filed under the same profile (see
/// `Training.profile`) — the EMT course sits with the health degrees. Licences
/// are not courses of study and stay in their own list on the sheet root.
struct DegreesSubmenuView: View {
    @ObservedObject var player: Player
    let profile: TertiaryProfile
    @Binding var yearsLeftToGraduation: Int?
    @Binding var showTertiarySheet: Bool
    @Binding var selectedTrainings: Set<Training>
    @Binding var selectedActivities: Set<String>
    var onCommit: () -> Void = {}

    private var courses: [Training] {
        TrainingRow.available(for: player).filter { $0.profile == profile }
    }

    private var degrees: [Education] {
        player.offeredDegrees
            .filter { $0.profile == profile }
            .sorted { lhs, rhs in
                let order: [Level.Stage: Int] = [
                    .Vocational: 0, .Bachelor: 1, .Master: 2, .Doctorate: 3,
                ]
                return (order[lhs.level] ?? 99) < (order[rhs.level] ?? 99)
            }
    }

    var body: some View {
        List {
            if !degrees.isEmpty {
                Section("Degrees") {
                    ForEach(Array(degrees.enumerated()), id: \.element.id) { _, education in
                        NavigationLink {
                            InstitutionTiersView(
                                player: player,
                                level: education.level,
                                profile: profile,
                                yearsLeftToGraduation: $yearsLeftToGraduation,
                                showTertiarySheet: $showTertiarySheet,
                                onCommit: onCommit
                            )
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(education.degreeName)
                                        .font(.headline)
                                    InfoHint(
                                        title: "\(education.pictogram) \(education.degreeName)",
                                        message: degreeHintBody(for: education)
                                    )
                                }
                                Text(player.isSimplified
                                     ? "\(education.yearsToComplete) years"
                                     : "\(education.yearsToComplete) years • compare schools")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
            if !courses.isEmpty {
                Section("Courses") {
                    ForEach(courses, id: \.rawValue) { training in
                        TrainingRow(
                            training: training,
                            player: player,
                            selectedTrainings: $selectedTrainings,
                            selectedActivities: $selectedActivities,
                            onCommit: onCommit
                        )
                    }
                }
            }
        }
        .navigationTitle(profile.rawValue.capitalized)
        .frame(minHeight: 400)
    }

    /// Combine the Stage explanation with what this profile actually teaches.
    private func degreeHintBody(for education: Education) -> String {
        let levelText = Level(stage: education.level).description
        if let prof = education.profile {
            return "\(levelText)\n\n\(prof.degreeMeaning)"
        }
        return levelText
    }
}

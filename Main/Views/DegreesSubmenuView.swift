import SwiftUI

/// Second level of the education nav stack — lists the degree levels available for a profile
/// (Vocational / Bachelor / Master / Doctorate). Each row navigates into InstitutionTiersView.
struct DegreesSubmenuView: View {
    @ObservedObject var player: Player
    let profile: TertiaryProfile
    @Binding var yearsLeftToGraduation: Int?
    @Binding var showTertiarySheet: Bool

    private var degrees: [Education] {
        let availableEducations = availableNextEducations(holds: player.degrees)
        return availableEducations
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
            ForEach(Array(degrees.enumerated()), id: \.element.id) { _, education in
                NavigationLink {
                    InstitutionTiersView(
                        player: player,
                        level: education.level,
                        profile: profile,
                        yearsLeftToGraduation: $yearsLeftToGraduation,
                        showTertiarySheet: $showTertiarySheet
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

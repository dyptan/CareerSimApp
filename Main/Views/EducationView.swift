import SwiftUI

/// The **Education** sheet — every way to spend a year learning, in one place.
/// Degrees lead into the profile → degree → institution flow; the courses below
/// them are the professional credentials and licences (see `TrainingRow`), which
/// are picked inline because a course is a single yes-or-no commitment rather
/// than a choice of school.
struct EducationView: View {
    @ObservedObject var player: Player

    @Binding var yearsLeftToGraduation: Int?
    @Binding var showTertiarySheet: Bool
    @Binding var showCareersSheet: Bool
    @Binding var selectedTrainings: Set<Training>
    @Binding var selectedActivities: Set<String>
    /// Advances the game year and dismisses, via the shared **Next ▸** control.
    var onNext: (() -> Void)? = nil

    private var availableEducations: [Education] {
        availableNextEducations(holds: player.degrees)
    }

    private var availableProfiles: [TertiaryProfile] {
        let profiles = availableEducations.compactMap { $0.profile }
        let unique = Set(profiles)
        return unique.sorted { $0.rawValue < $1.rawValue }
    }

    private var availableTrainings: [Training] {
        TrainingRow.available(for: player)
    }

    var body: some View {
        Group {
            if #available(iOS 16, macOS 13, *) {
                NavigationStack {
                    content
                }
            } else {
                NavigationView {
                    content
                }
                #if os(iOS)
                    .navigationViewStyle(.stack)
                #endif
            }
        }
        .frame(minHeight: 500)
    }

    private var content: some View {
        List {
            if !availableProfiles.isEmpty {
                Section("Degrees") {
                    ForEach(availableProfiles, id: \.self) { profile in
                        NavigationLink {
                            DegreesSubmenuView(
                                player: player,
                                profile: profile,
                                yearsLeftToGraduation: $yearsLeftToGraduation,
                                showTertiarySheet: $showTertiarySheet
                            )
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 6) {
                                    Text(profile.rawValue.capitalized)
                                        .font(.headline)
                                    InfoHint(
                                        title: profile.rawValue.capitalized,
                                        message: "\(profile.degreeMeaning)\n\nLikely jobs: \(profile.helpfulJobs)."
                                    )
                                }
                                Text(profile.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
            if !availableTrainings.isEmpty {
                Section("Courses & licences") {
                    ForEach(availableTrainings, id: \.rawValue) { training in
                        TrainingRow(
                            training: training,
                            player: player,
                            selectedTrainings: $selectedTrainings,
                            selectedActivities: $selectedActivities
                        )
                    }
                }
            }
            if availableProfiles.isEmpty, availableTrainings.isEmpty {
                Text("Degrees and professional courses unlock as you get older and finish school.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            }
        }
        .gameSheetClose($showTertiarySheet, title: "Education", onNext: onNext)
    }

    private func degrees(for profile: TertiaryProfile) -> [Education] {
        availableEducations
            .filter { $0.profile == profile }
            .sorted { lhs, rhs in
                let order: [Level.Stage: Int] = [
                    .Vocational: 0, .Bachelor: 1, .Master: 2, .Doctorate: 3,
                ]
                return (order[lhs.level] ?? 99) < (order[rhs.level] ?? 99)
            }
    }
}

#Preview {
    EducationView(
        player: Player(),
        yearsLeftToGraduation: .constant(nil),
        showTertiarySheet: .constant(true),
        showCareersSheet: .constant(false),
        selectedTrainings: .constant([]),
        selectedActivities: .constant([])
    )
}


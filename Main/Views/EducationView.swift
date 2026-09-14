import SwiftUI

/// The **Education** sheet — every way to spend a year learning, in one place.
/// The top level is the fields of study; each one leads to its degrees *and* the
/// professional courses and licences filed under it (see `Training.profile`), so
/// a nursing licence is found where the health degrees are rather than in a list
/// of its own.
///
/// The one section that stays here is the licences. A licence qualifies you to
/// practise rather than teaching you a field, so it sits on its own rather than
/// under a faculty. Both kinds are picked inline, since a course is a yes-or-no
/// commitment rather than a choice of school.
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

    /// Fields of study with something to offer this year — a degree still to
    /// take, a course still to earn, or both. A field whose degrees are all
    /// behind the player still appears while it has courses left, which is how
    /// a qualified doctor still finds their board certification.
    private var availableProfiles: [TertiaryProfile] {
        let fromDegrees = availableEducations.compactMap { $0.profile }
        let fromCourses = availableTrainings.compactMap { $0.profile }
        return Set(fromDegrees + fromCourses).sorted { $0.rawValue < $1.rawValue }
    }

    private var availableTrainings: [Training] {
        TrainingRow.available(for: player)
    }

    /// The licences, which belong to no field of study and so are listed here
    /// rather than under a faculty (see `Training.profile`).
    private var generalCourses: [Training] {
        availableTrainings.filter { $0.profile == nil }
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
                Section("Fields of study") {
                    ForEach(availableProfiles, id: \.self) { profile in
                        NavigationLink {
                            DegreesSubmenuView(
                                player: player,
                                profile: profile,
                                yearsLeftToGraduation: $yearsLeftToGraduation,
                                showTertiarySheet: $showTertiarySheet,
                                selectedTrainings: $selectedTrainings,
                                selectedActivities: $selectedActivities
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
            if !generalCourses.isEmpty {
                Section("Licences") {
                    ForEach(generalCourses, id: \.rawValue) { training in
                        TrainingRow(
                            training: training,
                            player: player,
                            selectedTrainings: $selectedTrainings,
                            selectedActivities: $selectedActivities
                        )
                    }
                }
            }
            if availableProfiles.isEmpty, generalCourses.isEmpty {
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


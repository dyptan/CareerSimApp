import SwiftUI

struct EducationView: View {
    @ObservedObject var player: Player

    @Binding var yearsLeftToGraduation: Int?
    @Binding var showTertiarySheet: Bool
    @Binding var showCareersSheet: Bool

    private var availableEducations: [Education] {
        availableNextEducations(holds: player.degrees)
    }

    private var availableProfiles: [TertiaryProfile] {
        let profiles = availableEducations.compactMap { $0.profile }
        let unique = Set(profiles)
        return unique.sorted { $0.rawValue < $1.rawValue }
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
        showCareersSheet: .constant(false)
    )
}


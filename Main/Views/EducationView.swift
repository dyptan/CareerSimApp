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
                        .navigationTitle("Education")
                }
            } else {
                NavigationView {
                    content
                        .navigationTitle("Education")
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
            Section {
                ForEach(availableProfiles, id: \.self) { profile in
                    NavigationLink {
                        DegreesSubmenuView(
                            player: player,
                            profile: profile,
                            degrees: degrees(for: profile),
                            yearsLeftToGraduation: $yearsLeftToGraduation,
                            showTertiarySheet: $showTertiarySheet
                        )
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(profile.rawValue.capitalized)
                                .font(.headline)
                            Text(profile.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                    }
                }
            } header: {
                Text("Pick your education direction")
            }

            Section {
                Button("Find a job") {
                    showCareersSheet = true
                    showTertiarySheet = false
                }
                .foregroundStyle(.secondary)
            }
        }
    }

    private func degrees(for profile: TertiaryProfile) -> [Education] {
        availableEducations
            .filter { $0.profile == profile }
            .sorted { lhs, rhs in
                let order: [Level.Stage: Int] = [.Vocational: 0, .Bachelor: 1, .Master: 2, .Doctorate: 3]
                return (order[lhs.level] ?? 99) < (order[rhs.level] ?? 99)
            }
    }
}

// MARK: - Submenu: Degrees for a profile

private struct DegreesSubmenuView: View {
    @ObservedObject var player: Player
    let profile: TertiaryProfile
    let degrees: [Education]
    @Binding var yearsLeftToGraduation: Int?
    @Binding var showTertiarySheet: Bool

    var body: some View {
        List {
            Section {
                ForEach(degrees) { education in
                    Button {
                        player.currentOccupation = nil
                        player.currentEducation = education
                        yearsLeftToGraduation = education.yearsToComplete
                        showTertiarySheet = false
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(education.degreeName)
                                .font(.headline)
                            Text("Takes \(education.yearsToComplete) years")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                    }
                }
            } header: {
                Text(profile.rawValue.capitalized)
            }
        }
        .navigationTitle(profile.rawValue.capitalized)
        .frame(minHeight: 400)
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

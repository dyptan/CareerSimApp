import SwiftUI

struct HardSkillsView: View {
    @Binding var selectedCertifications: Set<Certification>
    @Binding var selectedLicences: Set<License>
    @Binding var selectedLanguages: Set<ProgrammingLanguage>
    @Binding var selectedSoftware: Set<Software>
    @Binding var selectedPortfolio: Set<PortfolioItem>
    @Binding var selectedActivities: Set<String>

    @EnvironmentObject private var player: Player

    private let maxActivitiesPerYear = 3

    var body: some View {
        VStack(spacing: 20) {
            CertificationsView(
                selectedCertifications: $selectedCertifications,
                selectedActivities: $selectedActivities
            )
            .environmentObject(player)

            Divider()

            LicensesView(
                selectedLicences: $selectedLicences,
                selectedActivities: $selectedActivities
            )
            .environmentObject(player)

            Divider()

            LanguagesView(
                selectedLanguages: $selectedLanguages,
                selectedActivities: $selectedActivities
            )
            .environmentObject(player)

            Divider()

            SoftwareView(
                selectedSoftware: $selectedSoftware,
                selectedActivities: $selectedActivities
            )
            .environmentObject(player)

            Divider()

            PortfolioView(
                selectedPortfolio: $selectedPortfolio,
                selectedActivities: $selectedActivities
            )
            .environmentObject(player)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Certifications (consumes activity slots, respects lockedCertifications)

private struct CertificationsView: View {
    @Binding var selectedCertifications: Set<Certification>
    @Binding var selectedActivities: Set<String>
    @EnvironmentObject private var player: Player

    private let maxActivitiesPerYear = 3

    private var sortedCertifications: [Certification] {
        Certification.allCases.sorted(by: { $0.rawValue < $1.rawValue })
    }

    var body: some View {
        VStack(spacing: 12) {
            counterRow

            Text("Certifications:")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(sortedCertifications, id: \.self) { cert in
                let isLocked = player.lockedCertifications.contains(cert)
                let isSelected = selectedCertifications.contains(cert)
                let atLimit = selectedActivities.count >= maxActivitiesPerYear

                Toggle(
                    cert.friendlyName,
                    isOn: Binding(
                        get: { isSelected },
                        set: { isOn in
                            guard !isLocked else { return }
                            if isOn {
                                if !atLimit {
                                    selectedCertifications.insert(cert)
                                    selectedActivities.insert(
                                        "cert:\(cert.rawValue)"
                                    )
                                }
                            } else {
                                if selectedCertifications.remove(cert) != nil {
                                    selectedActivities.remove(
                                        "cert:\(cert.rawValue)"
                                    )
                                }
                            }
                        }
                    )
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .disabled(isLocked || (!isSelected && atLimit))
                .opacity((isLocked || (!isSelected && atLimit)) ? 0.5 : 1.0)
                .help(
                    isLocked
                        ? "Locked after year end"
                        : ((!isSelected && atLimit)
                            ? "You can take up to \(maxActivitiesPerYear) activities this year."
                            : "")
                )
                #if os(macOS)
                    .toggleStyle(.checkbox)
                #endif
                #if os(iOS)
                    .toggleStyle(.switch)
                #endif
            }
        }
    }

    private var counterRow: some View {
        HStack(spacing: 6) {
            Text("Activities this year:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(selectedActivities.count)/\(maxActivitiesPerYear)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(
                    selectedActivities.count >= maxActivitiesPerYear
                        ? .red : .primary
                )
            Spacer()
        }
    }
}

// MARK: - Licenses (consumes activity slots, respects lockedLicenses)

private struct LicensesView: View {
    @Binding var selectedLicences: Set<License>
    @Binding var selectedActivities: Set<String>
    @EnvironmentObject private var player: Player

    private let maxActivitiesPerYear = 3

    private var sortedLicenses: [License] {
        License.allCases.sorted(by: { $0.rawValue < $1.rawValue })
    }

    var body: some View {
        VStack(spacing: 12) {
            counterRow

            Text("Licenses:")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(sortedLicenses, id: \.self) { lic in
                let isLocked = player.lockedLicenses.contains(lic)
                let isSelected = selectedLicences.contains(lic)
                let atLimit = selectedActivities.count >= maxActivitiesPerYear

                Toggle(
                    lic.friendlyName,
                    isOn: Binding(
                        get: { isSelected },
                        set: { isOn in
                            guard !isLocked else { return }
                            if isOn {
                                if !atLimit {
                                    selectedLicences.insert(lic)
                                    selectedActivities.insert(
                                        "lic:\(lic.rawValue)"
                                    )
                                }
                            } else {
                                if selectedLicences.remove(lic) != nil {
                                    selectedActivities.remove(
                                        "lic:\(lic.rawValue)"
                                    )
                                }
                            }
                        }
                    )
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .disabled(isLocked || (!isSelected && atLimit))
                .opacity((isLocked || (!isSelected && atLimit)) ? 0.5 : 1.0)
                .help(
                    isLocked
                        ? "Locked after year end"
                        : ((!isSelected && atLimit)
                            ? "You can take up to \(maxActivitiesPerYear) activities this year."
                            : "")
                )
                #if os(macOS)
                    .toggleStyle(.checkbox)
                #endif
                #if os(iOS)
                    .toggleStyle(.switch)
                #endif
            }
        }
    }

    private var counterRow: some View {
        HStack(spacing: 6) {
            Text("Activities this year:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(selectedActivities.count)/\(maxActivitiesPerYear)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(
                    selectedActivities.count >= maxActivitiesPerYear
                        ? .red : .primary
                )
            Spacer()
        }
    }
}

// MARK: - Languages (consumes activity slots, respects lockedLanguages)

private struct LanguagesView: View {
    @Binding var selectedLanguages: Set<ProgrammingLanguage>
    @Binding var selectedActivities: Set<String>
    @EnvironmentObject private var player: Player

    private let maxActivitiesPerYear = 3

    private var sortedLanguages: [ProgrammingLanguage] {
        ProgrammingLanguage.allCases.sorted(by: { $0.rawValue < $1.rawValue })
    }

    var body: some View {
        VStack(spacing: 12) {
            counterRow

            Text("Languages:")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(sortedLanguages, id: \.self) { lang in
                let isLocked = player.lockedLanguages.contains(lang)
                let isSelected = selectedLanguages.contains(lang)
                let atLimit = selectedActivities.count >= maxActivitiesPerYear

                Toggle(
                    "Language: \(lang.rawValue) \(lang.pictogram)",
                    isOn: Binding(
                        get: { isSelected },
                        set: { isOn in
                            guard !isLocked else { return }
                            if isOn {
                                if !atLimit {
                                    selectedLanguages.insert(lang)
                                    selectedActivities.insert(
                                        "lang:\(lang.rawValue)"
                                    )
                                }
                            } else {
                                if selectedLanguages.remove(lang) != nil {
                                    selectedActivities.remove(
                                        "lang:\(lang.rawValue)"
                                    )
                                }
                            }
                        }
                    )
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .disabled(isLocked || (!isSelected && atLimit))
                .opacity((isLocked || (!isSelected && atLimit)) ? 0.5 : 1.0)
                .help(
                    isLocked
                        ? "Locked after year end"
                        : ((!isSelected && atLimit)
                            ? "You can take up to \(maxActivitiesPerYear) activities this year."
                            : "")
                )
                #if os(macOS)
                    .toggleStyle(.checkbox)
                #endif
                #if os(iOS)
                    .toggleStyle(.switch)
                #endif
            }
        }
    }

    private var counterRow: some View {
        HStack(spacing: 6) {
            Text("Activities this year:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(selectedActivities.count)/\(maxActivitiesPerYear)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(
                    selectedActivities.count >= maxActivitiesPerYear
                        ? .red : .primary
                )
            Spacer()
        }
    }
}

// MARK: - Software (consumes activity slots, respects lockedSoftware)

private struct SoftwareView: View {
    @Binding var selectedSoftware: Set<Software>
    @Binding var selectedActivities: Set<String>
    @EnvironmentObject private var player: Player

    private let maxActivitiesPerYear = 3

    private var sortedSoftware: [Software] {
        Software.allCases.sorted(by: { $0.rawValue < $1.rawValue })
    }

    var body: some View {
        VStack(spacing: 12) {
            counterRow

            Text("Software:")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(sortedSoftware, id: \.self) { sw in
                let isLocked = player.lockedSoftware.contains(sw)
                let isSelected = selectedSoftware.contains(sw)
                let atLimit = selectedActivities.count >= maxActivitiesPerYear

                Toggle(
                    "Software: \(sw.rawValue) \(sw.pictogram)",
                    isOn: Binding(
                        get: { isSelected },
                        set: { isOn in
                            guard !isLocked else { return }
                            if isOn {
                                if !atLimit {
                                    selectedSoftware.insert(sw)
                                    selectedActivities.insert(
                                        "soft:\(sw.rawValue)"
                                    )
                                }
                            } else {
                                if selectedSoftware.remove(sw) != nil {
                                    selectedActivities.remove(
                                        "soft:\(sw.rawValue)"
                                    )
                                }
                            }
                        }
                    )
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .disabled(isLocked || (!isSelected && atLimit))
                .opacity((isLocked || (!isSelected && atLimit)) ? 0.5 : 1.0)
                .help(
                    isLocked
                        ? "Locked after year end"
                        : ((!isSelected && atLimit)
                            ? "You can take up to \(maxActivitiesPerYear) activities this year."
                            : "")
                )
                #if os(macOS)
                    .toggleStyle(.checkbox)
                #endif
                #if os(iOS)
                    .toggleStyle(.switch)
                #endif
            }
        }
    }

    private var counterRow: some View {
        HStack(spacing: 6) {
            Text("Activities this year:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(selectedActivities.count)/\(maxActivitiesPerYear)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(
                    selectedActivities.count >= maxActivitiesPerYear
                        ? .red : .primary
                )
            Spacer()
        }
    }
}

// MARK: - Portfolio (consumes activity slots, respects lockedPortfolio)

private struct PortfolioView: View {
    @Binding var selectedPortfolio: Set<PortfolioItem>
    @Binding var selectedActivities: Set<String>
    @EnvironmentObject private var player: Player

    private let maxActivitiesPerYear = 3

    private var sortedPortfolio: [PortfolioItem] {
        PortfolioItem.allCases.sorted(by: { $0.rawValue < $1.rawValue })
    }

    var body: some View {
        VStack(spacing: 12) {
            counterRow

            Text("Portfolio Items:")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(sortedPortfolio, id: \.self) { item in
                let isLocked = player.lockedPortfolio.contains(item)
                let isSelected = selectedPortfolio.contains(item)
                let atLimit = selectedActivities.count >= maxActivitiesPerYear

                Toggle(
                    "Portfolio: \(item.rawValue) \(item.pictogram)",
                    isOn: Binding(
                        get: { isSelected },
                        set: { isOn in
                            guard !isLocked else { return }
                            if isOn {
                                if !atLimit {
                                    selectedPortfolio.insert(item)
                                    selectedActivities.insert(
                                        "port:\(item.rawValue)"
                                    )
                                }
                            } else {
                                if selectedPortfolio.remove(item) != nil {
                                    selectedActivities.remove(
                                        "port:\(item.rawValue)"
                                    )
                                }
                            }
                        }
                    )
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .disabled(isLocked || (!isSelected && atLimit))
                .opacity((isLocked || (!isSelected && atLimit)) ? 0.5 : 1.0)
                .help(
                    isLocked
                        ? "Locked after year end"
                        : ((!isSelected && atLimit)
                            ? "You can take up to \(maxActivitiesPerYear) activities this year."
                            : "")
                )
                #if os(macOS)
                    .toggleStyle(.checkbox)
                #endif
                #if os(iOS)
                    .toggleStyle(.switch)
                #endif
            }
        }
    }

    private var counterRow: some View {
        HStack(spacing: 6) {
            Text("Activities this year:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(selectedActivities.count)/\(maxActivitiesPerYear)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(
                    selectedActivities.count >= maxActivitiesPerYear
                        ? .red : .primary
                )
            Spacer()
        }
    }
}

#Preview {
    @Previewable @State var certs = Set<Certification>()
    @Previewable @State var lic = Set<License>()
    @Previewable @State var langs = Set<ProgrammingLanguage>()
    @Previewable @State var soft = Set<Software>()
    @Previewable @State var port = Set<PortfolioItem>()
    @Previewable @State var acts = Set<String>()
    HardSkillsView(
        selectedCertifications: $certs,
        selectedLicences: $lic,
        selectedLanguages: $langs,
        selectedSoftware: $soft,
        selectedPortfolio: $port,
        selectedActivities: $acts
    )
    .environmentObject(Player())
    .padding()
}

import SwiftUI

struct HardSkillsView: View {
    @Binding var selectedCertifications: Set<Certification>
    @Binding var selectedLicences: Set<License>
    @Binding var selectedSoftware: Set<Software>
    @Binding var selectedPortfolio: Set<PortfolioItem>
    @Binding var selectedActivities: Set<String>

    @EnvironmentObject private var player: Player

    let maxActivitiesPerYear = 1

    var sortedCertifications: [Certification] {
        Certification.allCases.sorted(by: { $0.rawValue < $1.rawValue })
    }

    var sortedPortfolio: [PortfolioItem] {
        PortfolioItem.allCases.sorted(by: { $0.rawValue < $1.rawValue })
    }

    var sortedLicenses: [License] {
        License.allCases.sorted(by: { $0.rawValue < $1.rawValue })
    }

    var sortedSoftware: [Software] {
        Software.allCases.sorted(by: { $0.rawValue < $1.rawValue })
    }

    var counterRow: some View {
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
            Text("Savings: $\(player.savings)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                counterRow

                // Certifications
                Text("Certifications:")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(sortedCertifications, id: \.self) { cert in
                    let isLocked = player.lockedCertifications.contains(cert)
                    let isSelected = selectedCertifications.contains(cert)
                    let atLimit =
                        selectedActivities.count >= maxActivitiesPerYear

                    let requirement = cert.certificationRequirements(player)
                    let blockedReason: String? = {
                        switch requirement {
                        case .blocked(let reason): return reason
                        case .ok: return nil
                        }
                    }()

                    Toggle(
                        cert.friendlyName,
                        isOn: Binding(
                            get: { isSelected },
                            set: { isOn in
                                guard !isLocked else { return }
                                if isOn {
                                    guard !atLimit else { return }
                                    switch cert.certificationRequirements(
                                        player
                                    ) {
                                    case .ok(let cost):
                                        selectedCertifications.insert(cert)
                                        selectedActivities.insert(
                                            "cert:\(cert.rawValue)"
                                        )
                                        player.savings -= cost
                                    case .blocked:
                                        break
                                    }
                                } else {
                                    if selectedCertifications.remove(cert)
                                        != nil
                                    {
                                        selectedActivities.remove(
                                            "cert:\(cert.rawValue)"
                                        )
                                        player.savings +=
                                            cert.costForCertification
                                    }
                                }
                            }
                        )
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .disabled(
                        isLocked
                            || (!isSelected
                                && (atLimit || blockedReason != nil))
                    )
                    .opacity(
                        (isLocked
                            || (!isSelected
                                && (atLimit || blockedReason != nil)))
                            ? 0.5 : 1.0
                    )
                    .help(
                        isLocked
                            ? "Locked after year end"
                            : ((!isSelected && atLimit)
                                ? "You can take up to \(maxActivitiesPerYear) activities this year."
                                : (blockedReason ?? ""))
                    )
                    #if os(macOS)
                        .toggleStyle(.checkbox)
                    #endif
                    #if os(iOS)
                        .toggleStyle(.switch)
                    #endif
                }

                // Licenses
                Text("Licenses:")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(sortedLicenses, id: \.self) { lic in
                    let isLocked = player.lockedLicenses.contains(lic)
                    let isSelected = selectedLicences.contains(lic)
                    let atLimit =
                        selectedActivities.count >= maxActivitiesPerYear

                    let requirement = lic.licenseRequirements(player)
                    let blockedReason: String? = {
                        switch requirement {
                        case .blocked(let reason): return reason
                        case .ok: return nil
                        }
                    }()

                    Toggle(
                        lic.friendlyName,
                        isOn: Binding(
                            get: { isSelected },
                            set: { isOn in
                                guard !isLocked else { return }
                                if isOn {
                                    guard !atLimit else { return }
                                    switch lic.licenseRequirements(player) {
                                    case .ok(let cost):
                                        selectedLicences.insert(lic)
                                        selectedActivities.insert(
                                            "lic:\(lic.rawValue)"
                                        )
                                        player.savings -= cost
                                    case .blocked:
                                        break
                                    }
                                } else {
                                    if selectedLicences.remove(lic) != nil {
                                        selectedActivities.remove(
                                            "lic:\(lic.rawValue)"
                                        )
                                        player.savings += lic.costForLicense
                                    }
                                }
                            }
                        )
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .disabled(
                        isLocked
                            || (!isSelected
                                && (atLimit || blockedReason != nil))
                    )
                    .opacity(
                        (isLocked
                            || (!isSelected
                                && (atLimit || blockedReason != nil)))
                            ? 0.5 : 1.0
                    )
                    .help(
                        isLocked
                            ? "Locked after year end"
                            : ((!isSelected && atLimit)
                                ? "You can take up to \(maxActivitiesPerYear) activities this year."
                                : (blockedReason ?? ""))
                    )
                    #if os(macOS)
                        .toggleStyle(.checkbox)
                    #endif
                    #if os(iOS)
                        .toggleStyle(.switch)
                    #endif
                }

                // Software
                Text("Software:")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(sortedSoftware, id: \.self) { sw in
                    let isLocked = player.lockedSoftware.contains(sw)
                    let isSelected = selectedSoftware.contains(sw)
                    let atLimit =
                        selectedActivities.count >= maxActivitiesPerYear

                    let requirement = sw.softwareRequirements(player)
                    let blockedReason: String? = {
                        switch requirement {
                        case .blocked(let reason): return reason
                        case .ok: return nil
                        }
                    }()

                    Toggle(
                        "Software: \(sw.rawValue) \(sw.pictogram)",
                        isOn: Binding(
                            get: { isSelected },
                            set: { isOn in
                                guard !isLocked else { return }
                                if isOn {
                                    guard !atLimit else { return }
                                    switch sw.softwareRequirements(player) {
                                    case .ok(let cost):
                                        selectedSoftware.insert(sw)
                                        selectedActivities.insert(
                                            "soft:\(sw.rawValue)"
                                        )
                                        player.savings -= cost  // currently 0 per Software.softwareRequirements
                                    case .blocked:
                                        break
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
                    .disabled(
                        isLocked
                            || (!isSelected
                                && (atLimit || blockedReason != nil))
                    )
                    .opacity(
                        (isLocked
                            || (!isSelected
                                && (atLimit || blockedReason != nil)))
                            ? 0.5 : 1.0
                    )
                    .help(
                        isLocked
                            ? "Locked after year end"
                            : ((!isSelected && atLimit)
                                ? "You can take up to \(maxActivitiesPerYear) activities this year."
                                : (blockedReason ?? ""))
                    )
                    #if os(macOS)
                        .toggleStyle(.checkbox)
                    #endif
                    #if os(iOS)
                        .toggleStyle(.switch)
                    #endif
                }

                // Portfolio
                Text("Portfolio Items:")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(sortedPortfolio, id: \.self) { item in
                    let isLocked = player.lockedPortfolio.contains(item)
                    let isSelected = selectedPortfolio.contains(item)
                    let atLimit =
                        selectedActivities.count >= maxActivitiesPerYear

                    Toggle(
                        "Portfolio: \(item.rawValue) \(item.pictogram)",
                        isOn: Binding(
                            get: { isSelected },
                            set: { isOn in
                                guard !isLocked else { return }
                                if isOn {
                                    guard !atLimit else { return }
                                    selectedPortfolio.insert(item)
                                    selectedActivities.insert(
                                        "port:\(item.rawValue)"
                                    )
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
                                : (""))
                    )
                    #if os(macOS)
                        .toggleStyle(.checkbox)
                    #endif
                    #if os(iOS)
                        .toggleStyle(.switch)
                    #endif
                }
            }
            .padding(.horizontal)
        }
    }
}

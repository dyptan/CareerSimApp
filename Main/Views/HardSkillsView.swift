import SwiftUI

struct HardSkillsView: View {
    @Binding var selectedCertifications: Set<Certification>
    @Binding var selectedLicences: Set<License>
    @Binding var selectedSoftware: Set<Software>
    @Binding var selectedPortfolio: Set<PortfolioItem>
    @Binding var selectedActivities: Set<String>

    @EnvironmentObject private var player: Player

    let maxActivitiesPerYear = 1

    // Sorted arrays for ForEach (never bind these)
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

    // MARK: - UI helper (mirrors JobView requirement row)
    private func requirementRow(
        label: String,
        emoji: String,
        level: Int,
        playerLevel: Int
    ) -> some View {
        let required = max(level, 0)
        let meets = playerLevel >= required

        return HStack {
            Text(label)
            Spacer()
            HStack(spacing: 0) {
                ForEach(0..<required, id: \.self) { idx in
                    Text(emoji)
                        .opacity(idx < playerLevel ? 1.0 : 0.35)
                }
            }
            .font(.body)
        }
        .font(.body)
        .foregroundStyle(meets ? .primary : .secondary)
        .padding(.horizontal, 6)
    }

    // MARK: - Certification thresholds (match Certification.swift)
    private func certificationThresholds(_ cert: Certification) -> [(
        WritableKeyPath<SoftSkills, Int>, Int
    )] {
        switch cert {
        case .aws, .azure, .google, .scrum, .security:
            return [(\.analyticalReasoningAndProblemSolving, 5)]
        case .cna:
            return [
                (\.communicationAndNetworking, 2),
                (\.resilienceAndEndurance, 2),
                (\.carefulnessAndAttentionToDetail, 2),
            ]
        case .dentalAssistant:
            return [
                (\.carefulnessAndAttentionToDetail, 3),
                (\.communicationAndNetworking, 2),
            ]
        case .medicalAssistant:
            return [
                (\.communicationAndNetworking, 2),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.perseveranceAndGrit, 2),
            ]
        case .pharmacyTech:
            return [
                (\.analyticalReasoningAndProblemSolving, 2),
                (\.carefulnessAndAttentionToDetail, 3),
            ]
        case .cwi:
            return [
                (\.perseveranceAndGrit, 3),
                (\.carefulnessAndAttentionToDetail, 3),
            ]
        case .epa608:
            return [
                (\.carefulnessAndAttentionToDetail, 3),
                (\.analyticalReasoningAndProblemSolving, 2),
            ]
        case .nate:
            return [
                (\.tinkeringAndFingerPrecision, 3),
                (\.perseveranceAndGrit, 2),
            ]
        case .faaAMP:
            return [
                (\.tinkeringAndFingerPrecision, 3),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.perseveranceAndGrit, 3),
            ]
        case .cfp:
            return [
                (\.analyticalReasoningAndProblemSolving, 3),
                (\.communicationAndNetworking, 2),
            ]
        case .series65:
            return [
                (\.analyticalReasoningAndProblemSolving, 3)
            ]
        case .flightAttendantCert:
            return [
                (\.communicationAndNetworking, 2),
                (\.resilienceAndEndurance, 3),
            ]
        }
    }

    private func unmetPictograms(for cert: Certification) -> [String] {
        certificationThresholds(cert).compactMap { (kp, req) in
            let current = player.softSkills[keyPath: kp]
            guard current < req else { return nil }
            return SoftSkills.pictogram(forKeyPath: kp)
        }
    }

    // MARK: - License thresholds (visualization)
    private func licenseThresholds(_ lic: License) -> [(
        WritableKeyPath<SoftSkills, Int>, Int
    )] {
        switch lic {
        case .drivers:
            return [
                (\.spacialNavigation, 1),
                (\.coordinationAndBalance, 1),
                (\.resilienceAndEndurance, 1),
            ]
        case .cdl:
            return [
                (\.spacialNavigation, 2),
                (\.coordinationAndBalance, 2),
                (\.resilienceAndEndurance, 2),
                (\.perseveranceAndGrit, 2),
                (\.carefulnessAndAttentionToDetail, 2),
            ]
        case .pilot:
            return [
                (\.spacialNavigation, 2),
                (\.coordinationAndBalance, 2),
                (\.carefulnessAndAttentionToDetail, 2),
                (\.analyticalReasoningAndProblemSolving, 2),
            ]
        case .commercialPilot:
            return [
                (\.spacialNavigation, 3),
                (\.coordinationAndBalance, 3),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.perseveranceAndGrit, 3),
                (\.analyticalReasoningAndProblemSolving, 3),
            ]
        case .nurse:
            return [
                (\.communicationAndNetworking, 2),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.resilienceAndEndurance, 2),
            ]
        case .electrician:
            return [
                (\.tinkeringAndFingerPrecision, 3),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.perseveranceAndGrit, 2),
            ]
        case .plumber:
            return [
                (\.tinkeringAndFingerPrecision, 3),
                (\.carefulnessAndAttentionToDetail, 2),
                (\.perseveranceAndGrit, 2),
                (\.physicalStrength, 2),
            ]
        case .realEstateAgent:
            return [
                (\.communicationAndNetworking, 3),
                (\.presentationAndStorytelling, 2),
                (\.analyticalReasoningAndProblemSolving, 2),
            ]
        case .insuranceAgent:
            return [
                (\.communicationAndNetworking, 3),
                (\.analyticalReasoningAndProblemSolving, 2),
                (\.carefulnessAndAttentionToDetail, 2),
            ]
        }
    }

    private func unmetPictograms(for lic: License) -> [String] {
        licenseThresholds(lic).compactMap { (kp, req) in
            let current = player.softSkills[keyPath: kp]
            guard current < req else { return nil }
            return SoftSkills.pictogram(forKeyPath: kp)
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
                    let priceText: String = {
                        switch requirement {
                        case .ok(let cost): return "$\(cost)"
                        case .blocked: return "$\(cert.costForCertification)"
                        }
                    }()

                    VStack(alignment: .leading, spacing: 6) {
                        Toggle(
                            "\(cert.friendlyName) — \(priceText)",
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
                        #if os(macOS)
                            .toggleStyle(.checkbox)
                        #endif
                        #if os(iOS)
                            .toggleStyle(.switch)
                        #endif
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

                        let thresholds = certificationThresholds(cert)
                        if !thresholds.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(0..<thresholds.count, id: \.self) {
                                    idx in
                                    let (kp, lvl) = thresholds[idx]
                                    requirementRow(
                                        label: SoftSkills.label(forKeyPath: kp)
                                            ?? "",
                                        emoji: SoftSkills.pictogram(
                                            forKeyPath: kp
                                        ) ?? "",
                                        level: lvl,
                                        playerLevel: player.softSkills[
                                            keyPath: kp
                                        ]
                                    )
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
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
                    let priceText: String = {
                        switch requirement {
                        case .ok(let cost): return "$\(cost)"
                        case .blocked: return "$\(lic.costForLicense)"
                        }
                    }()

                    VStack(alignment: .leading, spacing: 6) {
                        Toggle(
                            "\(lic.friendlyName) — \(priceText)",
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
                        #if os(macOS)
                            .toggleStyle(.checkbox)
                        #endif
                        #if os(iOS)
                            .toggleStyle(.switch)
                        #endif
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

                        let thresholds = licenseThresholds(lic)
                        if !thresholds.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(0..<thresholds.count, id: \.self) {
                                    idx in
                                    let (kp, lvl) = thresholds[idx]
                                    requirementRow(
                                        label: SoftSkills.label(forKeyPath: kp)
                                            ?? "",
                                        emoji: SoftSkills.pictogram(
                                            forKeyPath: kp
                                        ) ?? "",
                                        level: lvl,
                                        playerLevel: player.softSkills[
                                            keyPath: kp
                                        ]
                                    )
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
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

                    VStack(alignment: .leading, spacing: 6) {
                        Toggle(
                            "\(sw.rawValue) \(sw.pictogram)",
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
                                            player.savings -= cost  // currently 0
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
                        #if os(macOS)
                            .toggleStyle(.checkbox)
                        #endif
                        #if os(iOS)
                            .toggleStyle(.switch)
                        #endif
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

                        requirementRow(
                            label: SoftSkills.label(
                                forKeyPath:
                                    \.analyticalReasoningAndProblemSolving
                            ) ?? "Problem Solving",
                            emoji: SoftSkills.pictogram(
                                forKeyPath:
                                    \.analyticalReasoningAndProblemSolving
                            ) ?? "🧩",
                            level: 1,
                            playerLevel: player.softSkills
                                .analyticalReasoningAndProblemSolving
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
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

                    let requirement = item.portfolioRequirements(player)
                    let blockedReason: String? = {
                        switch requirement {
                        case .blocked(let reason): return reason
                        case .ok: return nil
                        }
                    }()

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {

                            Toggle(

                                "\(item.rawValue) \(item.pictogram) \(blockedReason ?? "")",

                                isOn: Binding(
                                    get: { isSelected },
                                    set: { isOn in
                                        guard !isLocked else { return }
                                        if isOn {
                                            guard !atLimit else { return }
                                            switch item.portfolioRequirements(
                                                player
                                            ) {
                                            case .ok:
                                                selectedPortfolio.insert(item)
                                                selectedActivities.insert(
                                                    "port:\(item.rawValue)"
                                                )
                                            case .blocked:
                                                break
                                            }
                                        } else {
                                            if selectedPortfolio.remove(item)
                                                != nil
                                            {
                                                selectedActivities.remove(
                                                    "port:\(item.rawValue)"
                                                )
                                            }
                                        }
                                    }
                                )
                            )
                            #if os(macOS)
                                .toggleStyle(.checkbox)
                            #endif
                            #if os(iOS)
                                .toggleStyle(.switch)
                            #endif
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
                                        : "")
                            )

                        }

                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct HardSkillsPreviewContainer: View {
    @State private var certs: Set<Certification> = []
    @State private var licenses: Set<License> = []
    @State private var software: Set<Software> = []
    @State private var portfolio: Set<PortfolioItem> = []
    @State private var activities: Set<String> = []
    @StateObject private var player = Player()

    var body: some View {
        HardSkillsView(
            selectedCertifications: $certs,
            selectedLicences: $licenses,
            selectedSoftware: $software,
            selectedPortfolio: $portfolio,
            selectedActivities: $activities
        )
        .environmentObject(player)
    }
}

#Preview {
    HardSkillsPreviewContainer()
}

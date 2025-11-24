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

// MARK: - Shared gating helpers

private enum TrainingRequirementResult {
    case ok(cost: Int)
    case blocked(reason: String)
}

private extension Player {
    // Updated, more realistic ballpark costs (USD).
    // These include typical instruction, materials, and exam/issuance fees.

    func costForCertification(_ cert: Certification) -> Int {
        switch cert {
        case .aws: return 350   // prep + exam voucher
        case .azure: return 350
        case .google: return 300
        case .scrum: return 600 // 2-day course + exam
        case .security: return 250 // basic security awareness + test
        case .cwi: return 3000  // course + exam (CWI is pricey)
        case .epa608: return 200 // prep + exam
        case .nate: return 450   // prep + exam
        case .faaAMP: return 6000 // A&P prep/testing (very rough, excluding full school tuition)
        case .cna: return 1500   // course + clinical + exam
        case .dentalAssistant: return 2500 // short program + exam
        case .medicalAssistant: return 3500 // program + exam
        case .pharmacyTech: return 1200 // course + exam
        case .cfp: return 7000   // coursework + exam fee
        case .series65: return 500 // prep + exam
        case .flightAttendantCert: return 1000 // prep + airline hiring process costs
        }
    }

    func costForLicense(_ lic: License) -> Int {
        switch lic {
        case .drivers:
            // Driving school package + DMV fees + written/road test
            return 1200
        case .cdl:
            // CDL training program + exam fees
            return 4500
        case .pilot:
            // PPL: ground school + flight hours + checkride (very rough lower bound)
            return 12000
        case .commercialPilot:
            // Additional hours + checkride (very rough, incremental)
            return 20000
        case .nurse:
            // Licensing process costs; education is separate
            return 800
        case .electrician:
            // Course + exam + license application (excl. apprenticeship wages)
            return 1500
        case .plumber:
            // Course + exam + license application
            return 1500
        case .realEstateAgent:
            // Pre-licensing course + exam + license
            return 800
        case .insuranceAgent:
            // Pre-licensing course + exam + license
            return 600
        }
    }

    func costForLanguage(_ lang: ProgrammingLanguage) -> Int {
        // Cost to take a structured course this year (books + course)
        switch lang {
        case .english: return 300
        case .swift: return 500
        case .python: return 450
        case .java: return 550
        case .C: return 600
        }
    }

    func costForSoftware(_ sw: Software) -> Int {
        // Training course + potential license/subscription for a year
        switch sw {
        case .macOS: return 150   // general productivity + course
        case .linux: return 200   // admin course
        case .excel: return 250   // intermediate/advanced course
        case .unity: return 500   // course + potential asset purchases
        case .photoshop: return 400 // course + subscription months
        case .blender: return 350  // course + optional add-ons
        }
    }

    func costForPortfolio(_ item: PortfolioItem) -> Int {
        // Course, tools, hosting, and/or time costs converted into a budget
        switch item {
        case .app: return 800         // dev program + assets + tools
        case .game: return 1000       // engine course + assets
        case .website: return 300     // hosting + domain + template/tools
        case .library: return 500     // time + tooling + testing infra
        case .paper: return 150       // research tools + formatting tools
        case .presentation: return 200 // design tools + templates
        }
    }

    // Age and soft-skill gates; thresholds unchanged (tune as desired)
    func certificationRequirements(_ cert: Certification) -> TrainingRequirementResult {
        switch cert {
        case .cwi, .epa608, .nate, .faaAMP, .cfp, .series65:
            if age < 18 { return .blocked(reason: "Requires age 18+") }
        case .flightAttendantCert:
            if age < 17 { return .blocked(reason: "Requires age 17+") }
        default:
            break
        }

        switch cert {
        case .scrum:
            if softSkills.communicationAndNetworking < 2 || softSkills.leadershipAndInfluence < 2 {
                return .blocked(reason: "Needs better Communication and Leadership")
            }
        case .security:
            if softSkills.carefulnessAndAttentionToDetail < 2 {
                return .blocked(reason: "Needs more Carefulness")
            }
        case .aws, .azure, .google:
            if softSkills.analyticalReasoningAndProblemSolving < 2 {
                return .blocked(reason: "Needs more Problem Solving")
            }
        default:
            break
        }

        let cost = costForCertification(cert)
        guard savings >= cost else { return .blocked(reason: "Not enough savings ($\(cost))") }
        return .ok(cost: cost)
    }

    func licenseRequirements(_ lic: License) -> TrainingRequirementResult {
        switch lic {
        case .drivers:
            if age < 16 { return .blocked(reason: "Requires age 16+") }
        case .cdl:
            if age < 18 { return .blocked(reason: "Requires age 18+") }
        case .pilot, .realEstateAgent, .insuranceAgent:
            if age < 18 { return .blocked(reason: "Requires age 18+") }
        case .commercialPilot:
            if age < 21 { return .blocked(reason: "Requires age 21+") }
        case .nurse, .electrician, .plumber:
            if age < 18 { return .blocked(reason: "Requires age 18+") }
        }

        switch lic {
        case .drivers, .cdl, .pilot, .commercialPilot:
            if softSkills.coordinationAndBalance < 2 || softSkills.spacialNavigation < 2 {
                return .blocked(reason: "Needs better Coordination and Navigation")
            }
        case .nurse:
            if softSkills.resilienceAndEndurance < 2 || softSkills.communicationAndNetworking < 2 {
                return .blocked(reason: "Needs better Endurance and Communication")
            }
        case .electrician, .plumber:
            if softSkills.tinkeringAndFingerPrecision < 2 || softSkills.carefulnessAndAttentionToDetail < 2 {
                return .blocked(reason: "Needs better Tinkering and Carefulness")
            }
        default:
            break
        }

        let cost = costForLicense(lic)
        guard savings >= cost else { return .blocked(reason: "Not enough savings ($\(cost))") }
        return .ok(cost: cost)
    }

    func languageRequirements(_ lang: ProgrammingLanguage) -> TrainingRequirementResult {
        if softSkills.analyticalReasoningAndProblemSolving < 1 {
            return .blocked(reason: "Needs more Problem Solving")
        }
        let cost = costForLanguage(lang)
        guard savings >= cost else { return .blocked(reason: "Not enough savings ($\(cost))") }
        return .ok(cost: cost)
    }

    func softwareRequirements(_ sw: Software) -> TrainingRequirementResult {
        if softSkills.analyticalReasoningAndProblemSolving < 1 {
            return .blocked(reason: "Needs more Problem Solving")
        }
        let cost = costForSoftware(sw)
        guard savings >= cost else { return .blocked(reason: "Not enough savings ($\(cost))") }
        return .ok(cost: cost)
    }

    func portfolioRequirements(_ item: PortfolioItem) -> TrainingRequirementResult {
        switch item {
        case .app, .game, .website, .library:
            if softSkills.perseveranceAndGrit < 1 {
                return .blocked(reason: "Needs more Perseverance")
            }
        case .paper, .presentation:
            if softSkills.communicationAndNetworking < 1 {
                return .blocked(reason: "Needs more Communication")
            }
        }
        let cost = costForPortfolio(item)
        guard savings >= cost else { return .blocked(reason: "Not enough savings ($\(cost))") }
        return .ok(cost: cost)
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

                let requirement = player.certificationRequirements(cert)
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
                                switch player.certificationRequirements(cert) {
                                case .ok(let cost):
                                    selectedCertifications.insert(cert)
                                    selectedActivities.insert("cert:\(cert.rawValue)")
                                    player.savings -= cost
                                case .blocked:
                                    break
                                }
                            } else {
                                if selectedCertifications.remove(cert) != nil {
                                    selectedActivities.remove("cert:\(cert.rawValue)")
                                    player.savings += player.costForCertification(cert)
                                }
                            }
                        }
                    )
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .disabled(isLocked || (!isSelected && (atLimit || blockedReason != nil)))
                .opacity((isLocked || (!isSelected && (atLimit || blockedReason != nil))) ? 0.5 : 1.0)
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
            Text("Savings: $\(player.savings)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
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

                let requirement = player.licenseRequirements(lic)
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
                                switch player.licenseRequirements(lic) {
                                case .ok(let cost):
                                    selectedLicences.insert(lic)
                                    selectedActivities.insert("lic:\(lic.rawValue)")
                                    player.savings -= cost
                                case .blocked:
                                    break
                                }
                            } else {
                                if selectedLicences.remove(lic) != nil {
                                    selectedActivities.remove("lic:\(lic.rawValue)")
                                    player.savings += player.costForLicense(lic)
                                }
                            }
                        }
                    )
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .disabled(isLocked || (!isSelected && (atLimit || blockedReason != nil)))
                .opacity((isLocked || (!isSelected && (atLimit || blockedReason != nil))) ? 0.5 : 1.0)
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
            Text("Savings: $\(player.savings)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
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

                let requirement = player.languageRequirements(lang)
                let blockedReason: String? = {
                    switch requirement {
                    case .blocked(let reason): return reason
                    case .ok: return nil
                    }
                }()

                Toggle(
                    "Language: \(lang.rawValue) \(lang.pictogram)",
                    isOn: Binding(
                        get: { isSelected },
                        set: { isOn in
                            guard !isLocked else { return }
                            if isOn {
                                guard !atLimit else { return }
                                switch player.languageRequirements(lang) {
                                case .ok(let cost):
                                    selectedLanguages.insert(lang)
                                    selectedActivities.insert("lang:\(lang.rawValue)")
                                    player.savings -= cost
                                case .blocked:
                                    break
                                }
                            } else {
                                if selectedLanguages.remove(lang) != nil {
                                    selectedActivities.remove("lang:\(lang.rawValue)")
                                    player.savings += player.costForLanguage(lang)
                                }
                            }
                        }
                    )
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .disabled(isLocked || (!isSelected && (atLimit || blockedReason != nil)))
                .opacity((isLocked || (!isSelected && (atLimit || blockedReason != nil))) ? 0.5 : 1.0)
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
            Text("Savings: $\(player.savings)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
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

                let requirement = player.softwareRequirements(sw)
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
                                switch player.softwareRequirements(sw) {
                                case .ok(let cost):
                                    selectedSoftware.insert(sw)
                                    selectedActivities.insert("soft:\(sw.rawValue)")
                                    player.savings -= cost
                                case .blocked:
                                    break
                                }
                            } else {
                                if selectedSoftware.remove(sw) != nil {
                                    selectedActivities.remove("soft:\(sw.rawValue)")
                                    player.savings += player.costForSoftware(sw)
                                }
                            }
                        }
                    )
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .disabled(isLocked || (!isSelected && (atLimit || blockedReason != nil)))
                .opacity((isLocked || (!isSelected && (atLimit || blockedReason != nil))) ? 0.5 : 1.0)
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
            Text("Savings: $\(player.savings)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
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

                let requirement = player.portfolioRequirements(item)
                let blockedReason: String? = {
                    switch requirement {
                    case .blocked(let reason): return reason
                    case .ok: return nil
                    }
                }()

                Toggle(
                    "Portfolio: \(item.rawValue) \(item.pictogram)",
                    isOn: Binding(
                        get: { isSelected },
                        set: { isOn in
                            guard !isLocked else { return }
                            if isOn {
                                guard !atLimit else { return }
                                switch player.portfolioRequirements(item) {
                                case .ok(let cost):
                                    selectedPortfolio.insert(item)
                                    selectedActivities.insert("port:\(item.rawValue)")
                                    player.savings -= cost
                                case .blocked:
                                    break
                                }
                            } else {
                                if selectedPortfolio.remove(item) != nil {
                                    selectedActivities.remove("port:\(item.rawValue)")
                                    player.savings += player.costForPortfolio(item)
                                }
                            }
                        }
                    )
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .disabled(isLocked || (!isSelected && (atLimit || blockedReason != nil)))
                .opacity((isLocked || (!isSelected && (atLimit || blockedReason != nil))) ? 0.5 : 1.0)
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
            Text("Savings: $\(player.savings)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

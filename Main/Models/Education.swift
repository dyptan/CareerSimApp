import Foundation

// `Level` (with `Level.Stage`) lives in EducationLevel.swift.
// `TertiaryProfile` lives in EducationProfile.swift.

struct Education: Codable, Hashable, Identifiable {
    var level: Level.Stage
    var profile: TertiaryProfile?  // nil for early education
    var tier: EducationTier        // institution tier; ignored for K-12

    var id: String {
        if let p = profile {
            return "\(level.rawValue)-\(p.rawValue)-\(tier.rawValue)"
        } else {
            return level.rawValue
        }
    }

    init(_ level: Level.Stage) {
        self.level = level
        self.profile = nil
        self.tier = .state
    }

    init(_ level: Level.Stage, profile: TertiaryProfile, tier: EducationTier = .state) {
        self.level = level
        self.profile = profile
        self.tier = tier
    }

    var eqf: Int { Level(stage: level).eqf }
    var yearsToComplete: Int { Level(stage: level).yearsToComplete() }
    var pictogram: String { Level(stage: level).pictogram }

    /// Per-year tuition for this institution tier at this degree level.
    var annualTuition: Int { tier.annualTuition(for: level) }

    /// Total tuition over the duration of the degree.
    var totalTuition: Int { annualTuition * yearsToComplete }

    /// Convenience accessor for tier prestige (1/2/3); 0 for K-12.
    var prestige: Int { profile == nil ? 0 : tier.prestige }

    // Admission requirements mirror the Job model: soft-skill thresholds reuse
    // `SoftSkills` so the whole app shares one soft-skill field list.
    struct SoftSkillMapping: Identifiable {
        let id: String
        let pictogram: String
        let keyPath: WritableKeyPath<SoftSkills, Int>
    }

    struct Requirements: Codable, Hashable {
        var minEQF: Int = 0
        /// Minimum soft-skill levels required for admission.
        var soft = SoftSkills()

        init(minEQF: Int = 0) {
            self.minEQF = minEQF
        }

        func educationLabel() -> String {
            switch minEQF {
            case ..<1: return "Primary school"
            case 1: return "Primary school"
            case 2: return "Middle school"
            case 3: return "High school"
            case 4: return "College / Vocational"
            case 5: return "University — Bachelor's"
            case 6: return "University — Master's"
            case 7: return "Doctorate"
            default: return "Doctorate+"
            }
        }

        /// Derived from the single source of truth so the admissions UI lists
        /// every axis automatically.
        static let softSkillMappings: [Education.SoftSkillMapping] =
            SoftSkills.allAxes.map { .init(id: $0.label, pictogram: $0.pictogram, keyPath: $0.keyPath) }
    }

    var requirements: Requirements {
        guard let p = profile else { return Requirements() }

        var base = Education.baseRequirements(for: p)

        // Escalate by level, enforce minimums, and clamp to 0...5
        var r: Requirements
        switch level {
        case .Vocational:
            base.minEQF = 3
            r = Education.clamped(base)
        case .Bachelor:
            var x = Education.elevated(base, by: 1)
            x.minEQF = 3
            x = Education.enforceMinimums(x, for: .Bachelor, profile: p)
            r = Education.clamped(x)
        case .Master:
            var x = Education.elevated(base, by: 2)
            x.minEQF = 5
            x = Education.enforceMinimums(x, for: .Master, profile: p)
            r = Education.clamped(x)
        case .Doctorate:
            var x = Education.elevated(base, by: 3)
            x.minEQF = 6
            x = Education.enforceMinimums(x, for: .Doctorate, profile: p)
            r = Education.clamped(x)
        default:
            return Requirements()
        }

        // Tier raises the soft-skill admission bar for non-zero requirements.
        let bonus = tier.requirementBonus
        if bonus > 0 {
            r = Education.elevated(r, by: bonus)
            r = Education.clamped(r)
        }
        return r
    }

    func meetsRequirements(player: Player) -> Bool {
        let p = player.softSkills
        let highestEQF = player.degrees.last?.eqf ?? 0
        let r = requirements

        guard highestEQF >= r.minEQF else { return false }
        for kp in SoftSkills.allAxes.map(\.keyPath) {
            guard p[keyPath: kp] >= r.soft[keyPath: kp] else { return false }
        }
        return true
    }

    /// Probability (0.02...0.98) that an application here is accepted, in realistic
    /// mode. The prior-degree (EQF) prerequisite is a hard structural gate; beyond
    /// that, the odds rise with how well the player's soft skills match the
    /// admission bar and fall with the institution's selectivity. Meeting every
    /// bar is "fully qualified" (per-axis fit caps at 1.0), but an elite school can
    /// still turn a fully-qualified applicant away.
    func admissionProbability(player: Player) -> Double {
        let highestEQF = player.degrees.last?.eqf ?? 0
        guard highestEQF >= requirements.minEQF else { return 0 }

        var requiredAxes = 0
        var fitSum = 0.0
        for kp in SoftSkills.allAxes.map(\.keyPath) {
            let need = requirements.soft[keyPath: kp]
            guard need > 0 else { continue }
            requiredAxes += 1
            fitSum += min(Double(player.softSkills[keyPath: kp]) / Double(need), 1.0)
        }
        let fit = requiredAxes == 0 ? 1.0 : fitSum / Double(requiredAxes)
        let raw = 0.1 + 0.9 * fit + tier.admissionSelectivity + player.difficulty.opportunityBonus
        return max(0.02, min(0.98, raw))
    }

    var degreeName: String {
        switch (level, profile) {
        case (.Vocational, .some(let prof)) where prof.allowsVocational:
            let title = prof.rawValue.capitalized
            return "Vocational Diploma in \(title)"
        case (.Vocational, _):
            return "Vocational Diploma"
        case (.Bachelor, .some(let prof)):
            switch prof {
            case .business: return "Bachelor of Business Administration"
            case .engineering: return "Bachelor of Engineering"
            case .health: return "Bachelor of Health Sciences"
            case .arts: return "Bachelor of Arts"
            case .science: return "Bachelor of Science"
            case .education: return "Bachelor of Education"
            case .technology: return "Bachelor of Science in Information Technology"
            case .agriculture: return "Bachelor of Agriculture"
            case .law: return "Bachelor of Laws"
            case .design: return "Bachelor of Design"
            case .service: return "Bachelor of Science in Service Management"
            case .sports: return "Bachelor of Science in Sports Science"
            }
        case (.Master, .some(let prof)):
            switch prof {
            case .business: return "Master of Business Administration"
            case .engineering: return "Master of Engineering"
            case .health: return "Master of Health Sciences"
            case .arts: return "Master of Arts"
            case .science: return "Master of Science"
            case .education: return "Master of Education"
            case .technology: return "Master of Science in Information Technology"
            case .agriculture: return "Master of Agriculture"
            case .law: return "Master of Laws"
            case .design: return "Master of Design"
            case .service: return "Master of Science in Service Management"
            case .sports: return "Master of Science in Sports Science"
            }
        case (.Doctorate, .some(let prof)):
            switch prof {
            case .business: return "Doctor of Business Administration"
            case .engineering: return "Doctor of Philosophy in Engineering"
            case .health: return "Doctor of Philosophy in Health Sciences"
            case .arts: return "Doctor of Fine Arts"
            case .science: return "Doctor of Philosophy in Science"
            case .education: return "Doctor of Education"
            case .technology: return "Doctor of Philosophy in Information Technology"
            case .agriculture: return "Doctor of Philosophy in Agriculture"
            case .law: return "Doctor of Juridical Science"
            case .design: return "Doctor of Design"
            case .service: return "Doctor of Philosophy in Service Management"
            case .sports: return "Doctor of Philosophy in Sports Science"
            }
        default:
            return Level(stage: level).degree
        }
    }

    var degreeUS: String {
        switch (level, profile) {
        case (.Vocational, .some(let prof)) where prof.allowsVocational:
            let title = prof.rawValue.capitalized
            return "Associate of Applied Science in \(title)"
        case (.Vocational, _):
            return "Trade Certificate"
        case (.Bachelor, .some(let prof)):
            switch prof {
            case .business: return "Bachelor of Business Administration"
            case .engineering: return "Bachelor of Science in Engineering"
            case .health: return "Bachelor of Science in Health Sciences"
            case .arts: return "Bachelor of Arts in Arts"
            case .science: return "Bachelor of Science"
            case .education: return "Bachelor of Education"
            case .technology: return "Bachelor of Science in Information Technology"
            case .agriculture: return "Bachelor of Science in Agriculture"
            case .law: return "Bachelor of Arts in Law"
            case .design: return "Bachelor of Arts in Design"
            case .service: return "Bachelor of Science in Service Management"
            case .sports: return "Bachelor of Science in Kinesiology"
            }
        case (.Master, .some(let prof)):
            switch prof {
            case .business: return "Master of Business Administration"
            case .engineering: return "Master of Science in Engineering"
            case .health: return "Master of Science in Health Sciences"
            case .arts: return "Master of Arts in Arts"
            case .science: return "Master of Science"
            case .education: return "Master of Education"
            case .technology: return "Master of Science in Information Technology"
            case .agriculture: return "Master of Science in Agriculture"
            case .law: return "Master of Laws"
            case .design: return "Master of Arts in Design"
            case .service: return "Master of Science in Service Management"
            case .sports: return "Master of Science in Kinesiology"
            }
        case (.Doctorate, .some(let prof)):
            switch prof {
            case .business: return "Doctor of Business Administration"
            case .engineering: return "Doctor of Philosophy in Engineering"
            case .health: return "Doctor of Philosophy in Health Sciences"
            case .arts: return "Doctor of Fine Arts"
            case .science: return "Doctor of Philosophy in Science"
            case .education: return "Doctor of Education"
            case .technology: return "Doctor of Philosophy in Information Technology"
            case .agriculture: return "Doctor of Philosophy in Agriculture"
            case .law: return "Doctor of Juridical Science"
            case .design: return "Doctor of Design"
            case .service: return "Doctor of Philosophy in Service Management"
            case .sports: return "Doctor of Philosophy in Kinesiology"
            }
        default:
            return Level(stage: level).degreeUS
        }
    }
    
    // MARK: - Requirements scaffolding to scale difficulty

    private static func baseRequirements(for profile: TertiaryProfile) -> Requirements {
        var r = Requirements(minEQF: 3)

        // Modest baselines per profile. The level-elevation step (+1 / +2 / +3
        // for Bachelor / Master / Doctorate) grows them into a gradient where
        // primary traits hit 5 only at Master / Doctorate.
        switch profile {
        case .technology:
            r.soft.analyticalReasoningAndProblemSolving = 2
            r.soft.carefulnessAndAttentionToDetail = 2
            r.soft.selfDisciplineAndPerseverance = 2
            r.soft.tinkeringAndFingerPrecision = 1
            r.soft.timeManagementAndPlanning = 1
            r.soft.collaborationAndTeamwork = 1

        case .engineering:
            r.soft.analyticalReasoningAndProblemSolving = 2
            r.soft.spacialNavigationAndOrientation = 2
            r.soft.carefulnessAndAttentionToDetail = 1
            r.soft.tinkeringAndFingerPrecision = 1
            r.soft.timeManagementAndPlanning = 1
            r.soft.collaborationAndTeamwork = 1

        case .science:
            r.soft.analyticalReasoningAndProblemSolving = 2
            r.soft.selfDisciplineAndPerseverance = 2
            r.soft.timeManagementAndPlanning = 1
            r.soft.presentationAndStorytelling = 1

        case .arts:
            r.soft.creativityAndInsightfulThinking = 3
            r.soft.presentationAndStorytelling = 2
            r.soft.carefulnessAndAttentionToDetail = 1
            r.soft.communicationAndNetworking = 1

        case .design:
            r.soft.creativityAndInsightfulThinking = 3
            r.soft.carefulnessAndAttentionToDetail = 2
            r.soft.presentationAndStorytelling = 2
            r.soft.spacialNavigationAndOrientation = 1

        case .business:
            r.soft.communicationAndNetworking = 2
            r.soft.analyticalReasoningAndProblemSolving = 1
            r.soft.timeManagementAndPlanning = 2
            r.soft.presentationAndStorytelling = 2
            r.soft.collaborationAndTeamwork = 1

        case .education:
            r.soft.communicationAndNetworking = 2
            r.soft.empathyAndInterpersonalCare = 2
            r.soft.stressResistanceAndEmotionalRegulation = 2
            r.soft.presentationAndStorytelling = 2
            r.soft.timeManagementAndPlanning = 1

        case .health:
            r.soft.communicationAndNetworking = 2
            r.soft.empathyAndInterpersonalCare = 2
            r.soft.carefulnessAndAttentionToDetail = 2
            r.soft.resilienceAndEndurance = 2
            r.soft.stressResistanceAndEmotionalRegulation = 2

        case .sports:
            r.soft.resilienceAndEndurance = 2
            r.soft.collaborationAndTeamwork = 2
            r.soft.selfDisciplineAndPerseverance = 2

        case .agriculture:
            r.soft.resilienceAndEndurance = 2
            r.soft.outdoorAndWeatherResilience = 1
            r.soft.timeManagementAndPlanning = 1

        case .law:
            r.soft.analyticalReasoningAndProblemSolving = 2
            r.soft.communicationAndNetworking = 2
            r.soft.carefulnessAndAttentionToDetail = 2
            r.soft.presentationAndStorytelling = 2
            r.soft.timeManagementAndPlanning = 1

        case .service:
            r.soft.communicationAndNetworking = 2
            r.soft.empathyAndInterpersonalCare = 1
            r.soft.stressResistanceAndEmotionalRegulation = 2
            r.soft.collaborationAndTeamwork = 2
            r.soft.timeManagementAndPlanning = 1
        }

        return r
    }

    private static func elevated(_ r: Requirements, by delta: Int) -> Requirements {
        var x = r
        func bump(_ v: Int) -> Int { v > 0 ? min(v + delta, 5) : 0 }

        for kp in SoftSkills.allAxes.map(\.keyPath) {
            x.soft[keyPath: kp] = bump(x.soft[keyPath: kp])
        }
        return x
    }

    private static func enforceMinimums(_ r: Requirements, for level: Level.Stage, profile: TertiaryProfile) -> Requirements {
        var x = r

        // General escalation by level (keep within 5)
        switch level {
        case .Vocational:
            break
        case .Bachelor:
            if profile.isSTEM {
                x.soft.analyticalReasoningAndProblemSolving = min(max(x.soft.analyticalReasoningAndProblemSolving, x.soft.analyticalReasoningAndProblemSolving > 0 ? 3 : 0), 5)
                x.soft.carefulnessAndAttentionToDetail = min(max(x.soft.carefulnessAndAttentionToDetail, x.soft.carefulnessAndAttentionToDetail > 0 ? 2 : 0), 5)
            }
        case .Master:
            if profile.isSTEM {
                x.soft.analyticalReasoningAndProblemSolving = min(max(x.soft.analyticalReasoningAndProblemSolving, x.soft.analyticalReasoningAndProblemSolving > 0 ? 4 : 0), 5)
            } else {
                x.soft.analyticalReasoningAndProblemSolving = min(max(x.soft.analyticalReasoningAndProblemSolving, x.soft.analyticalReasoningAndProblemSolving > 0 ? 3 : 0), 5)
            }
        case .Doctorate:
            if profile.isSTEM {
                x.soft.analyticalReasoningAndProblemSolving = min(max(x.soft.analyticalReasoningAndProblemSolving, x.soft.analyticalReasoningAndProblemSolving > 0 ? 5 : 0), 5)
            } else {
                x.soft.analyticalReasoningAndProblemSolving = min(max(x.soft.analyticalReasoningAndProblemSolving, x.soft.analyticalReasoningAndProblemSolving > 0 ? 4 : 0), 5)
            }
            x.soft.selfDisciplineAndPerseverance = min(max(x.soft.selfDisciplineAndPerseverance, x.soft.selfDisciplineAndPerseverance > 0 ? 3 : 0), 5)
        default:
            break
        }

        // Profile-specific tuning (keep within 5)
        switch profile {
        case .arts, .design:
            if level == .Master || level == .Doctorate {
                x.soft.creativityAndInsightfulThinking = min(max(x.soft.creativityAndInsightfulThinking, x.soft.creativityAndInsightfulThinking > 0 ? (level == .Doctorate ? 5 : 4) : 0), 5)
                x.soft.presentationAndStorytelling = min(max(x.soft.presentationAndStorytelling, x.soft.presentationAndStorytelling > 0 ? (level == .Doctorate ? 4 : 3) : 0), 5)
            }
        case .education:
            if level == .Bachelor || level == .Master || level == .Doctorate {
                x.soft.stressResistanceAndEmotionalRegulation = min(max(x.soft.stressResistanceAndEmotionalRegulation, x.soft.stressResistanceAndEmotionalRegulation > 0 ? (level == .Doctorate ? 4 : 3) : 0), 5)
                x.soft.presentationAndStorytelling = min(max(x.soft.presentationAndStorytelling, x.soft.presentationAndStorytelling > 0 ? (level == .Doctorate ? 4 : 3) : 0), 5)
            }
        case .health:
            if level == .Bachelor || level == .Master || level == .Doctorate {
                x.soft.communicationAndNetworking = min(max(x.soft.communicationAndNetworking, x.soft.communicationAndNetworking > 0 ? 3 : 0), 5)
                x.soft.carefulnessAndAttentionToDetail = min(max(x.soft.carefulnessAndAttentionToDetail, x.soft.carefulnessAndAttentionToDetail > 0 ? 3 : 0), 5)
                x.soft.resilienceAndEndurance = min(max(x.soft.resilienceAndEndurance, x.soft.resilienceAndEndurance > 0 ? (level == .Doctorate ? 4 : 3) : 0), 5)
                x.soft.stressResistanceAndEmotionalRegulation = min(max(x.soft.stressResistanceAndEmotionalRegulation, x.soft.stressResistanceAndEmotionalRegulation > 0 ? (level == .Doctorate ? 4 : 3) : 0), 5)
            }
        case .business, .law:
            if level == .Master || level == .Doctorate {
                x.soft.presentationAndStorytelling = min(max(x.soft.presentationAndStorytelling, x.soft.presentationAndStorytelling > 0 ? (level == .Doctorate ? 4 : 3) : 0), 5)
            }
        default:
            break
        }

        return x
    }

    private static func clamped(_ r: Requirements) -> Requirements {
        var x = r
        func cap(_ v: Int) -> Int { min(max(0, v), 5) }

        for kp in SoftSkills.allAxes.map(\.keyPath) {
            x.soft[keyPath: kp] = cap(x.soft[keyPath: kp])
        }
        return x
    }
}

func availableNextEducations(holds: [Education]) -> [Education] {
    var available: [Education] = []
    for profile in TertiaryProfile.allCases {
        let bachelor = Education(.Bachelor, profile: profile)
        available.append(bachelor)
        if profile.allowsVocational {
            let vocational = Education(.Vocational, profile: profile)
            available.append(vocational)
        }
    }

    let bachelorDegrees = holds.filter { $0.level == .Bachelor }
    for bachelor in bachelorDegrees {
        if let profile = bachelor.profile {
            let master = Education(.Master, profile: profile)
            available.append(master)
        }
    }

    let masterDegrees = holds.filter { $0.level == .Master }
    for master in masterDegrees {
        if let profile = master.profile {
            let doctorate = Education(.Doctorate, profile: profile)
            available.append(doctorate)
        }
    }

    return available
}


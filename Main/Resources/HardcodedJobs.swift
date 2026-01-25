// HardcodedJobs.swift
import Foundation

enum HardcodedJobs {
    static func sampleJobs() -> [Job] {
        let rn = Job(
            id: "Registered Nurse",
            category: .health,
            income: 72_000,
            summary: "Provides patient care, administers medication, and coordinates with medical teams.",
            icon: "🩺",
            requirements: .init(
                education: .init(minEQF: 6, acceptedProfiles: [.health, .science]),
                softSkills: .init(
                    analyticalReasoningAndProblemSolving: 3,   // clinical reasoning
                    creativityAndInsightfulThinking: 0,
                    communicationAndNetworking: 5,             // patient & team comms
                    leadershipAndInfluence: 1,
                    courageAndRiskTolerance: 1,
                    spacialNavigation: 0,
                    carefulnessAndAttentionToDetail: 5,        // meds & charts
                    perseveranceAndGrit: 4,
                    tinkeringAndFingerPrecision: 2,
                    physicalStrength: 3,                        // lifting/long hours
                    coordinationAndBalance: 2,
                    resilienceAndEndurance: 4                   // stamina
                ),
                hardSkills: .init(
                    certifications: [],
                    licenses: ["RN"],
                    software: ["Office"],
                    portfolio: []
                )
            ),
            companyTier: .government,
            version: 6
        )

        let dev = Job(
            id: "Software Developer",
            category: .technology,
            income: 110_000,
            summary: "Designs and builds computer programs and applications.",
            icon: "💻",
            requirements: .init(
                education: .init(minEQF: 5, acceptedProfiles: [.technology, .engineering, .science]),
                softSkills: .init(
                    analyticalReasoningAndProblemSolving: 5,    // algorithms & debugging
                    creativityAndInsightfulThinking: 3,         // solution design
                    communicationAndNetworking: 2,              // teamwork
                    leadershipAndInfluence: 0,
                    courageAndRiskTolerance: 1,                 // shipping/ownership
                    spacialNavigation: 0,
                    carefulnessAndAttentionToDetail: 4,         // correctness
                    perseveranceAndGrit: 4,                     // long cycles
                    tinkeringAndFingerPrecision: 0,
                    physicalStrength: 0,
                    coordinationAndBalance: 0,
                    resilienceAndEndurance: 2                   // crunch tolerance
                ),
                hardSkills: .init(
                    certifications: [],
                    licenses: [],
                    software: ["Programming", "Office"],
                    portfolio: ["App", "Website"]
                )
            ),
            companyTier: .enterprise,
            version: 6
        )

        let designer = Job(
            id: "Graphic Designer",
            category: .design,
            income: 53_000,
            summary: "Creates visual concepts and designs for advertisements, publications, or digital media.",
            icon: "🎨",
            requirements: .init(
                education: .init(minEQF: 4, acceptedProfiles: nil),
                softSkills: .init(
                    analyticalReasoningAndProblemSolving: 1,
                    creativityAndInsightfulThinking: 5,         // core
                    communicationAndNetworking: 2,              // client/team
                    leadershipAndInfluence: 0,
                    courageAndRiskTolerance: 1,
                    spacialNavigation: 3,                        // visual/spatial
                    carefulnessAndAttentionToDetail: 4,         // polish
                    perseveranceAndGrit: 3,
                    tinkeringAndFingerPrecision: 2,
                    physicalStrength: 0,
                    coordinationAndBalance: 0,
                    resilienceAndEndurance: 1
                ),
                hardSkills: .init(
                    certifications: [],
                    licenses: [],
                    software: ["Photo/Video Editing", "Office"],
                    portfolio: ["Presentation", "Website"]
                )
            ),
            companyTier: .mid,
            version: 6
        )

        let lightDriver = Job(
            id: "Light Truck Delivery Driver",
            category: .logistics,
            income: 42_000,
            summary: "Delivers goods locally using vans or small trucks.",
            icon: "🚐",
            requirements: .init(
                education: .init(minEQF: 3, acceptedProfiles: nil),
                softSkills: .init(
                    analyticalReasoningAndProblemSolving: 1,
                    creativityAndInsightfulThinking: 0,
                    communicationAndNetworking: 1,
                    leadershipAndInfluence: 0,
                    courageAndRiskTolerance: 1,
                    spacialNavigation: 3,                        // routing
                    carefulnessAndAttentionToDetail: 3,         // handling goods
                    perseveranceAndGrit: 3,                     // long shifts
                    tinkeringAndFingerPrecision: 1,
                    physicalStrength: 3,                        // loading
                    coordinationAndBalance: 2,
                    resilienceAndEndurance: 3
                ),
                hardSkills: .init(
                    certifications: [],
                    licenses: ["B"],
                    software: [],
                    portfolio: []
                )
            ),
            companyTier: .mid,
            version: 6
        )

        return [rn, dev, designer, lightDriver]
    }
}

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
                    analyticalReasoningAndProblemSolving: 4,
                    creativityAndInsightfulThinking: 0,
                    communicationAndNetworking: 5,
                    leadershipAndInfluence: 0,
                    courageAndRiskTolerance: 0,
                    spacialNavigation: 0,
                    carefulnessAndAttentionToDetail: 5,
                    perseveranceAndGrit: 4,
                    tinkeringAndFingerPrecision: 0,
                    physicalStrength: 3,
                    coordinationAndBalance: 0,
                    resilienceAndEndurance: 4
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
                    analyticalReasoningAndProblemSolving: 5,
                    creativityAndInsightfulThinking: 3,
                    communicationAndNetworking: 0,
                    leadershipAndInfluence: 0,
                    courageAndRiskTolerance: 0,
                    spacialNavigation: 0,
                    carefulnessAndAttentionToDetail: 4,
                    perseveranceAndGrit: 3,
                    tinkeringAndFingerPrecision: 0,
                    physicalStrength: 0,
                    coordinationAndBalance: 0,
                    resilienceAndEndurance: 0
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
                    analyticalReasoningAndProblemSolving: 0,
                    creativityAndInsightfulThinking: 5,
                    communicationAndNetworking: 0,
                    leadershipAndInfluence: 0,
                    courageAndRiskTolerance: 0,
                    spacialNavigation: 3,
                    carefulnessAndAttentionToDetail: 4,
                    perseveranceAndGrit: 3,
                    tinkeringAndFingerPrecision: 0,
                    physicalStrength: 0,
                    coordinationAndBalance: 0,
                    resilienceAndEndurance: 0
                ),
                hardSkills: .init(
                    certifications: [],
                    licenses: [],
                    software: ["Photo/Video Editing", "Office"],
                    portfolio: ["Presentation", "Website"]
                )
            ),
            companyTier: .smb,
            version: 6
        )

        let lightDriver = Job(
            id: "Light Truck Delivery Driver",
            category: .logistics,
            income: 39_000,
            summary: "Delivers goods locally using vans or small trucks.",
            icon: "🚐",
            requirements: .init(
                education: .init(minEQF: 3, acceptedProfiles: nil),
                softSkills: .init(
                    analyticalReasoningAndProblemSolving: 0,
                    creativityAndInsightfulThinking: 0,
                    communicationAndNetworking: 0,
                    leadershipAndInfluence: 0,
                    courageAndRiskTolerance: 0,
                    spacialNavigation: 3,
                    carefulnessAndAttentionToDetail: 3,
                    perseveranceAndGrit: 3,
                    tinkeringAndFingerPrecision: 3,
                    physicalStrength: 3,
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
            companyTier: .smb,
            version: 6
        )

        return [rn, dev, designer, lightDriver]
    }
}

//
//  Tests.swift
//  Tests
//
//  Created by Ivan Dyptan on 11.10.25.
//

import Testing
@testable import CareersApp

@Suite("Smoke")
struct SmokeTests {
    @Test("Project compiles and basic types are available")
    func compiles() {
        // Minimal sanity: create one hardcoded job without touching JSON
        let job = Job(
            id: "demo",
            category: .technology,
            income: 1,
            summary: "demo",
            icon: "💻",
            requirements: .init(
                education: .init(minEQF: 0, acceptedProfiles: nil),
                softSkills: .init(
                    analyticalReasoningAndProblemSolving: 0,
                    creativityAndInsightfulThinking: 0,
                    communicationAndNetworking: 0,
                    leadershipAndInfluence: 0,
                    courageAndRiskTolerance: 0,
                    spacialNavigation: 0,
                    carefulnessAndAttentionToDetail: 0,
                    perseveranceAndGrit: 0,
                    tinkeringAndFingerPrecision: 0,
                    physicalStrength: 0,
                    coordinationAndBalance: 0,
                    resilienceAndEndurance: 0
                ),
                hardSkills: .init(certifications: [], licenses: [], software: [], portfolio: [])
            ),
            companyTier: nil,
            version: 6
        )
        #expect(job.category == .technology)
    }
}

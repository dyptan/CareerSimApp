//
//  HeaderView.swift
//  CareersApp
//
//  Created by Ivan Dyptan on 27.10.25.
//  Copyright © 2025 Apple. All rights reserved.
//
import SwiftUI

struct HeaderView: View {
    // Inject the model and all state this header needs to read/mutate
    @ObservedObject var player: Player

    @Binding var showDecisionSheet: Bool
    @Binding var showTertiarySheet: Bool
    @Binding var showCareersSheet: Bool

    @Binding var selectedActivities: Set<String>
    @Binding var selectedLanguages: Set<Language>
    @Binding var selectedSoftware: Set<Software>
    @Binding var selectedLicences: Set<License>
    @Binding var selectedPortfolio: Set<PortfolioItem>
    @Binding var selectedCertifications: Set<Certification>

    @Binding var yearsLeftToGraduation: Int?
    @Binding var descisionText: String

    private let maxActivitiesPerYear = 3

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Age: \(player.age)")
                    .font(.title2)
                Spacer()
                VStack(alignment: .leading, spacing: 8) {
                    // Visible activities counter
                    HStack(spacing: 6) {
                        Text("Activities this year:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(selectedActivities.count)/\(maxActivitiesPerYear)")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(selectedActivities.count >= maxActivitiesPerYear ? .red : .primary)
                    }

                    Button("+1 Year") {
                        // Lock certifications that were selected at the end of this year
                        player.lockedCertifications.formUnion(selectedCertifications)

                        player.age += 1
                        player.hardSkills.certifications.formUnion(
                            selectedCertifications
                        )
                        player.hardSkills.languages.formUnion(selectedLanguages)
                        player.hardSkills.licenses.formUnion(selectedLicences)
                        player.hardSkills.portfolioItems.formUnion(
                            selectedPortfolio
                        )
                        player.hardSkills.software.formUnion(selectedSoftware)

                        selectedActivities = []

                        yearsLeftToGraduation? -= 1
                        if yearsLeftToGraduation == 0 {
                            descisionText =
                                "You're done with your degree! What's your next step?"
                            showDecisionSheet.toggle()
                            if let currentEducation = player.currentEducation {
                                player.degrees.append(currentEducation)
                            }
                            yearsLeftToGraduation = nil
                            player.currentEducation = nil
                        }

                        if let income = player.currentOccupation?.income {
                            player.savings += income
                        }
                    }
                    .disabled(false)

                    if player.currentOccupation != nil {
                        Button("Find new Job") {
                            showCareersSheet.toggle()
                            player.currentOccupation = nil
                        }
                        Button("Get a new degree") {
                            showTertiarySheet.toggle()
                        }
                    }
                }
            }

            if let lastlog = player.degrees.last {
                HStack {
                    Text(lastlog.1.degree)
                    Text(String(repeating: "⭐️", count: lastlog.1.eqf))
                }
            } else {
                Text("⭐️")
            }

            Text("Bank balance: \(player.savings * 1000)")
            Text(String(repeating: "💶", count: player.savings / 10))

            if let currentOccupation = player.currentOccupation {
                Text(
                    "Occupation: \(currentOccupation.id) \(currentOccupation.icon)"
                )
            }
            if let currentEducation = player.currentEducation {
                Text(
                    "Studying: \(currentEducation.0.rawValue) \(currentEducation.1.rawValue)"
                )
            }

        }
        .padding(.top, 10)
    }
}

#Preview {
    HeaderView(
        player: Player(
            degrees: [(.some(.business), .Bachelor)],
            currentOccupation: .some(
                jobExample
            )
        ),
        showDecisionSheet: .constant(false),
        showTertiarySheet: .constant(false),
        showCareersSheet: .constant(false),
        selectedActivities: .constant(Set<String>()),
        selectedLanguages: .constant(Set<Language>()),
        selectedSoftware: .constant(Set<Software>()),
        selectedLicences: .constant(Set<License>()),
        selectedPortfolio: .constant(Set<PortfolioItem>()),
        selectedCertifications: .constant(Set<Certification>()),
        yearsLeftToGraduation: .constant(nil),
        descisionText: .constant("sdf")
    )
}


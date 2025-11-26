//
//  TrainingRequirementResult.swift
//  CareersApp
//
//  Created by Ivan Dyptan on 26.11.25.
//  Copyright © 2025 Apple. All rights reserved.
//


enum TrainingRequirementResult {
    case ok(cost: Int)
    case blocked(reason: String)
}
enum TrainingRequirementResult {
    case ok(cost: Int)
    case blocked(reason: String)
}

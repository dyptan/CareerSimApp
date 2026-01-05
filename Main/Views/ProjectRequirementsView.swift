import SwiftUI



public struct ProjectRequirementsView: View {


    public let requirements: [RequirementModel]

    public init(requirements: [RequirementModel]) {
        self.requirements = requirements
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(requirements) { req in
                RequirementRow(label: req.label, emoji: req.emoji, style: req.style)
            }
        }
    }
}

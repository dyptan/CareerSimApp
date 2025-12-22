import Foundation

public struct ProjectRequirements {
    public struct SoftRequirement {
        public let label: String
        public let emoji: String
        public let required: Int
        public let current: Int
        public init(label: String, emoji: String, required: Int, current: Int) {
            self.label = label
            self.emoji = emoji
            self.required = required
            self.current = current
        }
    }
    public struct HardRequirement {
        public let label: String
        public let emoji: String
        public let required: Int
        public let current: Int
        public init(label: String, emoji: String, required: Int, current: Int) {
            self.label = label
            self.emoji = emoji
            self.required = required
            self.current = current
        }
    }

    public let minEQF: Int?
    public let softSkills: [SoftRequirement]
    public let hardSkills: [HardRequirement]

    public init(minEQF: Int? = nil, softSkills: [SoftRequirement] = [], hardSkills: [HardRequirement] = []) {
        self.minEQF = minEQF
        self.softSkills = softSkills
        self.hardSkills = hardSkills
    }
}

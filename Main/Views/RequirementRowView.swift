import SwiftUI

public struct RequirementRowView: View {
    public let label: String
    public let emoji: String
    public let level: Int
    public let playerLevel: Int

    public init(label: String, emoji: String, level: Int, playerLevel: Int) {
        self.label = label
        self.emoji = emoji
        self.level = level
        self.playerLevel = playerLevel
    }

    public var body: some View {
        let required = max(level, 0)
        let meets = playerLevel >= required

        return HStack {
            Text(label)
            Spacer()
            HStack(spacing: 0) {
                ForEach(0..<required, id: \.self) { idx in
                    Text(emoji)
                        .opacity(idx < playerLevel ? 1.0 : 0.35)
                }
            }
            .font(.body)
        }
        .font(.body)
        .foregroundStyle(meets ? .primary : .secondary)
        .accessibilityHint(
            meets ? "\(label) requirement met" : "\(label) requirement not met"
        )
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        RequirementRowView(label: "Previous education", emoji: "🎓", level: 3, playerLevel: 2)
        RequirementRowView(label: "Problem Solving", emoji: "🧩", level: 4, playerLevel: 5)
    }
    .padding()
}

import SwiftUI

/// A reusable row to display a requirement with a label and a series of emoji
/// indicating required level vs. player level. Optionally, display a
/// quantifiable hard-skill indicator alongside.
public struct RequirementRow: View {
    private let label: String
    private let emoji: String
    private let level: Int
    private let playerLevel: Int

    // Optional hard-skill quantification
    // If provided, shows an additional trailing segment of repeated icons with met/unmet opacity.
    private let hardEmoji: String?
    private let hardRequiredLevel: Int?
    private let hardPlayerLevel: Int?

    public init(
        label: String,
        emoji: String,
        level: Int,
        playerLevel: Int,
        hardEmoji: String? = nil,
        hardRequiredLevel: Int? = nil,
        hardPlayerLevel: Int? = nil
    ) {
        self.label = label
        self.emoji = emoji
        self.level = level
        self.playerLevel = playerLevel
        self.hardEmoji = hardEmoji
        self.hardRequiredLevel = hardRequiredLevel
        self.hardPlayerLevel = hardPlayerLevel
    }

    public var body: some View {
        let required = max(level, 0)
        let meets = playerLevel >= required
        let showHard = (hardEmoji != nil) && (hardRequiredLevel != nil) && (hardPlayerLevel != nil)

        return HStack {
            Text(label)
            Spacer()
            HStack(spacing: 8) {
                // Soft-skill indicator
                HStack(spacing: 0) {
                    ForEach(0..<required, id: \.self) { idx in
                        Text(emoji)
                            .opacity(idx < playerLevel ? 1.0 : 0.35)
                    }
                }
                .font(.body)

                // Optional hard-skill quantification
                if showHard, let icon = hardEmoji, let req = hardRequiredLevel, let cur = hardPlayerLevel {
                    HStack(spacing: 0) {
                        ForEach(0..<max(req, 0), id: \.self) { idx in
                            Text(icon)
                                .opacity(idx < cur ? 1.0 : 0.35)
                        }
                    }
                    .font(.body)
                }
            }
        }
        .font(.body)
        .foregroundStyle(meets ? .primary : .secondary)
        .padding(.horizontal, 6)
    }
}

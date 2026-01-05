import SwiftUI

public enum Style {
    case meter(current: Int, required: Int)
    case badge(isMet: Bool)
}

public struct RequirementRow: View {
    let label: String
    let emoji: String
    let style: Style

    public init(label: String, emoji: String, style: Style) {
        self.label = label
        self.emoji = emoji
        self.style = style
    }

    public var body: some View {
        HStack {
            Text(label)
            Spacer()
            switch style {
            case let .meter(current, required):
                HStack(spacing: 4) {
                    ForEach(0..<required, id: \.self) { index in
                        Text(emoji)
                            .opacity(index < current ? 1.0 : 0.3)
                    }
                }
            case let .badge(isMet):
                Text(emoji)
                    .opacity(isMet ? 1.0 : 0.3)
            }
        }
    }
}

//public struct RequirementRow: View {
//    private let label: String
//    private let emoji: String
//    private let level: Int
//    private let playerLevel: Int
//    private let hardEmoji: String?
//    private let hardRequiredLevel: Int?
//    private let hardPlayerLevel: Int?
//
//    public init(
//        label: String,
//        emoji: String,
//        level: Int,
//        playerLevel: Int,
//        hardEmoji: String? = nil,
//        hardRequiredLevel: Int? = nil,
//        hardPlayerLevel: Int? = nil
//    ) {
//        self.label = label
//        self.emoji = emoji
//        self.level = level
//        self.playerLevel = playerLevel
//        self.hardEmoji = hardEmoji
//        self.hardRequiredLevel = hardRequiredLevel
//        self.hardPlayerLevel = hardPlayerLevel
//    }
//
//    public var body: some View {
//        let required = max(level, 0)
//        let meets = playerLevel >= required
//        let showHard = (hardEmoji != nil) && (hardRequiredLevel != nil) && (hardPlayerLevel != nil)
//
//        return HStack {
//            Text(label)
//            Spacer()
//            HStack(spacing: 8) {
//                HStack(spacing: 0) {
//                    ForEach(0..<required, id: \.self) { idx in
//                        Text(emoji)
//                            .opacity(idx < playerLevel ? 1.0 : 0.35)
//                    }
//                }
//                .font(.body)
//
//                if showHard, let icon = hardEmoji, let req = hardRequiredLevel, let cur = hardPlayerLevel {
//                    HStack(spacing: 0) {
//                        ForEach(0..<max(req, 0), id: \.self) { idx in
//                            Text(icon)
//                                .opacity(idx < cur ? 1.0 : 0.35)
//                        }
//                    }
//                    .font(.body)
//                }
//            }
//        }
//        .font(.body)
//        .foregroundStyle(meets ? .primary : .secondary)
//        .padding(.horizontal, 6)
//    }
//}

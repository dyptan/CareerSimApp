import SwiftUI

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
            // A long translated label wraps onto a second line instead of squeezing the
            // emoji meter or being cut off.
            Text(label)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            switch style {
            case let .meter(current, required):
                HStack(spacing: 4) {
                    ForEach(0..<max(0, required), id: \.self) { index in
                        Text(emoji)
                            .opacity(index < current ? 1.0 : 0.3)
                    }
                }
                .fixedSize()
                .layoutPriority(1)
            case let .badge(isMet):
                Text(emoji)
                    .opacity(isMet ? 1.0 : 0.3)
                    .layoutPriority(1)
            }
        }
    }
}

#Preview {
    RequirementRow(label: "Test", emoji: "🌟", style: .meter(current: 3, required: 5))  // i18n:ignore preview
}

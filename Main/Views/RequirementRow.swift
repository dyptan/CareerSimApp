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

#Preview {
    RequirementRow(label: "Test", emoji: "🌟", style: .meter(current: 3, required: 5))
}

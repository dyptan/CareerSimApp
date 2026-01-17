import Foundation
public struct Requirement: Identifiable {
    public let id = UUID()
    public let label: String
    public let emoji: String
    public let style: Style
    public init(label: String, emoji: String, style: Style) {
        self.label = label
        self.emoji = emoji
        self.style = style
    }
}

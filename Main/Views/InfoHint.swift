import SwiftUI

/// A small "i" icon that opens a short popover description on tap.
/// Used to demystify abbreviations and game-specific terms (cert names, soft skills, education levels)
/// for younger or first-time players.
struct InfoHint: View {
    let title: String
    let message: String
    @State private var showing = false
    /// Measured natural height of the message text, used to size the scroll area
    /// so short hints fit snugly and only long ones scroll (capped at `maxMessageHeight`).
    @State private var messageHeight: CGFloat = 0

    /// The popover never grows the message beyond this; past it the text scrolls.
    private let maxMessageHeight: CGFloat = 280

    var body: some View {
        Button {
            showing = true
        } label: {
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)
                .imageScale(.medium)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showing) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                // Long hints (e.g. valuation / formula explanations) can exceed the
                // popover; scroll the body instead of overflowing, while the title
                // stays pinned above.
                ScrollView {
                    Text(message)
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(key: HintHeightKey.self, value: geo.size.height)
                            }
                        )
                }
                .frame(height: min(max(messageHeight, 0), maxMessageHeight))
                .onPreferenceChange(HintHeightKey.self) { messageHeight = $0 }
            }
            .padding()
            .frame(idealWidth: 300, maxWidth: 320, alignment: .leading)
            .modifier(CompactPopoverAdaptation())
        }
    }
}

/// Carries the measured natural height of the hint message up so the scroll view
/// can size itself to the content (up to the cap).
private struct HintHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

/// Forces popover presentation on iPhone (otherwise the OS would use a sheet).
/// Available iOS 16.4+ / macOS 13.3+; older OSes fall back to the default sheet.
private struct CompactPopoverAdaptation: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.4, macOS 13.3, *) {
            content.presentationCompactAdaptation(.popover)
        } else {
            content
        }
    }
}

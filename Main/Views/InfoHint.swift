import SwiftUI

/// A small "i" icon that opens a short popover description on tap.
/// Used to demystify abbreviations and game-specific terms (cert names, soft skills, education levels)
/// for younger or first-time players. `symbol` swaps the icon for popovers that
/// carry something other than an explanation (e.g. an activity's contest).
///
/// `title` and `message` are finished, already-localized text (build them with
/// `L(...)`). The popover scrolls when the text outgrows `maxHeight`, so a long
/// hint — German and Ukrainian run about a third longer than English — is never cut off.
struct InfoHint: View {
    let title: String
    let message: String
    var symbol: String = "info.circle"  // i18n:ignore SF Symbol name
    @State private var showing = false
    /// The tallest the popover grows before it scrolls.
    private static let maxHeight: CGFloat = 420

    var body: some View {
        Button {
            showing = true
        } label: {
            Image(systemName: symbol)
                .foregroundStyle(.secondary)
                .imageScale(.medium)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showing) {
            // An invisible copy of the text sets the popover's size — as tall as
            // the text, up to `maxHeight` — and the same text, in a scroll view,
            // is laid over it. Short hints get a snug popover; long ones scroll.
            popoverText
                .hidden()
                .frame(maxHeight: Self.maxHeight)
                .overlay(ScrollView { popoverText })
                // The popover picks up the styling around its ⓘ — a section
                // title's blue tint and centring, a bold row's weight — so it sets
                // its own and reads the same wherever the ⓘ sits. `Color.primary`,
                // not `.primary`: the hierarchical style resolves against the
                // inherited tint and stays blue.
                .foregroundStyle(Color.primary)
                .multilineTextAlignment(.leading)
                .fontWeight(nil)
                .frame(idealWidth: 300, maxWidth: 320, alignment: .leading)
                .modifier(CompactPopoverAdaptation())
        }
    }

    private var popoverText: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
            Text(message)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
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

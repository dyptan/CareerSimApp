import SwiftUI

/// A small "i" icon that opens a short popover description on tap.
/// Used to demystify abbreviations and game-specific terms (cert names, soft skills, education levels)
/// for younger or first-time players. `symbol` swaps the icon for popovers that
/// carry something other than an explanation (e.g. an activity's contest).
struct InfoHint: View {
    let title: String
    let message: String
    var symbol: String = "info.circle"
    @State private var showing = false

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
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                Text(message)
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
            }
            // The popover picks up the styling around its ⓘ — a section
            // title's blue tint and centring, a bold row's weight — so it sets
            // its own and reads the same wherever the ⓘ sits. `Color.primary`,
            // not `.primary`: the hierarchical style resolves against the
            // inherited tint and stays blue.
            .foregroundStyle(Color.primary)
            .multilineTextAlignment(.leading)
            .fontWeight(nil)
            .padding()
            .frame(idealWidth: 300, maxWidth: 320, alignment: .leading)
            .modifier(CompactPopoverAdaptation())
        }
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

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
    private static let maxHeight: CGFloat = 520

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
            // As tall as the text — up to `maxHeight`, and never more than the room the system
            // offers this popover (it sits where the ⓘ is, so the room varies) — with the text in a
            // scroll view when it doesn't all fit. A hidden copy measures the text; see `CappedHeight`.
            CappedHeight(cap: Self.maxHeight) {
                popoverText.hidden()
                ScrollView { popoverText }
                    .scrollIndicators(.visible)
            }
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

/// Lays out two views in one box: the first (hidden) only measures the text, the second (the scroll
/// view) fills the box. The box is as tall as the text, but never taller than `cap` or than the height
/// the popover is offered — which a plain `.frame(maxHeight:)` around a fixed-size text would ignore,
/// leaving the popover clipped at top and bottom where there is little room.
private struct CappedHeight: Layout {
    var cap: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let measure = subviews.first else { return .zero }
        let width = proposal.width ?? 300
        let natural = measure.sizeThatFits(ProposedViewSize(width: width, height: nil))
        let height = min(natural.height, cap, proposal.height ?? .infinity)
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 2 else { return }
        subviews[0].place(at: bounds.origin, anchor: .topLeading, proposal: ProposedViewSize(width: bounds.width, height: nil))
        subviews[1].place(at: bounds.origin, anchor: .topLeading, proposal: ProposedViewSize(bounds.size))
    }
}

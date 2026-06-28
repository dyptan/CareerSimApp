import SwiftUI

@main
struct Main: App {
    init() {
        #if DEBUG
        // Catalogue integrity check — runs on every debug launch since the
        // project has no XCTest target. Fails loudly if a project is orphaned,
        // a licence chain forms a cycle, or a job requires something unbuildable.
        // O(catalogue size): reachability, not a combinatorial player sweep.
        let issues = CareerGraph.validateCatalogue()
        for issue in issues { print("⚠️ CareerGraph: \(issue)") }
        assert(issues.isEmpty, "Career graph validation failed (\(issues.count) issue(s)) — see console.")
        #endif
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                RootView()
            }
            .onAppear { GameCenterManager.shared.authenticate() }
        }
        #if os(macOS)
        // Bind the macOS window to its content's size so the mode-selection
        // dialog stays at its fixed width instead of stretching to infinity.
        .windowResizability(.contentSize)
        #endif
    }
}



#Preview {
    if #available(macOS 13.0, iOS 16.0, *) {
        NavigationStack {
            RootView()
        }
        .frame(width: 1000, height: 700)
    } else {
        NavigationView {
            RootView()
        }
        .frame(width: 1000, height: 700)
    }
}

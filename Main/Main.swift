import SwiftUI

@main
struct Main: App {
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
    NavigationStack {
        RootView()
    }
    .frame(width: 1000, height: 700)
}

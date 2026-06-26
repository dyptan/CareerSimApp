import SwiftUI

@main
struct Main: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                RootView()
            }
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

import SwiftUI

@main
struct Main: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                MainView()
            }
        }
    }
}

#Preview {
    NavigationStack {
        MainView()
    }
}

import SwiftUI

@main
struct Main: App {
    var body: some Scene {
        WindowGroup {
            if #available(macOS 13.0, *) {
                NavigationStack {
                    MainView()
                }
            } else {
                NavigationView {
                    MainView()
                }
            }
        }
    }
}

#Preview {
    
    if #available(macOS 13.0, *) {
        NavigationStack {
            MainView()
        }
    } else {
        NavigationView {
        MainView()
    }
    }
    
}

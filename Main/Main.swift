import SwiftUI

@main
struct Main: App {
    var body: some Scene {
        WindowGroup {
            if #available(macOS 13.0, *) {
                ScrollView {
                    NavigationStack {
                        MainView()
                    }
                }
            } else {
                ScrollView {
                    NavigationView {
                        MainView()
                    }
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

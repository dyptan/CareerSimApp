import SwiftUI

@main
struct Main: App {
    var body: some Scene {
        WindowGroup {
            if #available(macOS 13.0, iOS 16.0, *) {
                NavigationStack {
                    RootView()
                }
            } else {
                NavigationView {
                    RootView()
                }
            }
        }
    
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

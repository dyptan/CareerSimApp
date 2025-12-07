import SwiftUI

@main
struct Main: App {
    var body: some Scene {
        WindowGroup {
            if #available(macOS 13.0, iOS 16.0, *) {
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
    if #available(macOS 13.0, iOS 16.0, *) {
        NavigationStack {
            MainView()
        }
        .frame(width: 1000, height: 700)
    } else {
        NavigationView {
            MainView()
        }
        .frame(width: 1000, height: 700)
    }
}

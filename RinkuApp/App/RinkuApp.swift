import SwiftUI

@main
struct RinkuApp: App {
    @StateObject private var store = AppStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}

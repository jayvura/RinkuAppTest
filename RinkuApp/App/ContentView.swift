import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppStore.shared
    @StateObject private var onboardingManager = OnboardingManager.shared
    @State private var selectedTab: TabItem = .home

    var body: some View {
        Group {
            if onboardingManager.hasCompletedOnboarding {
                // Main App
                mainAppView
            } else {
                // First-time onboarding
                OnboardingView(onboardingManager: onboardingManager)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: onboardingManager.hasCompletedOnboarding)
    }
    
    private var mainAppView: some View {
        ZStack(alignment: .bottom) {
            // Main Content
            Group {
                switch selectedTab {
                case .home:
                    HomeView(selectedTab: $selectedTab)
                case .lovedOnes:
                    LovedOnesView(store: store, selectedTab: $selectedTab)
                case .add:
                    AddLovedOneView(store: store, selectedTab: $selectedTab)
                case .recognize:
                    RecognizeView(store: store, selectedTab: $selectedTab)
                case .profile:
                    ProfileView(store: store)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Tab Bar
            TabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

#Preview("Main App") {
    let manager = OnboardingManager.shared
    manager.completeOnboarding()
    return ContentView()
}

#Preview("Onboarding") {
    OnboardingView(onboardingManager: OnboardingManager.shared)
}

import Foundation

/// Manages onboarding state - tracks if user has completed first-time setup
final class OnboardingManager: ObservableObject {
    
    static let shared = OnboardingManager()
    
    private let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: hasCompletedOnboardingKey)
        }
    }
    
    private init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey)
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
    
    /// For testing - resets onboarding state
    func resetOnboarding() {
        hasCompletedOnboarding = false
    }
}

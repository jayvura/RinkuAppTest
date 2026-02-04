import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: TabItem
    @ObservedObject private var languageManager = LanguageManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Text("app_name".localized)
                        .font(.system(size: Theme.FontSize.h1, weight: .bold))
                        .foregroundColor(Theme.Colors.primary)

                    Text("app_tagline".localized)
                        .font(.system(size: Theme.FontSize.body))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .padding(.top, 16)

                // Main CTAs
                VStack(spacing: 16) {
                    RinkuButton(
                        title: "home_loved_ones_button".localized,
                        icon: "person.2.fill",
                        variant: .primary,
                        size: .large
                    ) {
                        selectedTab = .lovedOnes
                    }

                    RinkuButton(
                        title: "home_add_button".localized,
                        icon: "person.fill.badge.plus",
                        variant: .secondary,
                        size: .large
                    ) {
                        selectedTab = .add
                    }

                    RinkuButton(
                        title: "home_recognize_button".localized,
                        icon: "camera.fill",
                        variant: .primary,
                        size: .large
                    ) {
                        selectedTab = .recognize
                    }
                }

                // Info Card
                VStack {
                    Text("home_info_card".localized)
                        .font(.system(size: Theme.FontSize.body))
                        .foregroundColor(Theme.Colors.primaryDark)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .background(Theme.Colors.primaryLight)
                .cornerRadius(Theme.CornerRadius.medium)

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
        }
        .background(Theme.Colors.background)
        .id(languageManager.currentLanguage) // Force refresh when language changes
    }
}

#Preview {
    HomeView(selectedTab: .constant(.home))
}

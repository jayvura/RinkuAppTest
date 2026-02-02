import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: TabItem

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Text("Rinku AI")
                        .font(.system(size: Theme.FontSize.h1, weight: .bold))
                        .foregroundColor(Theme.Colors.primary)

                    Text("A gentle memory companion.")
                        .font(.system(size: Theme.FontSize.body))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .padding(.top, 16)

                // Main CTAs
                VStack(spacing: 16) {
                    RinkuButton(
                        title: "Loved Ones",
                        icon: "person.2.fill",
                        variant: .primary,
                        size: .large
                    ) {
                        selectedTab = .lovedOnes
                    }

                    RinkuButton(
                        title: "Add Loved One",
                        icon: "person.fill.badge.plus",
                        variant: .secondary,
                        size: .large
                    ) {
                        selectedTab = .add
                    }

                    RinkuButton(
                        title: "Recognize",
                        icon: "camera.fill",
                        variant: .primary,
                        size: .large
                    ) {
                        selectedTab = .recognize
                    }
                }

                // Info Card
                VStack {
                    Text("Use the camera to recognize loved ones and hear gentle reminders about your relationship.")
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
    }
}

#Preview {
    HomeView(selectedTab: .constant(.home))
}

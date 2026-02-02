import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let ctaLabel: String
    let onCtaClick: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Theme.Colors.primaryLight)
                    .frame(width: 64, height: 64)

                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(Theme.Colors.primary)
            }

            // Title
            Text(title)
                .font(.system(size: Theme.FontSize.h2, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)

            // Body
            Text(message)
                .font(.system(size: Theme.FontSize.body))
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)

            // CTA Button
            RinkuButton(
                title: ctaLabel,
                variant: .primary,
                size: .large,
                action: onCtaClick
            )
        }
        .padding(32)
        .background(Color.white)
        .cornerRadius(Theme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                .foregroundColor(Theme.Colors.border)
        )
    }
}

#Preview {
    EmptyStateView(
        icon: "person.fill.badge.plus",
        title: "No loved ones yet",
        message: "Add people you want to recognize. Include their name, relationship, and a memory prompt.",
        ctaLabel: "Add Loved One"
    ) {
        print("CTA tapped")
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

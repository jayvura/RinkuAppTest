import SwiftUI

struct PersonListItem: View {
    let name: String
    let relationship: String
    var avatarText: String? = nil
    var action: (() -> Void)? = nil

    private var initials: String {
        if let text = avatarText {
            return text
        }
        let parts = name.split(separator: " ")
        if parts.count == 1 {
            return String(parts[0].prefix(2)).uppercased()
        }
        let first = parts.first?.first ?? Character(" ")
        let last = parts.last?.first ?? Character(" ")
        return "\(first)\(last)".uppercased()
    }

    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Theme.Colors.primaryLight)
                        .frame(width: 48, height: 48)

                    Text(initials)
                        .font(.system(size: Theme.FontSize.body, weight: .semibold))
                        .foregroundColor(Theme.Colors.primary)
                }

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: Theme.FontSize.body, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .lineLimit(1)

                    Text(relationship)
                        .font(.system(size: Theme.FontSize.caption))
                        .foregroundColor(Theme.Colors.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(Theme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(Theme.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: 12) {
        PersonListItem(name: "Gabriela Martinez", relationship: "Daughter")
        PersonListItem(name: "Michael Chen", relationship: "Son")
        PersonListItem(name: "John", relationship: "Friend")
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

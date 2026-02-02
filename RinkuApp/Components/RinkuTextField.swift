import SwiftUI

struct RinkuTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var helperText: String? = nil
    var errorText: String? = nil
    var isRequired: Bool = false
    var isMultiline: Bool = false
    var leadingIcon: String? = nil

    private var hasError: Bool {
        errorText != nil && !errorText!.isEmpty
    }

    private var borderColor: Color {
        hasError ? Theme.Colors.danger : Theme.Colors.border
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            HStack(spacing: 4) {
                Text(label)
                    .font(.system(size: Theme.FontSize.body, weight: .medium))
                    .foregroundColor(Theme.Colors.textPrimary)

                if isRequired {
                    Text("*")
                        .font(.system(size: Theme.FontSize.body, weight: .medium))
                        .foregroundColor(Theme.Colors.danger)
                }
            }

            // Input Field
            HStack(spacing: 12) {
                if let icon = leadingIcon {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(Theme.Colors.textSecondary)
                }

                if isMultiline {
                    TextEditor(text: $text)
                        .font(.system(size: Theme.FontSize.body))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .frame(minHeight: 100, maxHeight: 150)
                        .scrollContentBackground(.hidden)
                } else {
                    TextField(placeholder, text: $text)
                        .font(.system(size: Theme.FontSize.body))
                        .foregroundColor(Theme.Colors.textPrimary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, isMultiline ? 12 : 0)
            .frame(minHeight: isMultiline ? nil : 48)
            .background(Color.white)
            .cornerRadius(Theme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(borderColor, lineWidth: 2)
            )

            // Helper/Error Text
            if let error = errorText, !error.isEmpty {
                Text(error)
                    .font(.system(size: Theme.FontSize.caption))
                    .foregroundColor(Theme.Colors.danger)
            } else if let helper = helperText {
                Text(helper)
                    .font(.system(size: Theme.FontSize.caption))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        RinkuTextField(
            label: "Full Name",
            text: .constant(""),
            placeholder: "e.g., Gabriela Martinez",
            isRequired: true
        )

        RinkuTextField(
            label: "Familiar Name",
            text: .constant(""),
            placeholder: "e.g., Gabi (optional)",
            helperText: "The name you usually call them"
        )

        RinkuTextField(
            label: "Full Name",
            text: .constant(""),
            placeholder: "Required field",
            errorText: "Full name is required",
            isRequired: true
        )

        RinkuTextField(
            label: "Memory Prompt",
            text: .constant(""),
            placeholder: "e.g., She loves painting...",
            helperText: "A gentle reminder about this person (optional)",
            isMultiline: true
        )

        RinkuTextField(
            label: "Search",
            text: .constant(""),
            placeholder: "Search by name or relationship",
            leadingIcon: "magnifyingglass"
        )
    }
    .padding()
}

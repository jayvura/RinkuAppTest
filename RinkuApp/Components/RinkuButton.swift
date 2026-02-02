import SwiftUI

enum ButtonVariant {
    case primary
    case secondary
    case destructive
}

enum ButtonSize {
    case medium
    case large

    var height: CGFloat {
        switch self {
        case .medium:
            return 44
        case .large:
            return 52
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .medium:
            return 16
        case .large:
            return 24
        }
    }
}

struct RinkuButton: View {
    let title: String
    var icon: String? = nil
    var variant: ButtonVariant = .primary
    var size: ButtonSize = .medium
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    private var backgroundColor: Color {
        switch variant {
        case .primary:
            return Theme.Colors.primary
        case .secondary:
            return .white
        case .destructive:
            return Theme.Colors.danger
        }
    }

    private var pressedBackgroundColor: Color {
        switch variant {
        case .primary:
            return Theme.Colors.primaryDark
        case .secondary:
            return Color.gray.opacity(0.1)
        case .destructive:
            return Color(hex: "C62828")
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary, .destructive:
            return .white
        case .secondary:
            return Theme.Colors.textPrimary
        }
    }

    private var borderColor: Color {
        switch variant {
        case .secondary:
            return Theme.Colors.border
        default:
            return .clear
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                        .scaleEffect(0.9)
                }

                if let icon = icon, !isLoading {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                }

                Text(title)
                    .font(.system(size: Theme.FontSize.body, weight: .medium))
            }
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .background(backgroundColor)
            .cornerRadius(Theme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(borderColor, lineWidth: variant == .secondary ? 2 : 0)
            )
        }
        .disabled(isDisabled || isLoading)
        .opacity((isDisabled || isLoading) ? 0.5 : 1.0)
        .buttonStyle(RinkuButtonStyle(pressedColor: pressedBackgroundColor, variant: variant))
    }
}

struct RinkuButtonStyle: ButtonStyle {
    let pressedColor: Color
    let variant: ButtonVariant

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Group {
                    if configuration.isPressed {
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                            .fill(pressedColor)
                    }
                }
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 16) {
        RinkuButton(title: "Primary Button", variant: .primary, size: .large) {}
        RinkuButton(title: "Secondary Button", variant: .secondary, size: .large) {}
        RinkuButton(title: "Destructive", variant: .destructive, size: .medium) {}
        RinkuButton(title: "With Icon", icon: "person.fill.badge.plus", variant: .primary) {}
        RinkuButton(title: "Loading", isLoading: true) {}
        RinkuButton(title: "Disabled", isDisabled: true) {}
    }
    .padding()
}

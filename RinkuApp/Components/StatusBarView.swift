import SwiftUI

struct StatusBarView: View {
    let type: StatusType
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: type.iconName)
                .font(.system(size: 14))

            Text(message)
                .font(.system(size: Theme.FontSize.caption))
        }
        .foregroundColor(type.foregroundColor)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(type.backgroundColor)
        .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 16) {
        StatusBarView(type: .info, message: "Loading models...")
        StatusBarView(type: .success, message: "Ready to recognize")
        StatusBarView(type: .warning, message: "Person not recognized")
        StatusBarView(type: .danger, message: "Error occurred")
    }
    .padding()
}

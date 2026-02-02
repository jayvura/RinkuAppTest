import SwiftUI

enum TabItem: Int, CaseIterable {
    case home
    case lovedOnes
    case add
    case recognize
    case profile

    var title: String {
        switch self {
        case .home:
            return "Home"
        case .lovedOnes:
            return "Loved Ones"
        case .add:
            return "Add"
        case .recognize:
            return "Recognize"
        case .profile:
            return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home:
            return "house.fill"
        case .lovedOnes:
            return "person.2.fill"
        case .add:
            return "person.fill.badge.plus"
        case .recognize:
            return "camera.fill"
        case .profile:
            return "person.circle.fill"
        }
    }
}

struct TabBar: View {
    @Binding var selectedTab: TabItem

    var body: some View {
        HStack {
            ForEach(TabItem.allCases, id: \.self) { tab in
                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    action: { selectedTab = tab }
                )
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Theme.Colors.border),
            alignment: .top
        )
    }
}

struct TabBarButton: View {
    let tab: TabItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Theme.Colors.primary : Theme.Colors.textSecondary)

                Text(tab.title)
                    .font(.system(size: Theme.FontSize.caption, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Theme.Colors.primary : Theme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 60)
        }
    }
}

#Preview {
    VStack {
        Spacer()
        TabBar(selectedTab: .constant(.home))
    }
}

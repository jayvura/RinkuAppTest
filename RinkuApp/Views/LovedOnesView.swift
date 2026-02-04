import SwiftUI

struct LovedOnesView: View {
    @ObservedObject var store: AppStore
    @Binding var selectedTab: TabItem
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var searchQuery = ""
    @State private var selectedPerson: LovedOne? = nil

    private var filteredLovedOnes: [LovedOne] {
        if searchQuery.isEmpty {
            return store.lovedOnes
        }
        return store.lovedOnes.filter { person in
            person.fullName.localizedCaseInsensitiveContains(searchQuery) ||
            person.relationship.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("loved_ones_title".localized)
                        .font(.system(size: Theme.FontSize.h1, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)
                    Spacer()
                }

                if store.lovedOnes.isEmpty {
                    // Empty State
                    EmptyStateView(
                        icon: "person.fill.badge.plus",
                        title: "loved_ones_empty_title".localized,
                        message: "loved_ones_empty_subtitle".localized,
                        ctaLabel: "loved_ones_add_first".localized
                    ) {
                        selectedTab = .add
                    }
                    .padding(.top, 32)
                } else {
                    // Search
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.Colors.textSecondary)

                        TextField("Search by name or relationship", text: $searchQuery)
                            .font(.system(size: Theme.FontSize.body))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(Theme.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                            .stroke(Theme.Colors.border, lineWidth: 2)
                    )

                    // List
                    VStack(spacing: 12) {
                        if filteredLovedOnes.isEmpty {
                            Text("No matches found for \"\(searchQuery)\"")
                                .font(.system(size: Theme.FontSize.body))
                                .foregroundColor(Theme.Colors.textSecondary)
                                .padding(.vertical, 32)
                        } else {
                            ForEach(filteredLovedOnes) { person in
                                PersonListItem(
                                    name: person.displayName,
                                    relationship: person.relationship
                                ) {
                                    selectedPerson = person
                                }
                            }
                        }
                    }
                }

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
            .padding(.top, 32)
        }
        .background(Theme.Colors.background)
        .fullScreenCover(item: $selectedPerson) { person in
            // Fetch the latest version from store in case it was updated
            if let currentPerson = store.getLovedOne(byId: person.id) {
                LovedOneDetailView(store: store, lovedOne: currentPerson)
            }
        }
        .id(languageManager.currentLanguage) // Force refresh when language changes
    }
}

#Preview {
    LovedOnesView(store: AppStore.shared, selectedTab: .constant(.lovedOnes))
}

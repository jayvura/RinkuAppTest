import SwiftUI

struct ProfileView: View {
    @ObservedObject var store: AppStore
    @ObservedObject private var authService = AuthService.shared
    @ObservedObject private var audioService = AudioService.shared
    @ObservedObject private var historyService = RecognitionHistoryService.shared
    @ObservedObject private var offlineCache = OfflineFaceCache.shared
    @ObservedObject private var onboardingManager = OnboardingManager.shared
    @ObservedObject private var familyService = FamilyService.shared
    @ObservedObject private var wearablesService = WearablesService.shared
    
    @State private var showAuthSheet = false
    @State private var showSignOutAlert = false
    @State private var showFullHistory = false
    @State private var showFamilyView = false
    @State private var showGlassesSettings = false
    
    private var userName: String {
        authService.currentUser?.fullName ?? authService.currentUser?.email ?? "Guest User"
    }
    
    private var userEmail: String {
        authService.currentUser?.email ?? "Sign in to sync your data"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Profile")
                        .font(.system(size: Theme.FontSize.h1, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)
                    Spacer()
                }
                
                // Profile Card
                ProfileCardView(
                    name: userName,
                    email: userEmail,
                    isSignedIn: authService.isSignedIn,
                    lovedOnesCount: store.lovedOnes.count,
                    recognitionsToday: historyService.todayEvents().count
                )
                
                // Recognition History Section
                if !historyService.events.isEmpty {
                    VStack(spacing: 12) {
                        HStack {
                            ProfileSectionHeader(title: "Recent Activity")
                            Spacer()
                            Button {
                                showFullHistory = true
                            } label: {
                                Text("See All")
                                    .font(.system(size: Theme.FontSize.caption, weight: .medium))
                                    .foregroundColor(Theme.Colors.primary)
                            }
                        }
                        
                        // Show last 3 recognitions
                        ForEach(historyService.events.prefix(3)) { event in
                            RecognitionHistoryItem(event: event)
                        }
                    }
                }
                
                // Account Section
                if !authService.isSignedIn {
                    VStack(spacing: 12) {
                        ProfileSectionHeader(title: "Account")
                        
                        ProfileActionButton(
                            icon: "person.crop.circle.badge.plus",
                            label: "Sign Up",
                            subtitle: "Create an account to backup your data",
                            color: Theme.Colors.primary
                        ) {
                            showAuthSheet = true
                        }
                        
                        ProfileActionButton(
                            icon: "arrow.right.circle.fill",
                            label: "Sign In",
                            subtitle: "Already have an account?",
                            color: Theme.Colors.success
                        ) {
                            showAuthSheet = true
                        }
                    }
                }
                
                // Family Section (only show if signed in)
                if authService.isSignedIn {
                    VStack(spacing: 12) {
                        ProfileSectionHeader(title: "Family")
                        
                        if let family = familyService.currentFamily {
                            // Show current family
                            FamilyCard(
                                family: family,
                                memberCount: familyService.familyMembers.count
                            ) {
                                showFamilyView = true
                            }
                        } else {
                            // Prompt to create or join
                            ProfileActionButton(
                                icon: "person.3.fill",
                                label: "Set Up Family Sharing",
                                subtitle: "Share loved ones with caregivers",
                                color: Theme.Colors.primary
                            ) {
                                showFamilyView = true
                            }
                        }
                    }
                }
                
                // Smart Glasses Section
                VStack(spacing: 12) {
                    ProfileSectionHeader(title: "Smart Glasses")
                    
                    GlassesConnectionItem(
                        registrationState: wearablesService.registrationState,
                        isSDKConfigured: wearablesService.isSDKConfigured,
                        onTap: { showGlassesSettings = true },
                        onConnect: { wearablesService.connectGlasses() }
                    )
                }
                
                // Settings Section
                VStack(spacing: 12) {
                    ProfileSectionHeader(title: "Settings")
                    
                    // Audio Reminders Toggle
                    AudioToggleItem(
                        isEnabled: $audioService.isEnabled,
                        onToggle: { enabled in
                            audioService.setEnabled(enabled)
                        }
                    )
                    
                    ProfileItem(
                        icon: "bell.fill",
                        label: "Notifications",
                        type: .toggle,
                        isEnabled: true
                    )
                    
                    ProfileItem(
                        icon: "camera.fill",
                        label: "Camera Access",
                        value: "Enabled",
                        type: .info
                    )
                    
                    // Offline cache info
                    ProfileItem(
                        icon: "wifi.slash",
                        label: "Offline Cache",
                        value: "\(offlineCache.cachedFaces.count) faces cached",
                        type: .info
                    )
                    
                    // Replay tutorial button
                    Button {
                        onboardingManager.resetOnboarding()
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Theme.Colors.primaryLight)
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Theme.Colors.primary)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Replay Tutorial")
                                    .font(.system(size: Theme.FontSize.body, weight: .medium))
                                    .foregroundColor(Theme.Colors.textPrimary)
                                
                                Text("View the welcome screens again")
                                    .font(.system(size: Theme.FontSize.caption))
                                    .foregroundColor(Theme.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
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
                }
                
                // Support Section
                VStack(spacing: 12) {
                    ProfileSectionHeader(title: "Support")
                    
                    ProfileItem(
                        icon: "shield.fill",
                        label: "Privacy Policy",
                        type: .link
                    )
                    
                    ProfileItem(
                        icon: "doc.text.fill",
                        label: "Terms of Service",
                        type: .link
                    )
                    
                    ProfileItem(
                        icon: "questionmark.circle.fill",
                        label: "Help & FAQ",
                        type: .link
                    )
                    
                    ProfileItem(
                        icon: "envelope.fill",
                        label: "Contact Support",
                        type: .link
                    )
                }
                
                // Sign Out Button (only if signed in)
                if authService.isSignedIn {
                    Button {
                        showSignOutAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                        .font(.system(size: Theme.FontSize.body, weight: .medium))
                        .foregroundColor(Theme.Colors.danger)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.Colors.dangerLight)
                        .cornerRadius(Theme.CornerRadius.medium)
                    }
                    .padding(.top, 8)
                }
                
                // App Info
                VStack(spacing: 4) {
                    Text("Rinku AI v1.0.0")
                        .font(.system(size: Theme.FontSize.caption))
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    Text("A gentle memory companion for those living with Alzheimer's")
                        .font(.system(size: Theme.FontSize.caption))
                        .foregroundColor(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
            .padding(.top, 32)
        }
        .background(Theme.Colors.background)
        .sheet(isPresented: $showAuthSheet) {
            AuthView(authService: authService)
        }
        .sheet(isPresented: $showFullHistory) {
            RecognitionHistoryView(historyService: historyService)
        }
        .sheet(isPresented: $showFamilyView) {
            FamilyView(familyService: familyService)
        }
        .sheet(isPresented: $showGlassesSettings) {
            GlassesSettingsView()
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task {
                    await authService.signOut()
                }
            }
        } message: {
            Text("Are you sure you want to sign out? Your data will remain on this device.")
        }
    }
}

// MARK: - Profile Card

struct ProfileCardView: View {
    let name: String
    let email: String
    let isSignedIn: Bool
    let lovedOnesCount: Int
    var recognitionsToday: Int = 0
    
    private var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.primary, Theme.Colors.primaryDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                if isSignedIn {
                    Text(initials)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
            }
            
            // Name & Email
            VStack(spacing: 4) {
                Text(name)
                    .font(.system(size: Theme.FontSize.h2, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Text(email)
                    .font(.system(size: Theme.FontSize.caption))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            
            // Stats
            HStack(spacing: 24) {
                ProfileStatItem(value: "\(lovedOnesCount)", label: "Loved Ones")
                
                ProfileStatItem(value: "\(recognitionsToday)", label: "Today")
                
                if isSignedIn {
                    ProfileStatItem(value: "Synced", label: "Status", isPositive: true)
                } else {
                    ProfileStatItem(value: "Local", label: "Storage", isPositive: false)
                }
            }
            .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(Theme.CornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }
}

// MARK: - Stat Item

struct ProfileStatItem: View {
    let value: String
    let label: String
    var isPositive: Bool? = nil
    
    var body: some View {
        VStack(spacing: 4) {
            if let isPositive = isPositive {
                HStack(spacing: 4) {
                    Circle()
                        .fill(isPositive ? Theme.Colors.success : Theme.Colors.warning)
                        .frame(width: 8, height: 8)
                    Text(value)
                        .font(.system(size: Theme.FontSize.body, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                }
            } else {
                Text(value)
                    .font(.system(size: Theme.FontSize.h2, weight: .bold))
                    .foregroundColor(Theme.Colors.primary)
            }
            
            Text(label)
                .font(.system(size: Theme.FontSize.caption))
                .foregroundColor(Theme.Colors.textSecondary)
        }
    }
}

// MARK: - Section Header

struct ProfileSectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: Theme.FontSize.caption, weight: .semibold))
                .foregroundColor(Theme.Colors.textSecondary)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.top, 8)
    }
}

// MARK: - Profile Item Types

enum ProfileItemType {
    case info
    case link
    case toggle
}

// MARK: - Profile Item

struct ProfileItem: View {
    let icon: String
    let label: String
    var value: String? = nil
    let type: ProfileItemType
    var isEnabled: Bool = false
    
    @State private var toggleState: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Theme.Colors.primaryLight)
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Theme.Colors.primary)
            }
            
            // Label and Value
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: Theme.FontSize.body, weight: .medium))
                    .foregroundColor(Theme.Colors.textPrimary)
                
                if type == .info, let value = value {
                    Text(value)
                        .font(.system(size: Theme.FontSize.caption))
                        .foregroundColor(Theme.Colors.textSecondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Right side content
            switch type {
            case .link:
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
            case .toggle:
                Toggle("", isOn: $toggleState)
                    .labelsHidden()
                    .tint(Theme.Colors.primary)
                    .onAppear { toggleState = isEnabled }
            case .info:
                EmptyView()
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(Theme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }
}

// MARK: - Audio Toggle Item

struct AudioToggleItem: View {
    @Binding var isEnabled: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Theme.Colors.primaryLight)
                    .frame(width: 40, height: 40)
                
                Image(systemName: isEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Theme.Colors.primary)
            }
            
            // Label and description
            VStack(alignment: .leading, spacing: 2) {
                Text("Audio Reminders")
                    .font(.system(size: Theme.FontSize.body, weight: .medium))
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Text(isEnabled ? "Speaks name and memory prompt" : "Audio disabled")
                    .font(.system(size: Theme.FontSize.caption))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .tint(Theme.Colors.primary)
                .onChange(of: isEnabled) { _, newValue in
                    onToggle(newValue)
                }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(Theme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }
}

// MARK: - Profile Action Button

struct ProfileActionButton: View {
    let icon: String
    let label: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                }
                
                // Labels
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: Theme.FontSize.body, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: Theme.FontSize.caption))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(Theme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Recognition History Item

struct RecognitionHistoryItem: View {
    let event: RecognitionEvent
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail or initials
            ZStack {
                Circle()
                    .fill(Theme.Colors.primaryLight)
                    .frame(width: 44, height: 44)
                
                if let thumbnailData = event.thumbnailData,
                   let uiImage = UIImage(data: thumbnailData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                } else {
                    Text(String(event.personName.prefix(2)).uppercased())
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.primary)
                }
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(event.personName)
                        .font(.system(size: Theme.FontSize.body, weight: .medium))
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    if event.wasOffline {
                        Text("OFFLINE")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.orange)
                            .cornerRadius(3)
                    }
                }
                
                Text("\(event.relationship) • \(event.timeAgo)")
                    .font(.system(size: Theme.FontSize.caption))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            
            Spacer()
            
            // Confidence
            Text("\(event.confidencePercent)%")
                .font(.system(size: Theme.FontSize.caption, weight: .medium))
                .foregroundColor(Theme.Colors.success)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(Theme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }
}

// MARK: - Full History View

struct RecognitionHistoryView: View {
    @ObservedObject var historyService: RecognitionHistoryService
    @Environment(\.dismiss) private var dismiss
    
    @State private var showClearConfirmation = false
    
    private var groupedEvents: [(String, [RecognitionEvent])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: historyService.events) { event -> String in
            if calendar.isDateInToday(event.timestamp) {
                return "Today"
            } else if calendar.isDateInYesterday(event.timestamp) {
                return "Yesterday"
            } else if calendar.isDate(event.timestamp, equalTo: Date(), toGranularity: .weekOfYear) {
                return "This Week"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                return formatter.string(from: event.timestamp)
            }
        }
        
        let order = ["Today", "Yesterday", "This Week"]
        return grouped.sorted { a, b in
            let aIndex = order.firstIndex(of: a.key) ?? Int.max
            let bIndex = order.firstIndex(of: b.key) ?? Int.max
            if aIndex != bIndex {
                return aIndex < bIndex
            }
            return a.key > b.key
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if historyService.events.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        Text("No Recognition History")
                            .font(.system(size: Theme.FontSize.h3, weight: .semibold))
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        Text("Your recent face recognitions will appear here")
                            .font(.system(size: Theme.FontSize.body))
                            .foregroundColor(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(32)
                } else {
                    List {
                        ForEach(groupedEvents, id: \.0) { section, events in
                            Section(header: Text(section)) {
                                ForEach(events) { event in
                                    RecognitionHistoryRow(event: event)
                                }
                            }
                        }
                        
                        // Summary section
                        Section(header: Text("Summary")) {
                            ForEach(historyService.getSummaries()) { summary in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(summary.personName)
                                            .font(.system(size: Theme.FontSize.body, weight: .medium))
                                        Text(summary.relationship)
                                            .font(.system(size: Theme.FontSize.caption))
                                            .foregroundColor(Theme.Colors.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("\(summary.totalRecognitions) times")
                                            .font(.system(size: Theme.FontSize.caption, weight: .medium))
                                            .foregroundColor(Theme.Colors.primary)
                                        Text("Last: \(summary.lastSeenAgo)")
                                            .font(.system(size: Theme.FontSize.caption))
                                            .foregroundColor(Theme.Colors.textSecondary)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Recognition History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                if !historyService.events.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showClearConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(Theme.Colors.danger)
                        }
                    }
                }
            }
            .alert("Clear History", isPresented: $showClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    historyService.clearHistory()
                }
            } message: {
                Text("Are you sure you want to clear all recognition history? This cannot be undone.")
            }
        }
    }
}

struct RecognitionHistoryRow: View {
    let event: RecognitionEvent
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            ZStack {
                Circle()
                    .fill(Theme.Colors.primaryLight)
                    .frame(width: 40, height: 40)
                
                if let thumbnailData = event.thumbnailData,
                   let uiImage = UIImage(data: thumbnailData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    Text(String(event.personName.prefix(2)).uppercased())
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.Colors.primary)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(event.personName)
                        .font(.system(size: Theme.FontSize.body, weight: .medium))
                    
                    if event.wasOffline {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                    }
                }
                
                Text(event.formattedDate)
                    .font(.system(size: Theme.FontSize.caption))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            
            Spacer()
            
            Text("\(event.confidencePercent)%")
                .font(.system(size: Theme.FontSize.caption, weight: .medium))
                .foregroundColor(event.wasOffline ? .orange : Theme.Colors.success)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Glasses Connection Item

struct GlassesConnectionItem: View {
    let registrationState: GlassesRegistrationState
    let isSDKConfigured: Bool
    let onTap: () -> Void
    let onConnect: () -> Void
    
    private var statusColor: Color {
        if !isSDKConfigured {
            return Theme.Colors.textSecondary
        }
        switch registrationState {
        case .registered:
            return Theme.Colors.success
        case .registering:
            return Theme.Colors.warning
        case .unregistered:
            return Theme.Colors.textSecondary
        }
    }
    
    private var statusText: String {
        if !isSDKConfigured {
            return "SDK not installed"
        }
        return registrationState.displayText
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Theme.Colors.primaryLight)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "eyeglasses")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.Colors.primary)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text("Meta Smart Glasses")
                        .font(.system(size: Theme.FontSize.body, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 6, height: 6)
                        
                        Text(statusText)
                            .font(.system(size: Theme.FontSize.caption))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Quick connect button or chevron
                if !registrationState.isConnected && isSDKConfigured {
                    Button {
                        onConnect()
                    } label: {
                        Text("Connect")
                            .font(.system(size: Theme.FontSize.caption, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Theme.Colors.primary)
                            .cornerRadius(14)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(Theme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(registrationState.isConnected ? Theme.Colors.success.opacity(0.3) : Theme.Colors.border, lineWidth: 1)
            )
        }
    }
}

// MARK: - Family Card

struct FamilyCard: View {
    let family: Family
    let memberCount: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Theme.Colors.primaryLight)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.Colors.primary)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(family.name)
                        .font(.system(size: Theme.FontSize.body, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Text("\(memberCount) member\(memberCount == 1 ? "" : "s")")
                        .font(.system(size: Theme.FontSize.caption))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                
                Spacer()
                
                // Invite code badge
                Text(family.inviteCode)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(Theme.Colors.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.Colors.primaryLight)
                    .cornerRadius(6)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(Theme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(Theme.Colors.primary.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

#Preview {
    ProfileView(store: AppStore.shared)
}

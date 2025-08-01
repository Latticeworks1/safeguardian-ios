import SwiftUI
import Foundation

// MARK: - Profile Manager
class ProfileManager: ObservableObject {
    @Published var userProfile: UserProfile
    
    private let userDefaults = UserDefaults.standard
    private let profileKey = "SafeGuardian.UserProfile"
    private let emergencyContactsKey = "SafeGuardian.EmergencyContacts"
    
    @Published var emergencyContacts: [EmergencyContact] = []
    
    init() {
        // Load saved profile or create default
        if let savedData = userDefaults.data(forKey: profileKey),
           let savedProfile = try? JSONDecoder().decode(UserProfile.self, from: savedData) {
            self.userProfile = savedProfile
        } else {
            // Create default profile with secure device ID
            let deviceID = Self.generateSecureDeviceID()
            self.userProfile = UserProfile(
                name: "User",
                avatar: "person.crop.circle.fill",
                deviceID: deviceID,
                isOnline: false,
                meshConnected: false,
                notificationsEnabled: true,
                darkModeEnabled: false,
                autoConnectMesh: true,
                shareLocation: false,
                showOnlineStatus: true
            )
            saveProfile()
        }
        
        // Load emergency contacts
        loadEmergencyContacts()
    }
    
    // MARK: - Data Persistence
    
    private func saveProfile() {
        do {
            let encodedData = try JSONEncoder().encode(userProfile)
            userDefaults.set(encodedData, forKey: profileKey)
        } catch {
            print("Failed to save profile: \(error)")
        }
    }
    
    private func loadEmergencyContacts() {
        if let savedData = userDefaults.data(forKey: emergencyContactsKey),
           let contacts = try? JSONDecoder().decode([EmergencyContact].self, from: savedData) {
            self.emergencyContacts = contacts
        } else {
            // Default emergency contacts for safety
            self.emergencyContacts = [
                EmergencyContact(name: "Emergency Services", phone: "911", relationship: "Emergency"),
                EmergencyContact(name: "Poison Control", phone: "1-800-222-1222", relationship: "Emergency")
            ]
            saveEmergencyContacts()
        }
    }
    
    private func saveEmergencyContacts() {
        do {
            let encodedData = try JSONEncoder().encode(emergencyContacts)
            userDefaults.set(encodedData, forKey: emergencyContactsKey)
        } catch {
            print("Failed to save emergency contacts: \(error)")
        }
    }
    
    // MARK: - Profile Management
    
    func updateProfile(name: String? = nil, avatar: String? = nil) {
        var needsSave = false
        
        if let name = name, isValidName(name) {
            userProfile.name = name
            needsSave = true
        }
        
        if let avatar = avatar {
            userProfile.avatar = avatar
            needsSave = true
        }
        
        if needsSave {
            saveProfile()
        }
    }
    
    func addEmergencyContact(_ contact: EmergencyContact) {
        emergencyContacts.append(contact)
        saveEmergencyContacts()
    }
    
    func removeEmergencyContact(at index: Int) {
        guard index < emergencyContacts.count else { return }
        emergencyContacts.remove(at: index)
        saveEmergencyContacts()
    }
    
    // MARK: - Settings Toggles
    
    func toggleNotifications() {
        userProfile.notificationsEnabled.toggle()
        saveProfile()
    }
    
    func toggleDarkMode(themeManager: ThemeManager) {
        userProfile.darkModeEnabled.toggle()
        themeManager.updateTheme(darkModeEnabled: userProfile.darkModeEnabled)
        saveProfile()
    }
    
    func toggleAutoConnectMesh() {
        userProfile.autoConnectMesh.toggle()
        saveProfile()
    }
    
    func toggleLocationSharing() {
        userProfile.shareLocation.toggle()
        saveProfile()
    }
    
    func toggleOnlineStatus() {
        userProfile.showOnlineStatus.toggle()
        saveProfile()
    }
    
    // MARK: - Data Validation
    
    private func isValidName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 1 && trimmed.count <= 50
    }
    
    private static func generateSecureDeviceID() -> String {
        let deviceID = UUID().uuidString.prefix(8).uppercased()
        return String(deviceID)
    }
    
    // MARK: - Security & Privacy
    
    func resetProfile() {
        userDefaults.removeObject(forKey: profileKey)
        userDefaults.removeObject(forKey: emergencyContactsKey)
        
        let deviceID = Self.generateSecureDeviceID()
        userProfile = UserProfile(
            name: "User",
            avatar: "person.crop.circle.fill",
            deviceID: deviceID,
            isOnline: false,
            meshConnected: false,
            notificationsEnabled: true,
            darkModeEnabled: false,
            autoConnectMesh: true,
            shareLocation: false,
            showOnlineStatus: true
        )
        
        emergencyContacts = [
            EmergencyContact(name: "Emergency Services", phone: "911", relationship: "Emergency"),
            EmergencyContact(name: "Poison Control", phone: "1-800-222-1222", relationship: "Emergency")
        ]
        
        saveProfile()
        saveEmergencyContacts()
    }
}

// MARK: - Profile Header View
struct ProfileHeaderView: View {
    let profile: UserProfile
    let onEditTap: () -> Void
    @State private var showingAvatarPicker = false
    
    private let availableAvatars = [
        "person.crop.circle.fill",
        "person.crop.circle.badge.checkmark",
        "person.crop.circle.badge.moon",
        "person.crop.circle.badge.shield",
        "figure.wave.circle.fill",
        "brain.head.profile.fill",
        "heart.circle.fill",
        "shield.lefthalf.filled",
        "star.circle.fill"
    ]
    
    init(profile: UserProfile, onEditTap: @escaping () -> Void = {}) {
        self.profile = profile
        self.onEditTap = onEditTap
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar and name section
            VStack(spacing: 12) {
                // Enhanced avatar with status indicators
                ZStack {
                    Image(systemName: profile.avatar)
                        .font(.system(size: 64))
                        .foregroundStyle(.blue.gradient)
                        .frame(width: 80, height: 80)
                        .background(.blue.opacity(0.1), in: Circle())
                        .overlay(
                            Circle()
                                .stroke(.blue.opacity(0.3), lineWidth: 2)
                        )
                    
                    // Status indicators
                    VStack {
                        HStack {
                            Spacer()
                            
                            // Online status badge
                            Circle()
                                .fill(profile.isOnline ? .green : .red)
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Circle()
                                        .stroke(.white, lineWidth: 2)
                                )
                                .shadow(radius: 2)
                        }
                        Spacer()
                    }
                    .frame(width: 80, height: 80)
                }
                .onTapGesture {
                    showingAvatarPicker = true
                }
                
                VStack(spacing: 4) {
                    Text(profile.name)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "iphone")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Text("Device ID: \(profile.deviceID)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fontDesign(.monospaced)
                    }
                    
                    // Connection status summary
                    HStack(spacing: 12) {
                        StatusBadge(
                            text: profile.isOnline ? "Online" : "Offline",
                            color: profile.isOnline ? .green : .red,
                            icon: profile.isOnline ? "wifi" : "wifi.slash"
                        )
                        
                        if profile.meshConnected {
                            StatusBadge(
                                text: "Mesh",
                                color: .blue,
                                icon: "antenna.radiowaves.left.and.right"
                            )
                        }
                    }
                    .padding(.top, 4)
                }
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: onEditTap) {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                            .font(.caption)
                        Text("Edit Profile")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.blue.opacity(0.1), in: Capsule())
                }
                .buttonStyle(ModernButtonStyle(color: .blue))
                
                Button(action: { showingAvatarPicker = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.crop.circle")
                            .font(.caption)
                        Text("Avatar")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.secondary.opacity(0.1), in: Capsule())
                }
                .buttonStyle(ModernButtonStyle(color: .blue))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .sheet(isPresented: $showingAvatarPicker) {
            AvatarPickerView(currentAvatar: profile.avatar, availableAvatars: availableAvatars) { selectedAvatar in
                // This would need to be handled by the parent view
            }
        }
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let text: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2.weight(.medium))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15), in: Capsule())
    }
}

// MARK: - Avatar Picker View
struct AvatarPickerView: View {
    let currentAvatar: String
    let availableAvatars: [String]
    let onSelection: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(availableAvatars, id: \.self) { avatar in
                        Button(action: {
                            onSelection(avatar)
                            dismiss()
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: avatar)
                                    .font(.system(size: 40))
                                    .foregroundStyle(.blue.gradient)
                                    .frame(width: 60, height: 60)
                                    .background(.blue.opacity(0.1), in: Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(currentAvatar == avatar ? .blue : .clear, lineWidth: 3)
                                    )
                                
                                if currentAvatar == avatar {
                                    Text("Current")
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .buttonStyle(ModernButtonStyle(color: .blue))
                    }
                }
                .padding(20)
            }
            .navigationTitle("Choose Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Connection Status Section
struct ConnectionStatusSection: View {
    let profile: UserProfile
    @State private var signalStrength: SignalStrength = .good
    @State private var peerCount: Int = 0
    @State private var lastSeen: Date = Date()
    
    var body: some View {
        VStack(spacing: 16) {
            // Section header
            HStack {
                Text("Connection Status")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                // Overall status indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(overallStatusColor)
                        .frame(width: 8, height: 8)
                        .scaleEffect(profile.isOnline || profile.meshConnected ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: profile.isOnline || profile.meshConnected)
                    
                    Text(overallStatusText)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(overallStatusColor)
                }
            }
            
            // Connection details grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                // Internet connection
                ConnectionCard(
                    title: "Internet",
                    status: profile.isOnline ? "Connected" : "Offline",
                    icon: profile.isOnline ? "wifi" : "wifi.slash",
                    color: profile.isOnline ? .green : .red,
                    details: profile.isOnline ? "High Speed" : "No Connection",
                    signalStrength: profile.isOnline ? signalStrength : nil
                )
                
                // Mesh network
                ConnectionCard(
                    title: "Mesh Network",
                    status: profile.meshConnected ? "Active" : "Searching",
                    icon: profile.meshConnected ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash",
                    color: profile.meshConnected ? .blue : .orange,
                    details: profile.meshConnected ? "\(peerCount) peer\(peerCount == 1 ? "" : "s")" : "No peers found",
                    signalStrength: profile.meshConnected ? signalStrength : nil
                )
            }
            
            // Safety notice
            if !profile.isOnline && !profile.meshConnected {
                SafetyNoticeCard()
            }
            
            // Last seen info
            if profile.isOnline || profile.meshConnected {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Text("Last active: \(RelativeDateTimeFormatter().localizedString(for: lastSeen, relativeTo: Date()))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onAppear {
            // Simulate dynamic values - in real app these would come from network manager
            peerCount = Int.random(in: 0...5)
            signalStrength = SignalStrength.allCases.randomElement() ?? .good
            lastSeen = Date().addingTimeInterval(-Double.random(in: 0...3600)) // Random time within last hour
        }
    }
    
    private var overallStatusColor: Color {
        if profile.isOnline { return .green }
        if profile.meshConnected { return .blue }
        return .red
    }
    
    private var overallStatusText: String {
        if profile.isOnline && profile.meshConnected { return "Fully Connected" }
        if profile.isOnline { return "Internet Only" }
        if profile.meshConnected { return "Mesh Only" }
        return "Disconnected"
    }
}

// MARK: - Connection Card
struct ConnectionCard: View {
    let title: String
    let status: String
    let icon: String
    let color: Color
    let details: String
    let signalStrength: SignalStrength?
    
    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(color)
                    .frame(width: 16)
                
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            // Status
            HStack {
                Text(status)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
                
                Spacer()
                
                if let strength = signalStrength {
                    SignalStrengthIndicator(strength: strength)
                }
            }
            
            // Details
            HStack {
                Text(details)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(color.opacity(0.2), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Signal Strength Indicator
struct SignalStrengthIndicator: View {
    let strength: SignalStrength
    
    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<4) { index in
                Rectangle()
                    .fill(barColor(for: index))
                    .frame(width: 2, height: CGFloat(4 + index * 2))
                    .cornerRadius(0.5)
            }
        }
    }
    
    private func barColor(for index: Int) -> Color {
        let filledBars = strengthToBars(strength)
        return index < filledBars ? strength.color : Color.secondary.opacity(0.3)
    }
    
    private func strengthToBars(_ strength: SignalStrength) -> Int {
        switch strength {
        case .strong: return 4
        case .good: return 3
        case .weak: return 1
        }
    }
}

// MARK: - Safety Notice Card
struct SafetyNoticeCard: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.subheadline)
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Limited Connectivity")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                
                Text("If you need emergency help, dial 911 directly")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.orange.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.orange.opacity(0.2), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let content: Content
    let style: SectionStyle
    
    enum SectionStyle {
        case standard, safety, privacy, emergency
        
        var headerColor: Color {
            switch self {
            case .standard: return .primary
            case .safety: return .green
            case .privacy: return .blue
            case .emergency: return .red
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .standard: return Color(.systemBackground)
            case .safety: return .green.opacity(0.02)
            case .privacy: return .blue.opacity(0.02)
            case .emergency: return .red.opacity(0.02)
            }
        }
        
        var borderColor: Color {
            switch self {
            case .standard: return Color(.separator)
            case .safety: return .green.opacity(0.15)
            case .privacy: return .blue.opacity(0.15)
            case .emergency: return .red.opacity(0.15)
            }
        }
    }
    
    init(title: String, subtitle: String? = nil, icon: String? = nil, style: SectionStyle = .standard, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.style = style
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Section header
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundStyle(style.headerColor)
                        .frame(width: 16)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(style.headerColor)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // Settings content
            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(style.backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(style.borderColor, lineWidth: 0.5)
                    )
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Settings section: \(title)")
    }
}

// MARK: - Setting Row
struct SettingRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let value: String
    let style: RowStyle
    let controlType: ControlType
    let action: () -> Void
    
    enum RowStyle {
        case standard, warning, emergency, privacy, safety
        
        var iconColor: Color {
            switch self {
            case .standard: return .blue
            case .warning: return .orange
            case .emergency: return .red
            case .privacy: return .indigo
            case .safety: return .green
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .standard: return .clear
            case .warning: return .orange.opacity(0.05)
            case .emergency: return .red.opacity(0.05)
            case .privacy: return .indigo.opacity(0.05)
            case .safety: return .green.opacity(0.05)
            }
        }
    }
    
    enum ControlType {
        case toggle, navigation, action, display
        
        var chevronIcon: String? {
            switch self {
            case .navigation: return "chevron.right"
            case .action: return "arrow.up.right"
            case .toggle, .display: return nil
            }
        }
    }
    
    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        value: String,
        style: RowStyle = .standard,
        controlType: ControlType = .navigation,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.style = style
        self.controlType = controlType
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(style.iconColor)
                    .frame(width: 20)
                
                // Title and subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                // Value and controls
                HStack(spacing: 8) {
                    if !value.isEmpty {
                        Group {
                            if controlType == .toggle {
                                ToggleIndicator(isOn: value == "On")
                            } else {
                                Text(value)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    
                    if let chevron = controlType.chevronIcon {
                        Image(systemName: chevron)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, controlType == .display ? 8 : 12)
            .background(style.backgroundColor, in: Rectangle())
        }
        .buttonStyle(ModernButtonStyle(color: .blue))
        .disabled(controlType == .display)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(controlType == .toggle ? .isButton : .isButton)
    }
    
    private var accessibilityLabel: String {
        var label = title
        if let subtitle = subtitle {
            label += ", " + subtitle
        }
        if !value.isEmpty {
            label += ", current value: " + value
        }
        return label
    }
    
    private var accessibilityHint: String {
        switch controlType {
        case .toggle: return "Double tap to toggle"
        case .navigation: return "Double tap to open"
        case .action: return "Double tap to perform action"
        case .display: return "Information only"
        }
    }
}

// MARK: - Toggle Indicator
struct ToggleIndicator: View {
    let isOn: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isOn ? .green : .secondary.opacity(0.3))
            .frame(width: 40, height: 24)
            .overlay(
                Circle()
                    .fill(.white)
                    .frame(width: 20, height: 20)
                    .offset(x: isOn ? 8 : -8)
                    .shadow(radius: 1)
            )
            .animation(.easeInOut(duration: 0.2), value: isOn)
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @Binding var profile: UserProfile
    @Environment(\.dismiss) private var dismiss
    @State private var editedName: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Avatar section
                VStack(spacing: 16) {
                    Image(systemName: profile.avatar)
                        .font(.system(size: 64))
                        .foregroundStyle(.blue.gradient)
                        .frame(width: 80, height: 80)
                        .background(.blue.opacity(0.1), in: Circle())
                    
                    Button("Change Avatar") {}
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
                
                // Name field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Display Name")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    
                    TextField("Enter your name", text: $editedName)
                        .textFieldStyle(.roundedBorder)
                }
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        profile.name = editedName.isEmpty ? "User" : editedName
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                editedName = profile.name
            }
        }
    }
}

#Preview {
    VStack {
        ProfileHeaderView(profile: UserProfile(
            nickname: "John Doe",
            isEmergencyContact: false
        ))
        
        SettingRow(icon: "bell.fill", title: "Notifications", value: "On", action: {})
    }
    .padding()
}
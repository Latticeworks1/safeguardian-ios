import SwiftUI

struct ProfileView: View {
    @StateObject private var profileManager = ProfileManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var meshManager = SafeGuardianMeshManager()
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header with Connection Status
                    ProfileHeaderView(
                        profile: profileManager.userProfile,
                        onEditTap: { showingEditProfile = true }
                    )
                    
                    // Enhanced Connection Status Section with BitChat Integration
                    ConnectionStatusSectionWithMesh(
                        profile: profileManager.userProfile,
                        meshManager: meshManager
                    )
                    
                    // Advanced Mesh Network Configuration
                    MeshNetworkConfigurationSection(
                        profileManager: profileManager,
                        meshManager: meshManager
                    )
                    
                    // Enhanced Emergency Contacts with Mesh Integration
                    EnhancedEmergencyContactsSection(
                        profileManager: profileManager
                    )
                    
                    // Safety Preferences Categories
                    SafetyPreferencesSection(
                        profileManager: profileManager
                    )
                    
                    // Privacy & Security Settings
                    SettingsSection(
                        title: "Privacy & Security",
                        subtitle: "Control your privacy and mesh network data",
                        icon: "lock.shield.fill",
                        style: .privacy
                    ) {
                        SettingRow(
                            icon: "eye.circle",
                            title: "Show Online Status",
                            subtitle: "Let others see when you're active on mesh network",
                            value: profileManager.userProfile.showOnlineStatus ? "On" : "Off",
                            style: .privacy,
                            controlType: .toggle,
                            action: { profileManager.toggleOnlineStatus() }
                        )
                        
                        SettingRow(
                            icon: "person.crop.circle.badge.questionmark",
                            title: "Peer Discovery",
                            subtitle: "Allow other devices to discover yours",
                            value: profileManager.userProfile.allowPeerDiscovery ? "On" : "Off",
                            style: .privacy,
                            controlType: .toggle,
                            action: { profileManager.togglePeerDiscovery() }
                        )
                        
                        SettingRow(
                            icon: "location.circle.fill",
                            title: "Location Sharing",
                            subtitle: "Share location with emergency contacts and mesh network",
                            value: profileManager.userProfile.shareLocation ? "On" : "Off",
                            style: .privacy,
                            controlType: .toggle,
                            action: { profileManager.toggleLocationSharing() }
                        )
                        
                        SettingRow(
                            icon: "moon.fill",
                            title: "Dark Mode",
                            value: profileManager.userProfile.darkModeEnabled ? "On" : "Off",  
                            style: .privacy,
                            controlType: .toggle,
                            action: { profileManager.toggleDarkMode(themeManager: themeManager) }
                        )
                    }
                    
                    // Basic Safety Settings (for quick access)
                    SettingsSection(
                        title: "Basic Safety Settings",
                        subtitle: "Quick access to essential safety features",
                        icon: "shield.checkered",
                        style: .safety
                    ) {
                        SettingRow(
                            icon: "bell.fill",
                            title: "Safety Notifications",
                            subtitle: "Get alerted about nearby incidents",
                            value: profileManager.userProfile.notificationsEnabled ? "On" : "Off",
                            style: .safety,
                            controlType: .toggle,
                            action: { profileManager.toggleNotifications() }
                        )
                        
                        SettingRow(
                            icon: "antenna.radiowaves.left.and.right",
                            title: "Auto-Connect Mesh",
                            subtitle: "Automatically connect to nearby SafeGuardian users",
                            value: profileManager.userProfile.autoConnectMesh ? "On" : "Off",
                            style: .safety,
                            controlType: .toggle,
                            action: { profileManager.toggleAutoConnectMesh() }
                        )
                        
                        SettingRow(
                            icon: "exclamationmark.triangle.fill",
                            title: "Emergency Broadcast",
                            subtitle: "Enable priority emergency messaging across mesh network",
                            value: profileManager.userProfile.emergencyBroadcastEnabled ? "On" : "Off",
                            style: .emergency,
                            controlType: .toggle,
                            action: { profileManager.toggleEmergencyBroadcast() }
                        )
                    }
                    
                    // Settings Backup and Restore
                    SettingsBackupSection(
                        profileManager: profileManager
                    )
                }
                .padding(.vertical)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(profile: $profileManager.userProfile)
        }
    }
}

// MARK: - Connection Status with BitChat Integration
struct ConnectionStatusSectionWithMesh: View {
    let profile: UserProfile
    @ObservedObject var meshManager: SafeGuardianMeshManager
    @State private var signalStrength: SignalStrength = .good
    @State private var lastSeen: Date = Date()
    
    var body: some View {
        VStack(spacing: 16) {
            // Section header
            HStack {
                Text("Network Status")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                // Overall status indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(overallStatusColor)
                        .frame(width: 8, height: 8)
                        .scaleEffect(meshManager.isConnected ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: meshManager.isConnected)
                    
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
                
                // Mesh network with real BitChat data
                ConnectionCard(
                    title: "Mesh Network",
                    status: meshManager.isConnected ? "Active" : "Searching",
                    icon: meshManager.isConnected ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash",
                    color: meshManager.isConnected ? .blue : .orange,
                    details: meshManager.isConnected ? "\(meshManager.connectedPeers.count) peer\(meshManager.connectedPeers.count == 1 ? "" : "s")" : "No peers found",
                    signalStrength: meshManager.isConnected ? signalStrength : nil
                )
            }
            
            // Safety notice
            if !profile.isOnline && !meshManager.isConnected {
                SafetyNoticeCard()
            }
            
            // Last seen info
            if profile.isOnline || meshManager.isConnected {
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
            signalStrength = SignalStrength.allCases.randomElement() ?? .good
            lastSeen = Date().addingTimeInterval(-Double.random(in: 0...3600)) // Random time within last hour
        }
    }
    
    private var overallStatusColor: Color {
        if profile.isOnline { return .green }
        if meshManager.isConnected { return .blue }
        return .red
    }
    
    private var overallStatusText: String {
        if profile.isOnline && meshManager.isConnected { return "Fully Connected" }
        if profile.isOnline { return "Internet Only" }
        if meshManager.isConnected { return "Mesh Only" }
        return "Disconnected"
    }
}

#Preview {
    ProfileView()
}
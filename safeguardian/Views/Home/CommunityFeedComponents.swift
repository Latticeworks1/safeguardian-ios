import SwiftUI
import Network

// MARK: - Safety Status Enum
enum SafetyStatus: CaseIterable {
    case safe, caution, alert, emergency, disconnected
    
    var color: Color {
        switch self {
        case .safe: return .green
        case .caution: return .yellow
        case .alert: return .orange
        case .emergency: return .red
        case .disconnected: return .secondary
        }
    }
    
    var icon: String {
        switch self {
        case .safe: return "shield.checkered"
        case .caution: return "exclamationmark.triangle"
        case .alert: return "exclamationmark.triangle.fill"
        case .emergency: return "exclamationmark.octagon.fill"
        case .disconnected: return "wifi.slash"
        }
    }
}

// MARK: - Local Social Feed Section (Nextdoor-style)
struct LocalCommunityFeedSection: View {
    @ObservedObject private var feedManager = LocalSocialFeedManager.shared
    @State private var showingNewPost = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Quick Post Section
            QuickPostSection(showingNewPost: $showingNewPost)
            
            // Local Social Feed
            LocalSocialFeed()
        }
        .sheet(isPresented: $showingNewPost) {
            NewPostView()
        }
    }
}

// MARK: - Empty Feed View
struct EmptyFeedView: View {
    var body: some View {
        VStack(spacing: 20) {
            SafetyIndicator(
                status: .disconnected,
                size: .large
            )
            
            VStack(spacing: 8) {
                Text("Stay Connected, Stay Safe")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                
                Text("Connect with your neighborhood network to receive safety updates, emergency alerts, and community information")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                ActionCard(
                    icon: "wifi",
                    title: "Connect Online",
                    subtitle: "Join internet community",
                    color: .blue,
                    size: .wide,
                    action: { /* Connect online action */ }
                )
                
                ActionCard(
                    icon: "antenna.radiowaves.left.and.right",
                    title: "Join Mesh Network",
                    subtitle: "Connect locally",
                    color: .orange,
                    size: .wide,
                    action: { /* Join mesh action */ }
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(.separator).opacity(0.5), lineWidth: 1)
                )
        )
    }
}

// MARK: - Safety Indicator Component
struct SafetyIndicator: View {
    let status: SafetyStatus
    let size: IndicatorSize
    @State private var isAnimating = false
    
    enum IndicatorSize {
        case small, medium, large
        
        var diameter: CGFloat {
            switch self {
            case .small: return 24
            case .medium: return 36
            case .large: return 48
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 18
            case .large: return 24
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Outer breathing circle
            Circle()
                .fill(status.color.opacity(0.2))
                .frame(width: size.diameter * (isAnimating ? 1.4 : 1.2), height: size.diameter * (isAnimating ? 1.4 : 1.2))
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
            
            // Middle pulse circle
            Circle()
                .fill(status.color.opacity(0.4))
                .frame(width: size.diameter * (isAnimating ? 1.2 : 1.0), height: size.diameter * (isAnimating ? 1.2 : 1.0))
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
            
            // Inner solid circle
            Circle()
                .fill(status.color)
                .frame(width: size.diameter, height: size.diameter)
            
            // Status icon
            Image(systemName: status.icon)
                .font(.system(size: size.iconSize, weight: .medium))
                .foregroundStyle(.white)
        }
        .onAppear {
            isAnimating = true
        }
        .accessibilityLabel("Safety status: \(status)")
    }
}

// MARK: - Action Card Component
struct ActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let size: CardSize
    let action: () -> Void
    
    enum CardSize {
        case small, large, wide
        
        var width: CGFloat? {
            switch self {
            case .small: return 120
            case .large: return 160
            case .wide: return nil // Full width
            }
        }
        
        var height: CGFloat {
            switch self {
            case .small: return 80
            case .large: return 100
            case .wide: return 60
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: size == .wide ? 12 : 8) {
                Image(systemName: icon)
                    .font(.system(size: size == .small ? 16 : 20, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: size == .small ? 32 : 40, height: size == .small ? 32 : 40)
                    .background(
                        Circle()
                            .fill(color.opacity(0.2))
                    )
                
                if size != .small {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: size == .wide ? 16 : 14, weight: .semibold))
                            .foregroundStyle(.white)
                        
                        Text(subtitle)
                            .font(.system(size: size == .wide ? 12 : 11))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                if size == .wide {
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .frame(width: size.width, height: size.height)
            .frame(maxWidth: size == .wide ? .infinity : size.width)
            .padding(.horizontal, size == .small ? 8 : 16)
            .padding(.vertical, size == .small ? 8 : 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(color.gradient)
            )
        }
        .buttonStyle(ModernButtonStyle(color: color))
        .accessibilityLabel("\(title): \(subtitle)")
    }
}

// MARK: - Safety Status Header
struct SafetyStatusHeader: View {
    @StateObject private var safetyStatus = SafetyStatusManager()
    
    var body: some View {
        HStack(spacing: 16) {
            SafetyIndicator(
                status: safetyStatus.currentStatus,
                size: .large
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(safetyStatus.statusMessage)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                
                Text(safetyStatus.statusDetail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Community Actions Section  
struct CommunityActionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Community Actions")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ActionCard(
                        icon: "shield.checkered",
                        title: "Safety Check",
                        subtitle: "Check-in with community",
                        color: .green,
                        size: .large,
                        action: { /* Safety check-in action */ }
                    )
                    
                    ActionCard(
                        icon: "location.fill",
                        title: "Share Location",
                        subtitle: "Send to contacts",
                        color: .blue,
                        size: .large,
                        action: { /* Share location action */ }
                    )
                    
                    ActionCard(
                        icon: "person.2.wave.2.fill", 
                        title: "Find Neighbors",
                        subtitle: "Connect with community",
                        color: .orange,
                        size: .large,
                        action: { /* Find neighbors action */ }
                    )
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Connected Community View
struct ConnectedCommunityView: View {
    @StateObject private var communityData = CommunityDataManager()
    
    var body: some View {
        VStack(spacing: 16) {
            // Connection Status Card
            ConnectionStatusCard()
            
            // Recent Community Activity
            if !communityData.recentActivities.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Activity")
                        .font(.headline.weight(.medium))
                        .foregroundStyle(.primary)
                    
                    ForEach(communityData.recentActivities.prefix(3)) { activity in
                        CommunityActivityRow(activity: activity)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.background)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color(.separator).opacity(0.5), lineWidth: 1)
                        )
                )
            }
        }
    }
}

// MARK: - Connection Status Card
struct ConnectionStatusCard: View {
    @StateObject private var connectionManager = ConnectionStatusManager()
    
    var body: some View {
        HStack(spacing: 12) {
            SafetyIndicator(
                status: connectionManager.connectionStatus,
                size: .medium
            )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(connectionManager.statusTitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                
                Text(connectionManager.deviceCount)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button("Settings") {
                // Connection settings action
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(.separator).opacity(0.5), lineWidth: 1)
                )
        )
    }
}

// MARK: - Community Activity Row
struct CommunityActivityRow: View {
    let activity: CommunityActivity
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.icon)
                .font(.subheadline)
                .foregroundStyle(activity.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.message)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                Text(activity.timeAgo)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Supporting Models and Managers

// MARK: - Community Feed Manager
class CommunityFeedManager: ObservableObject {
    @Published var isConnected: Bool = false
    @Published var connectionType: ConnectionType = .offline
    
    enum ConnectionType {
        case offline, online, mesh, hybrid
        
        var description: String {
            switch self {
            case .offline: return "Offline"
            case .online: return "Online"
            case .mesh: return "Mesh Network"
            case .hybrid: return "Online + Mesh"
            }
        }
    }
}

// MARK: - Safety Status Manager
class SafetyStatusManager: ObservableObject {
    @Published var currentStatus: SafetyStatus = .safe
    
    var statusMessage: String {
        switch currentStatus {
        case .safe: return "Area Status: Safe"
        case .caution: return "Area Status: Caution"
        case .alert: return "Safety Alert Active"
        case .emergency: return "Emergency Situation"
        case .disconnected: return "Status Unknown"
        }
    }
    
    var statusDetail: String {
        switch currentStatus {
        case .safe: return "No reported incidents in your area"
        case .caution: return "Stay aware of your surroundings"
        case .alert: return "Check recent safety updates"
        case .emergency: return "Seek immediate safety"
        case .disconnected: return "Connect to receive updates"
        }
    }
}

// MARK: - Connection Status Manager
class ConnectionStatusManager: ObservableObject {
    @Published var connectionStatus: SafetyStatus = .disconnected
    @Published var connectedDevices: Int = 0
    
    var statusTitle: String {
        switch connectionStatus {
        case .safe: return "Network Connected"
        case .caution: return "Limited Connection"
        case .alert: return "Connection Issues"
        case .emergency: return "Emergency Mode"
        case .disconnected: return "Not Connected"
        }
    }
    
    var deviceCount: String {
        if connectedDevices == 0 {
            return "No nearby devices"
        } else {
            return "\(connectedDevices) device\(connectedDevices == 1 ? "" : "s") nearby"
        }
    }
}

// MARK: - Community Data Manager
class CommunityDataManager: ObservableObject {
    @Published var recentActivities: [CommunityActivity] = [
        CommunityActivity(
            id: "1",
            message: "Safety check-in from 3 neighbors",
            icon: "checkmark.shield",
            color: .green,
            timestamp: Date().addingTimeInterval(-300)
        ),
        CommunityActivity(
            id: "2",
            message: "Community watch patrol active",
            icon: "eye",
            color: .blue,
            timestamp: Date().addingTimeInterval(-1200)
        ),
        CommunityActivity(
            id: "3",
            message: "Emergency services notified of incident",
            icon: "exclamationmark.triangle",
            color: .orange,
            timestamp: Date().addingTimeInterval(-3600)
        )
    ]
}

// MARK: - Community Activity Model
struct CommunityActivity: Identifiable {
    let id: String
    let message: String
    let icon: String
    let color: Color
    let timestamp: Date
    
    var timeAgo: String {
        let interval = Date().timeIntervalSince(timestamp)
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

// MARK: - Nextdoor-Style Components

// MARK: - Neighborhood Header
struct NeighborhoodHeader: View {
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Your Neighborhood")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 5) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                        
                        Text("Your Location")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                }
                
                Spacer()
                
                SafetyIndicator(status: .safe, size: .small)
            }
            
            HStack(spacing: 16) {
                NeighborhoodStat(
                    title: "Active", 
                    value: "--", 
                    icon: "person.2.fill", 
                    color: .secondary
                )
                
                NeighborhoodStat(
                    title: "This Week", 
                    value: "--", 
                    icon: "exclamationmark.shield.fill", 
                    color: .secondary
                )
                
                NeighborhoodStat(
                    title: "Resolved", 
                    value: "--", 
                    icon: "checkmark.shield.fill", 
                    color: .secondary
                )
                
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 0))
    }
}

struct NeighborhoodStat: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                    .frame(width: 12, height: 12)
                
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
        }
        .frame(minWidth: 50)
    }
}

// MARK: - Quick Post Section
struct QuickPostSection: View {
    @Binding var showingNewPost: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Quick action buttons moved above
            HStack(spacing: 6) {
                CompactActionButton(
                    icon: "exclamationmark.triangle.fill",
                    title: "Alert",
                    color: .orange,
                    action: { showingNewPost = true }
                )
                
                CompactActionButton(
                    icon: "heart.fill",
                    title: "Recommend",
                    color: .pink,
                    action: { showingNewPost = true }
                )
                
                CompactActionButton(
                    icon: "questionmark.bubble.fill",
                    title: "Ask",
                    color: .blue,
                    action: { showingNewPost = true }
                )
                
                Spacer()
            }
            
            // Main post entry
            HStack(spacing: 12) {
                Circle()
                    .fill(.blue.gradient)
                    .frame(width: 36, height: 36)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                    }
                
                Button(action: { showingNewPost = true }) {
                    HStack(spacing: 10) {
                        Text("What's happening in your neighborhood?")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        Spacer(minLength: 6)
                        
                        Image(systemName: "photo")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(.quaternary.opacity(0.6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.regularMaterial)
        .overlay(
            Rectangle()
                .fill(Color(.separator).opacity(0.4))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
}

// MARK: - Compact Action Button (for main feed)
struct CompactActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.tertiary.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(color.opacity(0.3), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Original Quick Action Button (kept for other uses if needed)
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(color)
                    .frame(height: 16)
                
                Text(title)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8) 
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.tertiary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Local Social Feed  
struct LocalSocialFeed: View {
    @ObservedObject private var feedManager = LocalSocialFeedManager.shared
    
    var body: some View {
        Group {
            if feedManager.isLoading {
                LoadingFeedView()
            } else if feedManager.posts.isEmpty {
                EnhancedEmptyFeedView()
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(feedManager.posts) { post in
                        SocialPostCard(post: post)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                    }
                }
            }
        }
        .refreshable {
            feedManager.refreshPosts()
        }
    }
}

// MARK: - Loading Feed View
struct LoadingFeedView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading community posts...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Enhanced Empty Feed View  
struct EnhancedEmptyFeedView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    
    private var isCompact: Bool {
        sizeClass == .compact
    }
    
    var body: some View {
        VStack(spacing: isCompact ? 20 : 28) {
            VStack(spacing: isCompact ? 12 : 18) {
                Image(systemName: "house.and.flag.fill")
                    .font(.system(size: isCompact ? 42 : 52, weight: .light))
                    .foregroundStyle(.blue.opacity(0.7))
                    .symbolEffect(.pulse.byLayer, options: .repeating.speed(0.5))
                
                VStack(spacing: isCompact ? 6 : 10) {
                    Text("Welcome to Your Neighborhood")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text("Be the first to share what's happening in your community")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            VStack(spacing: 16) {
                Text("Get Started")
                    .font(.headline.weight(.medium))
                    .foregroundStyle(.primary)
                
                VStack(spacing: 14) {
                    FeatureTip(
                        icon: "exclamationmark.triangle.fill",
                        title: "Share Safety Updates",
                        description: "Keep neighbors informed about local safety concerns and incidents",
                        color: .orange
                    )
                    
                    FeatureTip(
                        icon: "heart.fill", 
                        title: "Recommend Places",
                        description: "Help neighbors discover great local businesses and services",
                        color: .pink
                    )
                    
                    FeatureTip(
                        icon: "calendar",
                        title: "Organize Events", 
                        description: "Bring neighbors together for community meetings and activities",
                        color: .purple
                    )
                }
            }
        }
        .padding(.horizontal, isCompact ? 24 : 40)
        .padding(.vertical, isCompact ? 32 : 44)
        .frame(maxWidth: .infinity)
    }
}

struct FeatureTip: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon container with consistent sizing
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(color)
            }
            .frame(width: 36, height: 36) // Fixed size for alignment
            
            // Text content with better spacing
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Social Post Card
struct SocialPostCard: View {
    let post: SocialPost
    @State private var isLiked = false
    @State private var showingComments = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(post.author.profileColor)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text(post.author.initials)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .opacity(post.isQueued ? 0.7 : 1.0)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(post.author.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .opacity(post.isQueued ? 0.7 : 1.0)
                        
                        if post.author.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                                .opacity(post.isQueued ? 0.7 : 1.0)
                        }
                        
                        // Queued indicator
                        if post.isQueued {
                            HStack(spacing: 3) {
                                Image(systemName: "clock.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                                
                                Text("QUEUED")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.orange)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(.orange.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .stroke(.orange.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                    }
                    
                    HStack(spacing: 4) {
                        Text(post.location)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .opacity(post.isQueued ? 0.7 : 1.0)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .opacity(post.isQueued ? 0.7 : 1.0)
                        
                        if let queueStatus = post.queueStatus {
                            Text(queueStatus)
                                .font(.caption)
                                .foregroundStyle(.orange)
                        } else {
                            Text(post.timeAgo)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .opacity(post.isQueued ? 0.7 : 1.0)
                        }
                    }
                }
                
                Spacer()
                
                PostCategoryBadge(category: post.category)
                    .opacity(post.isQueued ? 0.7 : 1.0)
            }
            
            Text(post.content)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .opacity(post.isQueued ? 0.7 : 1.0)
                .lineLimit(nil)
            
            // Queued post info banner
            if post.isQueued {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Post will be published when connected")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.orange)
                        
                        Text("Your post is saved and will appear in the community feed once you're back online")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(.orange.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            
            if let imageName = post.imageName {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.tertiary)
                    .frame(height: 200)
                    .opacity(post.isQueued ? 0.7 : 1.0)
                    .overlay {
                        Image(systemName: imageName)
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                            .opacity(post.isQueued ? 0.7 : 1.0)
                    }
            }
            
            if post.likes > 0 || post.comments > 0 {
                HStack(spacing: 16) {
                    if post.likes > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.caption2)
                                .foregroundStyle(.pink)
                                .opacity(post.isQueued ? 0.7 : 1.0)
                            
                            Text("\(post.likes)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .opacity(post.isQueued ? 0.7 : 1.0)
                        }
                    }
                    
                    if post.comments > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.fill")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                                .opacity(post.isQueued ? 0.7 : 1.0)
                            
                            Text("\(post.comments)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .opacity(post.isQueued ? 0.7 : 1.0)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
            
            HStack(spacing: 32) {
                Button(action: { 
                    if !post.isQueued { 
                        isLiked.toggle() 
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(isLiked ? .pink : .secondary)
                            .opacity(post.isQueued ? 0.5 : 1.0)
                        
                        Text("Like")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                            .opacity(post.isQueued ? 0.5 : 1.0)
                    }
                }
                .buttonStyle(.plain)
                .disabled(post.isQueued)
                
                Button(action: { 
                    if !post.isQueued {
                        showingComments.toggle() 
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.secondary)
                            .opacity(post.isQueued ? 0.5 : 1.0)
                        
                        Text("Comment")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                            .opacity(post.isQueued ? 0.5 : 1.0)
                    }
                }
                .buttonStyle(.plain)
                .disabled(post.isQueued)
                
                Button(action: {}) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.secondary)
                            .opacity(post.isQueued ? 0.5 : 1.0)
                        
                        Text("Share")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                            .opacity(post.isQueued ? 0.5 : 1.0)
                    }
                }
                .buttonStyle(.plain)
                .disabled(post.isQueued)
                
                Spacer()
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(post.isQueued ? .orange.opacity(0.3) : Color(.separator), lineWidth: post.isQueued ? 1.5 : 0.5)
        )
        .opacity(post.isQueued ? 0.9 : 1.0)
    }
}

struct PostCategoryBadge: View {
    let category: PostCategory
    
    var body: some View {
        Text(category.displayName)
            .font(.caption2.weight(.medium))
            .foregroundStyle(category.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(category.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - New Post View  
struct NewPostView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var postText = ""
    @State private var selectedCategory: PostCategory = .general
    @State private var isPosting = false
    @State private var showingOfflineAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Offline status indicator
                if !LocalSocialFeedManager.shared.isOnline {
                    HStack(spacing: 8) {
                        Image(systemName: "wifi.slash")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        
                        Text("Offline - Posts will be queued until connected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(.orange.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(.orange.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                
                // Compact category selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("What type of post?")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(PostCategory.allCases, id: \.self) { category in
                                CompactCategoryButton(
                                    category: category,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("What's on your mind?")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    
                    TextEditor(text: $postText)
                        .font(.subheadline)
                        .frame(minHeight: 140)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.quaternary.opacity(0.6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
                                )
                        )
                }
                
                Spacer()
            }
            .padding(16)
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { 
                        dismiss() 
                    }
                    .disabled(isPosting)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: handlePost) {
                        if isPosting {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Posting...")
                            }
                        } else {
                            Text(LocalSocialFeedManager.shared.isOnline ? "Post" : "Queue Post")
                        }
                    }
                    .disabled(postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isPosting)
                }
            }
        }
        .alert("Post Queued", isPresented: $showingOfflineAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your post has been queued and will be published when you're back online.")
        }
    }
    
    private func handlePost() {
        let trimmedText = postText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        isPosting = true
        
        // Create the post
        let newPost = SocialPost(
            author: Author(name: "You", isVerified: false),
            content: trimmedText,
            category: selectedCategory,
            location: "Your Location",
            timestamp: Date(),
            likes: 0,
            comments: 0,
            imageName: nil
        )
        
        // Simulate posting attempt
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isPosting = false
            
            if LocalSocialFeedManager.shared.isOnline {
                // Online: Post immediately
                LocalSocialFeedManager.shared.publishPost(newPost)
                dismiss()
            } else {
                // Offline: Queue the post
                LocalSocialFeedManager.shared.queuePost(newPost)
                showingOfflineAlert = true
            }
        }
    }
}

// MARK: - Compact Category Button
struct CompactCategoryButton: View {
    let category: PostCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isSelected ? category.color : .secondary)
                
                Text(category.displayName)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? category.color.opacity(0.15) : Color(.quaternarySystemFill))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isSelected ? category.color.opacity(0.5) : Color(.separator).opacity(0.3), lineWidth: isSelected ? 1.5 : 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Original Category Selection Card (kept for compatibility)
struct CategorySelectionCard: View {
    let category: PostCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(isSelected ? category.color : .secondary)
                
                Text(category.displayName)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? category.color.opacity(0.1) : Color(.quaternarySystemFill))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? category.color : .clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Data Models

struct SocialPost: Identifiable {
    let id = UUID()
    let author: Author
    let content: String
    let category: PostCategory
    let location: String
    let timestamp: Date
    let likes: Int
    let comments: Int
    let imageName: String?
    var isQueued: Bool = false
    var queuedAt: Date? = nil
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    var queueStatus: String? {
        guard isQueued, let queuedAt = queuedAt else { return nil }
        let interval = Date().timeIntervalSince(queuedAt)
        
        if interval < 60 {
            return "Queued just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "Queued \(minutes)m ago"
        } else {
            let hours = Int(interval / 3600)
            return "Queued \(hours)h ago"
        }
    }
}

struct Author {
    let name: String
    let initials: String
    let profileColor: Color
    let isVerified: Bool
    
    init(name: String, isVerified: Bool = false) {
        self.name = name
        self.isVerified = isVerified
        self.initials = String(name.split(separator: " ").compactMap { $0.first }).uppercased()
        self.profileColor = [.blue, .green, .orange, .purple, .pink, .teal].randomElement() ?? .blue
    }
}

enum PostCategory: CaseIterable {
    case safetyAlert
    case recommendation
    case question
    case event
    case lostFound
    case general
    
    var displayName: String {
        switch self {
        case .safetyAlert: return "Safety Alert"
        case .recommendation: return "Recommendation"
        case .question: return "Question"
        case .event: return "Event"
        case .lostFound: return "Lost & Found"
        case .general: return "General"
        }
    }
    
    var icon: String {
        switch self {
        case .safetyAlert: return "exclamationmark.triangle.fill"
        case .recommendation: return "heart.fill"
        case .question: return "questionmark.bubble.fill"
        case .event: return "calendar"
        case .lostFound: return "magnifyingglass"
        case .general: return "bubble.left.and.bubble.right.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .safetyAlert: return .orange
        case .recommendation: return .pink
        case .question: return .blue
        case .event: return .purple
        case .lostFound: return .green
        case .general: return .secondary
        }
    }
}

class LocalSocialFeedManager: ObservableObject {
    static let shared = LocalSocialFeedManager()
    
    @Published var posts: [SocialPost] = []
    @Published var queuedPosts: [SocialPost] = []
    @Published var isLoading = false
    @Published var isOnline = false
    
    private init() {
        // Start with empty posts - real app behavior for first-time offline user
        loadCommunityPosts()
        
        // Simulate checking network connectivity
        checkNetworkStatus()
    }
    
    private func loadCommunityPosts() {
        // In a real app, this would check network connectivity and load from server
        // For now, shows empty state as user would see offline/first time
        if isOnline {
            // Would load actual posts from server/cache
            posts = []
        } else {
            posts = []
            // Show any queued posts in the feed
            posts = queuedPosts
        }
    }
    
    private func checkNetworkStatus() {
        // Real network connectivity monitoring using NWPathMonitor
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let wasOnline = self?.isOnline ?? false
                self?.isOnline = path.status == .satisfied
                
                // If we just came back online, publish queued posts
                if !wasOnline && path.status == .satisfied {
                    self?.publishQueuedPosts()
                }
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
        
        // Store monitor to prevent deallocation
        self.networkMonitor = monitor
    }
    
    // Store network monitor to prevent deallocation
    private var networkMonitor: NWPathMonitor?
    
    func queuePost(_ post: SocialPost) {
        var queuedPost = post
        queuedPost.isQueued = true
        queuedPost.queuedAt = Date()
        
        queuedPosts.append(queuedPost)
        posts.insert(queuedPost, at: 0) // Show at top of feed
        
        // Simulate automatic retry when connection is restored
        scheduleQueuedPostRetry()
    }
    
    func publishPost(_ post: SocialPost) {
        // Add to main posts feed (if online)
        posts.insert(post, at: 0)
    }
    
    private func publishQueuedPosts() {
        guard isOnline && !queuedPosts.isEmpty else { return }
        
        // In real app, would send queued posts to server
        for i in 0..<queuedPosts.count {
            queuedPosts[i].isQueued = false
            queuedPosts[i].queuedAt = nil
            
            // Update corresponding post in main feed
            if let index = posts.firstIndex(where: { $0.id == queuedPosts[i].id }) {
                posts[index] = queuedPosts[i]
            }
        }
        
        queuedPosts.removeAll()
    }
    
    private func scheduleQueuedPostRetry() {
        // Simulate periodic retry attempts
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            // In real app, would check network and retry
            // For demo, posts stay queued until manually connected
        }
    }
    
    func refreshPosts() {
        isLoading = true
        // Simulate network request
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            // In real app, would populate with actual data if online
            if self.isOnline {
                self.publishQueuedPosts()
            }
        }
    }
    
    func simulateGoOnline() {
        // For testing purposes - simulate coming back online
        isOnline = true
        publishQueuedPosts()
    }
}

#Preview {
    LocalCommunityFeedSection()
}

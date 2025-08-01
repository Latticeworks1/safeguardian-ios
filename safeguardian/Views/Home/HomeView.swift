import SwiftUI

struct HomeView: View {
    @StateObject private var meshManager = SafeGuardianMeshManager()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Safety Status Header with Mesh Integration
                    SafetyStatusHeaderWithMesh(meshManager: meshManager)
                    
                    // Local Community Feed Section
                    LocalCommunityFeedSection()
                }
                .padding(.vertical)
            }
            .navigationTitle("SafeGuardian")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Minimal Home View
struct MinimalHomeView: View {
    @ObservedObject var meshManager: SafeGuardianMeshManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Minimal sticky header
            MinimalTopHeader(title: "SafeGuardian", meshManager: meshManager)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Minimal community feed
                    MinimalCommunitySection()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
.background(Color(.systemBackground))
    }
}

// MARK: - Enhanced Minimal Community Section with BitChat Integration
struct MinimalCommunitySection: View {
    @StateObject private var meshManager = SafeGuardianMeshManager()
    @State private var posts: [CommunityPost] = []
    @State private var showingEmergencyBroadcast = false
    
    var body: some View {
        LazyVStack(spacing: 12) {
            // Emergency Broadcast Button - Always Visible for Safety
            EmergencyBroadcastButton(meshManager: meshManager, showingEmergencyBroadcast: $showingEmergencyBroadcast)
            
            // Real-time Community Posts from Mesh Network
            ForEach(posts.prefix(5), id: \.id) { post in
                MinimalPostCard(post: post)
            }
            
            // Enhanced Empty State with Mesh Network Context
            if posts.isEmpty {
                MeshNetworkEmptyState(meshManager: meshManager)
                    .padding(.vertical, 40)
            }
            
            // Live Mesh Network Activity Indicator
            if meshManager.isConnected {
                LiveMeshActivityIndicator(meshManager: meshManager)
            }
        }
        .onAppear {
            loadMeshNetworkPosts()
        }
        .onChange(of: meshManager.messages) { _ in
            loadMeshNetworkPosts()
        }
        .sheet(isPresented: $showingEmergencyBroadcast) {
            EmergencyBroadcastView(meshManager: meshManager)
        }
    }
    
    private func loadMeshNetworkPosts() {
        // Convert BitChat messages to community posts
        let meshPosts = meshManager.messages.suffix(5).compactMap { message -> CommunityPost? in
            let postType: CommunityPostType = meshManager.isEmergencyMessage(message.content) ? .alert : .general
            
            return CommunityPost(
                id: message.id,
                author: message.sender,
                content: message.content,
                timestamp: message.timestamp,
                type: postType,
                location: "Mesh Network"
            )
        }
        
        // If no mesh messages, show sample posts to demonstrate functionality
        if meshPosts.isEmpty && meshManager.isConnected {
            posts = [
                CommunityPost(
                    id: "mesh-demo-1",
                    author: "Mesh Network",
                    content: "\(meshManager.connectedPeers.count) community members connected via mesh network",
                    timestamp: Date(),
                    type: .announcement,
                    location: "Local Network"
                )
            ]
        } else {
            posts = Array(meshPosts.reversed()) // Show newest first
        }
    }
}

// MARK: - Minimal Post Card
struct MinimalPostCard: View {
    let post: CommunityPost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(post.author)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text(formatTime(post.timestamp))
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            Text(post.content)
                .font(.system(size: 15, weight: .regular, design: .default))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
            
            if let location = post.location {
                HStack(spacing: 4) {
                    Image(systemName: "location")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    
                    Text(location)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Minimal Empty State  
struct MinimalEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.secondary)
            
            Text(title)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
            
            Text(subtitle)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Safety Status Header with Mesh Integration
struct SafetyStatusHeaderWithMesh: View {
    @ObservedObject var meshManager: SafeGuardianMeshManager
    
    var body: some View {
        HStack(spacing: 16) {
            SafetyIndicator(
                status: meshManager.isConnected ? .safe : .disconnected,
                size: .large
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(safetyStatusMessage)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                
                Text(networkStatusDetail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                // Enhanced Mesh Network Status with Emergency Broadcast
                if meshManager.isConnected {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.caption)
                                .foregroundStyle(.green)
                            
                            Text(meshNetworkStatus)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Network Quality Details
                        HStack(spacing: 8) {
                            NetworkQualityIndicator(quality: meshManager.getNetworkQuality())
                            
                            Text("Network: \(meshManager.getNetworkQuality().description)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                } else {
                    // Offline Status with Mesh Network Context
                    HStack(spacing: 8) {
                        Image(systemName: "antenna.radiowaves.left.and.right.slash")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        
                        Text("Searching for mesh network...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    private var safetyStatusMessage: String {
        return "SafeGuardian"
    }
    
    private var networkStatusDetail: String {
        let quality = meshManager.getNetworkQuality()
        switch quality {
        case .offline:
            return "Ready for emergency assistance"
        case .poor:
            return "Limited community coverage"
        case .good:
            return "Good community coverage"
        case .excellent:
            return "Excellent community coverage"
        }
    }
    
    private var meshNetworkStatus: String {
        if meshManager.isConnected {
            return "\(meshManager.connectedPeers.count) community member\(meshManager.connectedPeers.count == 1 ? "" : "s") nearby"
        } else {
            return ""
        }
    }
}

// MARK: - Emergency Broadcast Button
struct EmergencyBroadcastButton: View {
    @ObservedObject var meshManager: SafeGuardianMeshManager
    @Binding var showingEmergencyBroadcast: Bool
    
    var body: some View {
        Button(action: { showingEmergencyBroadcast = true }) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.octagon.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Emergency Broadcast")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Text(meshManager.isConnected ? 
                         "Alert \(meshManager.connectedPeers.count) neighbors" : 
                         "Will broadcast when connected")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.red.gradient)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Enhanced Empty State with Mesh Network Context
struct MeshNetworkEmptyState: View {
    @ObservedObject var meshManager: SafeGuardianMeshManager
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: meshManager.isConnected ? "antenna.radiowaves.left.and.right" : "wifi.slash")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(meshManager.isConnected ? .green : .orange)
            
            VStack(spacing: 8) {
                Text(meshManager.isConnected ? "Mesh Network Active" : "Connect to Mesh Network")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)
                
                Text(meshManager.isConnected ? 
                     "Connected to \(meshManager.connectedPeers.count) neighbors. Community posts will appear here." :
                     "Enable mesh networking to see community updates and emergency alerts from nearby neighbors.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Live Mesh Activity Indicator
struct LiveMeshActivityIndicator: View {
    @ObservedObject var meshManager: SafeGuardianMeshManager
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(.green)
                .frame(width: 8, height: 8)
                .scaleEffect(isAnimating ? 1.2 : 0.8)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isAnimating)
            
            Text("Live mesh network with \(meshManager.connectedPeers.count) neighbors")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(networkQualityText)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .onAppear {
            isAnimating = true
        }
    }
    
    private var networkQualityText: String {
        switch meshManager.getNetworkQuality() {
        case .excellent: return "Excellent Coverage"
        case .good: return "Good Coverage"
        case .poor: return "Limited Coverage"
        case .offline: return "No Coverage"
        }
    }
}

// MARK: - Network Quality Indicator
struct NetworkQualityIndicator: View {
    let quality: NetworkQuality
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(barColor(for: index))
                    .frame(width: 3, height: CGFloat(4 + index * 2))
            }
        }
    }
    
    private func barColor(for index: Int) -> Color {
        let activeBarCount: Int
        switch quality {
        case .offline: activeBarCount = 0
        case .poor: activeBarCount = 1
        case .good: activeBarCount = 2
        case .excellent: activeBarCount = 3
        }
        
        return index < activeBarCount ? Color(quality.color) : .secondary.opacity(0.3)
    }
}

// MARK: - Emergency Broadcast View
struct EmergencyBroadcastView: View {
    @ObservedObject var meshManager: SafeGuardianMeshManager
    @Environment(\.dismiss) private var dismiss
    @State private var emergencyMessage = ""
    @State private var selectedEmergencyType: EmergencyType = .general
    @State private var isBroadcasting = false
    
    enum EmergencyType: CaseIterable {
        case general, medical, fire, police, weather
        
        var title: String {
            switch self {
            case .general: return "General Emergency"
            case .medical: return "Medical Emergency"
            case .fire: return "Fire Emergency"
            case .police: return "Security Emergency"
            case .weather: return "Weather Emergency"
            }
        }
        
        var icon: String {
            switch self {
            case .general: return "exclamationmark.triangle.fill"
            case .medical: return "cross.fill"
            case .fire: return "flame.fill"
            case .police: return "shield.fill"
            case .weather: return "cloud.bolt.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .general: return .orange
            case .medical: return .red
            case .fire: return .red
            case .police: return .blue
            case .weather: return .purple
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Emergency Type Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Emergency Type")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(EmergencyType.allCases, id: \.self) { type in
                            EmergencyTypeButton(
                                type: type,
                                isSelected: selectedEmergencyType == type,
                                action: { selectedEmergencyType = type }
                            )
                        }
                    }
                }
                
                // Emergency Message Input
                VStack(alignment: .leading, spacing: 12) {
                    Text("Emergency Details")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    TextEditor(text: $emergencyMessage)
                        .font(.body)
                        .frame(minHeight: 100)
                        .padding(12)
                        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.separator, lineWidth: 1)
                        )
                }
                
                // Network Status
                HStack(spacing: 8) {
                    Image(systemName: meshManager.isConnected ? "antenna.radiowaves.left.and.right" : "wifi.slash")
                        .foregroundStyle(meshManager.isConnected ? .green : .orange)
                    
                    Text(meshManager.isConnected ? 
                         "Will broadcast to \(meshManager.connectedPeers.count) neighbors" :
                         "Will queue until mesh network connects")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                
                Spacer()
                
                // Broadcast Button
                Button(action: broadcastEmergency) {
                    HStack(spacing: 8) {
                        if isBroadcasting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "megaphone.fill")
                        }
                        
                        Text(isBroadcasting ? "Broadcasting..." : "Send Emergency Broadcast")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.red.gradient, in: RoundedRectangle(cornerRadius: 12))
                }
                .disabled(emergencyMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isBroadcasting)
            }
            .padding(20)
            .navigationTitle("Emergency Broadcast")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .disabled(isBroadcasting)
                }
            }
        }
    }
    
    private func broadcastEmergency() {
        let message = "🚨 [\(selectedEmergencyType.title.uppercased())] \(emergencyMessage.trimmingCharacters(in: .whitespacesAndNewlines))"
        
        isBroadcasting = true
        
        // Send emergency broadcast through mesh network
        meshManager.sendEmergencyBroadcast(message)
        
        // Simulate broadcast delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isBroadcasting = false
            dismiss()
        }
    }
}

// MARK: - Emergency Type Button
struct EmergencyTypeButton: View {
    let type: EmergencyBroadcastView.EmergencyType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : type.color)
                
                Text(type.title)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? AnyShapeStyle(type.color.gradient) : AnyShapeStyle(.quaternary.opacity(0.5)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? AnyShapeStyle(type.color) : AnyShapeStyle(.separator), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
}
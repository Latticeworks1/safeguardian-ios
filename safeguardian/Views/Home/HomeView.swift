import SwiftUI

struct HomeView: View {
    @StateObject private var meshManager = SafeGuardianMeshManager()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Safety Status Header with Mesh Integration
                    SafetyStatusHeaderWithMesh(meshManager: meshManager)
                    
                    // Community Actions Section
                    CommunityActionsSection()
                    
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
                
                // Mesh Network Status - only show when connected
                if meshManager.isConnected {
                    HStack(spacing: 8) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.caption)
                            .foregroundStyle(.green)
                        
                        Text(meshNetworkStatus)
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

#Preview {
    HomeView()
}
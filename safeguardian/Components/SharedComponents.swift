import SwiftUI

// MARK: - Minimal 2025 Design System

// MARK: - Minimal Top Header
struct MinimalTopHeader: View {
    let title: String
    @ObservedObject var meshManager: SafeGuardianMeshManager
    @State private var showingDownloadState = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Title with minimal styling
            Text(title)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
            
            Spacer()
            
            // Minimal status indicators
            HStack(spacing: 8) {
                // Peer count indicator (minimal)
                if meshManager.isConnected {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.blue)
                            .frame(width: 6, height: 6)
                        
                        Text("\(meshManager.connectedPeers.count)")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Circle()
                        .fill(.gray.opacity(0.5))
                        .frame(width: 6, height: 6)
                }
                
                // Download state indicator
                if showingDownloadState {
                    DownloadStateIndicator()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .onAppear {
            // Show download state on first launch
            if title == "SafeGuardian" {
                showingDownloadState = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        showingDownloadState = false
                    }
                }
            }
        }
    }
}

// MARK: - Download State Indicator
struct DownloadStateIndicator: View {
    @State private var progress: Double = 0.0
    @State private var isComplete = false
    
    var body: some View {
        HStack(spacing: 6) {
            if isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.green)
            } else {
                Circle()
                    .trim(from: 0.0, to: progress)
                    .stroke(.blue, lineWidth: 2)
                    .frame(width: 12, height: 12)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
            
            Text(isComplete ? "Ready" : "Loading")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .onAppear {
            simulateDownload()
        }
    }
    
    private func simulateDownload() {
        withAnimation(.easeInOut(duration: 2)) {
            progress = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation {
                isComplete = true
            }
        }
    }
}

// MARK: - Initial Loading State
struct InitialLoadingState: View {
    @State private var progress: Double = 0.0
    @State private var loadingStage = "Initializing..."
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // App logo/icon area
            Circle()
                .fill(.blue.opacity(0.1))
                .frame(width: 80, height: 80)
                .overlay {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(.blue)
                }
            
            VStack(spacing: 12) {
                Text("SafeGuardian")
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(loadingStage)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                
                // Minimal progress bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(.gray.opacity(0.2))
                    .frame(width: 200, height: 4)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.blue)
                            .frame(width: 200 * progress, height: 4)
                    }
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
        .onAppear {
            simulateLoading()
        }
    }
    
    private func simulateLoading() {
        let stages = [
            (0.2, "Connecting to mesh..."),
            (0.5, "Loading safety data..."),
            (0.8, "Preparing AI guide..."),
            (1.0, "Ready")
        ]
        
        for (index, (targetProgress, stage)) in stages.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.8) {
                withAnimation {
                    progress = targetProgress
                    loadingStage = stage
                }
            }
        }
    }
}

// MARK: - Shared UI Components
struct ModernButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct EmptyStateCard: View {
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

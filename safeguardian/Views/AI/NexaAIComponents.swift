import SwiftUI

// MARK: - NexaAI Model Download View
struct NexaAIModelDownloadView: View {
    @ObservedObject var nexaAI: NexaAIService
    
    var body: some View {
        switch nexaAI.modelDownloadStatus {
        case .notDownloaded:
            ModelNotDownloadedSection(nexaAI: nexaAI)
        case .downloading:
            ModelDownloadingSection(progress: nexaAI.downloadProgress)
        case .ready:
            EmptyView() // Don't show anything when ready
        case .error(let message):
            ModelErrorSection(message: message, nexaAI: nexaAI)
        }
    }
}

// MARK: - Model Not Downloaded Section
struct ModelNotDownloadedSection: View {
    @ObservedObject var nexaAI: NexaAIService
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Enhanced AI")
                    .font(.subheadline.weight(.medium))
                
                Text("Download model for better responses")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button("Download") {
                Task {
                    await nexaAI.downloadModel()
                }
            }
            .font(.caption.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.blue, in: Capsule())
            .foregroundStyle(.white)
        }
        .padding()
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Model Downloading Section
struct ModelDownloadingSection: View {
    let progress: Double
    
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Downloading Model")
                    .font(.subheadline.weight(.medium))
                
                Text("\(Int(progress * 100))% complete")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Model Ready Section
struct ModelReadySection: View {
    @ObservedObject var nexaAI: NexaAIService
    
    var body: some View {
        EmptyView() // Hide when ready - toggle will appear instead
    }
}

// MARK: - Model Error Section
struct ModelErrorSection: View {
    let message: String
    @ObservedObject var nexaAI: NexaAIService
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Download Failed")
                    .font(.subheadline.weight(.medium))
                
                Text("Tap to retry")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button("Retry") {
                Task {
                    await nexaAI.downloadModel()
                }
            }
            .font(.caption.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.orange, in: Capsule())
            .foregroundStyle(.white)
        }
        .padding()
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Model Info Sheet
struct NexaAIModelInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "brain.head.profile.fill")
                                .font(.title)
                                .foregroundStyle(.blue)
                            
                            Text("NexaAI Integration")
                                .font(.title2.weight(.semibold))
                        }
                        
                        Text("Enhanced AI-powered safety assistance")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Divider()
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Features")
                            .font(.headline)
                        
                        FeatureRow(
                            icon: "shield.checkered",
                            title: "Context-Aware Safety Responses",
                            description: "Advanced AI understanding of safety scenarios and personalized guidance"
                        )
                        
                        FeatureRow(
                            icon: "lock.fill",
                            title: "Privacy-First Design",
                            description: "All AI processing happens locally on your device - no data sent to servers"
                        )
                        
                        FeatureRow(
                            icon: "bolt.fill",
                            title: "Offline Capability",
                            description: "Works without internet connection once the model is downloaded"
                        )
                        
                        FeatureRow(
                            icon: "exclamationmark.triangle.fill",
                            title: "Emergency Detection",
                            description: "Advanced emergency keyword detection with priority routing"
                        )
                    }
                    
                    Divider()
                    
                    // Technical Details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Technical Details")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            DetailRow(label: "Model", value: "Qwen2-0.5B-Instruct")
                            DetailRow(label: "Size", value: "~150 MB")
                            DetailRow(label: "Quantization", value: "Q4_K_M (optimized)")
                            DetailRow(label: "Processing", value: "On-device only")
                        }
                    }
                    
                    Divider()
                    
                    // Important Notice
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.red)
                            Text("Important Safety Notice")
                                .font(.headline)
                                .foregroundStyle(.red)
                        }
                        
                        Text("This AI assistant provides safety guidance but should never replace emergency services. Always call 911 for real emergencies.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
                .padding()
            }
            .navigationTitle("AI Assistant Info")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

// MARK: - Helper Views
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - AI Generation Indicator
struct NexaAIGenerationIndicator: View {
    @State private var animationPhase = 0
    @State private var pulseScale = 1.0
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.1))
                    .frame(width: 36, height: 36)
                    .scaleEffect(pulseScale)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseScale)
                
                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("AI Assistant is thinking")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.primary)
                
                HStack(spacing: 6) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 5, height: 5)
                            .scaleEffect(animationPhase == index ? 1.3 : 0.7)
                            .opacity(animationPhase == index ? 1.0 : 0.4)
                            .animation(
                                .easeInOut(duration: 0.6).repeatForever(autoreverses: false),
                                value: animationPhase
                            )
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.blue.opacity(0.2), lineWidth: 1)
            }
        )
        .shadow(color: .blue.opacity(0.1), radius: 8, x: 0, y: 4)
        .onAppear {
            pulseScale = 1.1
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}

// MARK: - AI Response Toggle
struct AIResponseToggle: View {
    @Binding var useNexaAI: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .foregroundStyle(useNexaAI ? .blue : .secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Enhanced AI")
                    .font(.subheadline.weight(.medium))
                
                Text("Use downloaded model")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $useNexaAI)
                .labelsHidden()
        }
        .padding()
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    VStack(spacing: 20) {
        NexaAIModelDownloadView(nexaAI: NexaAIService())
        AIResponseToggle(useNexaAI: .constant(true))
        NexaAIGenerationIndicator()
    }
    .padding()
}
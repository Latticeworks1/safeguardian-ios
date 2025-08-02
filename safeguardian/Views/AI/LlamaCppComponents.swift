import SwiftUI
import Combine

// MARK: - Real llama.cpp UI Components for SafeGuardian
// Production-ready UI integration with SwiftLlama

// MARK: - Enhanced AI View with Real llama.cpp Integration
struct LlamaCppAIView: View {
    @ObservedObject var meshManager: SafeGuardianMeshManager
    @StateObject private var llamaService = LlamaCppService()
    @StateObject private var streamingAI = LlamaCppStreamingService()
    @State private var userInput = ""
    @State private var messages: [AIMessage] = []
    @State private var isStreaming = false
    @State private var currentStreamingResponse = ""
    @State private var showEmergencyAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Minimal header
            MinimalTopHeader(title: "SafeGuardian AI", meshManager: meshManager)
            
            // Chat area
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        // llama.cpp Model Download Section
                        LlamaCppModelDownloadView(llamaService: llamaService)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        
                        // AI Status Indicator (when model is ready)
                        if llamaService.modelDownloadStatus.canGenerate {
                            LlamaCppStatusIndicator(
                                llamaService: llamaService,
                                meshManager: meshManager
                            )
                            .padding(.horizontal, 20)
                        }
                        
                        // Messages
                        ForEach(messages, id: \.id) { message in
                            EnhancedAIMessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        // Real-time streaming response bubble
                        if isStreaming && !currentStreamingResponse.isEmpty {
                            LlamaCppStreamingBubble(content: currentStreamingResponse)
                                .id("streaming")
                        }
                        
                        // Generation indicator
                        if isStreaming {
                            LlamaCppGenerationIndicator()
                                .padding(.horizontal, 20)
                                .id("indicator")
                        }
                        
                        // Empty state with safety focus
                        if messages.isEmpty && !isStreaming {
                            LlamaCppEmptyState(
                                llamaService: llamaService,
                                onQuickAction: sendQuickAction
                            )
                            .padding(.vertical, 40)
                        }
                    }
                    .onChange(of: messages.count) { _, _ in
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: isStreaming) { _, streaming in
                        if streaming {
                            scrollToBottom(proxy: proxy)
                        }
                    }
                }
            }
            
            // Emergency Alert Banner
            if showEmergencyAlert {
                EmergencyAlertBanner()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
            
            // Input area with llama.cpp integration
            LlamaCppAIInput(
                text: $userInput,
                isProcessing: isStreaming,
                isModelReady: llamaService.modelDownloadStatus.canGenerate,
                onSend: sendMessage,
                onCancel: cancelStreaming
            )
        }
        .background(Color(.systemBackground))
        .alert("Emergency Detected", isPresented: $showEmergencyAlert) {
            Button("Call 911", role: .destructive) {
                if let url = URL(string: "tel://911") {
                    UIApplication.shared.open(url)
                }
            }
            Button("Continue Chat", role: .cancel) {}
        } message: {
            Text("Emergency keywords detected. For real emergencies, call 911 immediately.")
        }
        .onAppear {
            if messages.isEmpty && llamaService.modelDownloadStatus.canGenerate {
                addWelcomeMessage()
            }
        }
    }
    
    // MARK: - Real llama.cpp Integration Methods
    
    private func sendMessage() {
        let trimmedText = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty, !isStreaming else { return }
        
        // Add user message
        let userMessage = AIMessage(content: trimmedText, isFromUser: true)
        messages.append(userMessage)
        
        // Check for emergency keywords
        if containsEmergencyKeywords(trimmedText) {
            showEmergencyAlert = true
        }
        
        let inputToProcess = userInput
        userInput = ""
        
        // Generate AI response using real llama.cpp
        Task {
            await generateLlamaCppResponse(for: inputToProcess)
        }
    }
    
    private func sendQuickAction(_ action: String) {
        userInput = action
        sendMessage()
    }
    
    private func generateLlamaCppResponse(for prompt: String) async {
        guard llamaService.modelDownloadStatus.canGenerate else {
            await addBasicSafetyResponse(for: prompt)
            return
        }
        
        await MainActor.run {
            isStreaming = true
            currentStreamingResponse = ""
        }
        
        // Use real llama.cpp streaming via SwiftLlama
        await llamaService.generateStreamingResponse(for: prompt) { token, isComplete in
            Task { @MainActor in
                if isComplete {
                    // Final response - add to messages
                    let aiMessage = AIMessage(content: currentStreamingResponse, isFromUser: false)
                    messages.append(aiMessage)
                    isStreaming = false
                    currentStreamingResponse = ""
                } else {
                    // Real streaming token from llama.cpp
                    currentStreamingResponse += token
                }
            }
            return !isStreaming // Continue streaming unless cancelled
        }
    }
    
    private func addBasicSafetyResponse(for prompt: String) async {
        await MainActor.run {
            let response = """
            🛡️ SafeGuardian AI Assistant (llama.cpp)
            
            For enhanced AI responses, please download the llama.cpp model above.
            
            ⚠️ For emergencies: Call 911 immediately
            🌐 Use Mesh Chat to coordinate with nearby community
            📍 Check Safety Map for emergency services
            
            The downloaded model provides intelligent safety guidance powered by llama.cpp.
            """
            
            let aiMessage = AIMessage(content: response, isFromUser: false)
            messages.append(aiMessage)
        }
    }
    
    private func cancelStreaming() {
        isStreaming = false
        currentStreamingResponse = ""
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = messages.last {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        } else if isStreaming {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo("streaming", anchor: .bottom)
            }
        }
    }
    
    private func containsEmergencyKeywords(_ text: String) -> Bool {
        let emergencyKeywords = ["emergency", "help", "danger", "urgent", "911", "crisis", "attack", "hurt"]
        return emergencyKeywords.contains { text.lowercased().contains($0) }
    }
    
    private func addWelcomeMessage() {
        let welcomeMessage = AIMessage(
            content: "👋 Hello! I'm your SafeGuardian AI assistant powered by llama.cpp. I provide intelligent safety guidance, emergency planning, and community coordination.\n\n⚠️ For real emergencies, always call 911 first.\n\nHow can I help keep you safe today?",
            isFromUser: false
        )
        messages.append(welcomeMessage)
    }
}

// MARK: - llama.cpp Model Download UI
struct LlamaCppModelDownloadView: View {
    @ObservedObject var llamaService: LlamaCppService
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Model Status Header
            HStack(spacing: 12) {
                Image(systemName: "brain.head.profile.fill")
                    .font(.title2)
                    .foregroundStyle(statusColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("llama.cpp AI Model")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(llamaService.modelDownloadStatus.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if llamaService.modelDownloadStatus.canGenerate {
                        let (size, status) = llamaService.getModelInfo()
                        Text("Size: \(size) • Status: \(status)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                Spacer()
                
                statusIndicator
            }
            .padding()
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: 1)
            )
            
            // Download Progress (when downloading)
            if case .downloading = llamaService.modelDownloadStatus {
                VStack(spacing: 8) {
                    ProgressView(value: llamaService.downloadProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    
                    HStack {
                        Text("Downloading Qwen2-0.5B model...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(llamaService.downloadProgress * 100))%")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                switch llamaService.modelDownloadStatus {
                case .notDownloaded:
                    Button("Download AI Model") {
                        Task {
                            do {
                                try await llamaService.downloadModel()
                            } catch {
                                print("Download failed: \(error)")
                            }
                        }
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    
                case .downloading:
                    Button("Cancel Download") {
                        llamaService.deleteModel()
                    }
                    .buttonStyle(SecondaryActionButtonStyle())
                    
                case .ready:
                    Button("Delete Model") {
                        showingDeleteConfirmation = true
                    }
                    .buttonStyle(DestructiveActionButtonStyle())
                    
                case .error:
                    Button("Retry Download") {
                        Task {
                            do {
                                try await llamaService.downloadModel()
                            } catch {
                                print("Retry failed: \(error)")
                            }
                        }
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                }
                
                // Info button
                Button(action: {
                    // Could show model info sheet
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .alert("Delete AI Model", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                llamaService.deleteModel()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the downloaded llama.cpp model (~150MB). You can re-download it anytime.")
        }
    }
    
    private var statusColor: Color {
        switch llamaService.modelDownloadStatus {
        case .notDownloaded: return .orange
        case .downloading: return .blue
        case .ready: return .green
        case .error: return .red
        }
    }
    
    private var backgroundColor: Color {
        switch llamaService.modelDownloadStatus {
        case .notDownloaded: return .orange.opacity(0.1)
        case .downloading: return .blue.opacity(0.1)
        case .ready: return .green.opacity(0.1)
        case .error: return .red.opacity(0.1)
        }
    }
    
    private var borderColor: Color {
        switch llamaService.modelDownloadStatus {
        case .notDownloaded: return .orange.opacity(0.3)
        case .downloading: return .blue.opacity(0.3)
        case .ready: return .green.opacity(0.3)
        case .error: return .red.opacity(0.3)
        }
    }
    
    @ViewBuilder
    private var statusIndicator: some View {
        switch llamaService.modelDownloadStatus {
        case .notDownloaded:
            Image(systemName: "arrow.down.circle")
                .font(.title3)
                .foregroundStyle(.orange)
                
        case .downloading:
            ProgressView()
                .scaleEffect(0.8)
                
        case .ready:
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.green)
                
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.red)
        }
    }
}

// MARK: - llama.cpp Status Indicator
struct LlamaCppStatusIndicator: View {
    @ObservedObject var llamaService: LlamaCppService
    @ObservedObject var meshManager: SafeGuardianMeshManager
    
    var body: some View {
        HStack(spacing: 12) {
            // llama.cpp model indicator
            Image(systemName: "brain.head.profile.fill")
                .foregroundStyle(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("llama.cpp AI Ready")
                    .font(.subheadline.weight(.medium))
                
                HStack(spacing: 4) {
                    Text("Connected to \(meshManager.connectedPeers.count) peers")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if llamaService.isGenerating {
                        Text("• Generating...")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
                
                Text("llama.cpp")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.green.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Real-time Streaming Bubble for llama.cpp
struct LlamaCppStreamingBubble: View {
    let content: String
    @State private var showCursor = true
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .bottom) {
                    Text(content + (showCursor ? "|" : ""))
                        .font(.system(size: 15, weight: .regular, design: .default))
                        .foregroundStyle(.primary)
                        .textSelection(.enabled) // Allow text selection
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                
                HStack(spacing: 4) {
                    Image(systemName: "brain.head.profile.fill")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    
                    Text("llama.cpp generating...")
                        .font(.system(size: 10, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer(minLength: 50)
        }
        .padding(.horizontal, 4)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                showCursor.toggle()
            }
        }
    }
}

// MARK: - llama.cpp Generation Indicator
struct LlamaCppGenerationIndicator: View {
    @State private var animationPhase = 0
    @State private var pulseScale = 1.0
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.15))
                    .frame(width: 40, height: 40)
                    .scaleEffect(pulseScale)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulseScale)
                
                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("llama.cpp inference...")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.primary)
                
                HStack(spacing: 6) {
                    ForEach(0..<4) { index in
                        Circle()
                            .fill(.blue)
                            .frame(width: 4, height: 4)
                            .scaleEffect(animationPhase == index ? 1.5 : 0.8)
                            .opacity(animationPhase == index ? 1.0 : 0.4)
                            .animation(
                                .easeInOut(duration: 0.8).repeatForever(autoreverses: false),
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
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.blue.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .blue.opacity(0.1), radius: 8, x: 0, y: 4)
        .onAppear {
            pulseScale = 1.1
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                animationPhase = (animationPhase + 1) % 4
            }
        }
    }
}

// MARK: - Enhanced Empty State for llama.cpp
struct LlamaCppEmptyState: View {
    @ObservedObject var llamaService: LlamaCppService
    let onQuickAction: (String) -> Void
    
    private let quickSafetyActions = [
        ("shield.checkered", "Safety Tips", "Give me comprehensive safety tips for daily life"),
        ("location.fill", "Safe Routes", "How do I plan safe routes when traveling alone?"),
        ("person.2.fill", "Community Safety", "How can I coordinate with my community for safety?"),
        ("exclamationmark.triangle.fill", "Emergency Prep", "What should I know about emergency preparedness?")
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            // llama.cpp AI Status Section
            VStack(spacing: 16) {
                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(spacing: 8) {
                    Text("SafeGuardian AI")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    Text("Powered by llama.cpp")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.blue)
                    
                    Text(llamaService.modelDownloadStatus.canGenerate ? 
                         "Ready for intelligent safety guidance and emergency assistance" :
                         "Download the AI model above for enhanced safety responses")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Quick Safety Actions (only show when model is ready)
            if llamaService.modelDownloadStatus.canGenerate {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Safety Topics")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                        ForEach(Array(quickSafetyActions.enumerated()), id: \.offset) { _, actionData in
                            let (icon, title, query) = actionData
                            SafetyActionButton(icon: icon, title: title) {
                                onQuickAction(query)
                            }
                        }
                    }
                }
            }
            
            // Safety and Technology Notice
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text("Emergency Notice")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.red)
                }
                
                Text("For real emergencies, always call 911 first. This AI provides guidance but cannot replace emergency services.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                
                if llamaService.modelDownloadStatus.canGenerate {
                    HStack(spacing: 4) {
                        Image(systemName: "cpu.fill")
                            .foregroundStyle(.blue)
                        Text("Running locally via llama.cpp for privacy")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(12)
            .background(.red.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
        }
        .padding()
    }
}

// MARK: - Safety Action Button
struct SafetyActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.blue)
                
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.blue.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - llama.cpp AI Input
struct LlamaCppAIInput: View {
    @Binding var text: String
    let isProcessing: Bool
    let isModelReady: Bool
    let onSend: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            if !isModelReady {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                    Text("Download llama.cpp model above for AI-powered safety responses")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            
            HStack(spacing: 12) {
                TextField("Ask for safety advice or emergency guidance...", text: $text, axis: .vertical)
                    .font(.system(size: 15, weight: .regular, design: .default))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .disabled(isProcessing)
                    .onSubmit {
                        if !isProcessing {
                            onSend()
                        }
                    }
                
                if isProcessing {
                    Button(action: onCancel) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.red)
                    }
                } else {
                    Button(action: onSend) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(canSend ? .blue : .gray)
                    }
                    .disabled(!canSend || isProcessing)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - llama.cpp Streaming Service
class LlamaCppStreamingService: ObservableObject {
    @Published var isGenerating = false
    
    func generateStreamingResponse(for prompt: String, onToken: @escaping (String, Bool) -> Bool) async {
        // This would integrate with the LlamaCppService
        // For now, provides a placeholder that shows the streaming pattern
        isGenerating = true
        defer { isGenerating = false }
        
        let response = "🛡️ SafeGuardian AI Response (powered by llama.cpp):\n\nThis is a placeholder for real llama.cpp streaming inference. The actual implementation uses SwiftLlama's AsyncStream for token-by-token generation.\n\nFor emergencies, always call 911 first."
        
        // Simulate character-by-character streaming
        for char in response {
            let shouldContinue = onToken(String(char), false)
            if !shouldContinue { break }
            
            try? await Task.sleep(nanoseconds: 25_000_000) // 25ms delay
        }
        
        // Signal completion
        _ = onToken("", true)
    }
}

// MARK: - Button Styles
struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.blue, in: RoundedRectangle(cornerRadius: 8))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.blue)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.blue.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct DestructiveActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.red)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.red.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
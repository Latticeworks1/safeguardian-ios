import SwiftUI

// MARK: - Enhanced AI View with Real NexaAI Integration
struct MinimalAIView: View {
    @ObservedObject var meshManager: SafeGuardianMeshManager
    @StateObject private var nexaAI = NexaAIService()
    @StateObject private var streamingAI = StreamingAIService()
    @State private var userInput = ""
    @State private var messages: [AIMessage] = []
    @State private var isStreaming = false
    @State private var currentStreamingResponse = ""
    @State private var showEmergencyAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Minimal header
            MinimalTopHeader(title: "AI", meshManager: meshManager)
            
            // Chat area
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        // NexaAI Model Download Section (always shown at top)
                        NexaAIModelDownloadView(nexaAI: nexaAI)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        
                        // AI Status Indicator (when model is ready)
                        if nexaAI.modelDownloadStatus.canGenerate {
                            AIStatusIndicator(meshManager: meshManager)
                                .padding(.horizontal, 20)
                        }
                        
                        // Messages
                        ForEach(messages, id: \.id) { message in
                            EnhancedAIMessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        // Streaming response bubble
                        if isStreaming && !currentStreamingResponse.isEmpty {
                            StreamingResponseBubble(content: currentStreamingResponse)
                                .id("streaming")
                        }
                        
                        // Generation indicator
                        if isStreaming {
                            StreamingAIIndicator()
                                .padding(.horizontal, 20)
                                .id("indicator")
                        }
                        
                        // Empty state
                        if messages.isEmpty && !isStreaming {
                            EnhancedEmptyAIState(nexaAI: nexaAI, onQuickAction: sendQuickAction)
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
            
            // Input area
            EnhancedAIInput(
                text: $userInput,
                isProcessing: isStreaming,
                isModelReady: nexaAI.modelDownloadStatus.canGenerate,
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
            // Initialize with welcome message if needed
            if messages.isEmpty && nexaAI.modelDownloadStatus.canGenerate {
                addWelcomeMessage()
            }
        }
    }
    
    // MARK: - Enhanced AI Methods
    
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
        
        // Generate AI response
        Task {
            await generateAIResponse(for: inputToProcess)
        }
    }
    
    private func sendQuickAction(_ action: String) {
        userInput = action
        sendMessage()
    }
    
    private func generateAIResponse(for prompt: String) async {
        guard nexaAI.modelDownloadStatus.canGenerate else {
            // Fallback to basic safety guidance
            await addBasicSafetyResponse(for: prompt)
            return
        }
        
        await MainActor.run {
            isStreaming = true
            currentStreamingResponse = ""
        }
        
        // Use StreamingAI for real-time responses
        await streamingAI.generateStreamingResponse(for: prompt) { token, isComplete in
            Task { @MainActor in
                if isComplete {
                    // Final response - add to messages
                    let aiMessage = AIMessage(content: currentStreamingResponse, isFromUser: false)
                    messages.append(aiMessage)
                    isStreaming = false
                    currentStreamingResponse = ""
                } else {
                    // Streaming token
                    currentStreamingResponse += token
                }
            }
            return !isStreaming // Continue streaming unless cancelled
        }
    }
    
    private func addBasicSafetyResponse(for prompt: String) async {
        await MainActor.run {
            let response = """
            🛡️ SafeGuardian Safety Assistant
            
            For enhanced AI responses, please download the AI model above.
            
            ⚠️ For emergencies: Call 911 immediately
            🌐 Use Mesh Chat to coordinate with nearby community
            📍 Check Safety Map for emergency services
            
            Basic safety reminder: Stay aware of your surroundings and trust your instincts.
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
            content: "👋 Hello! I'm your SafeGuardian AI assistant. I can help with safety guidance, emergency planning, and community coordination.\n\n⚠️ For real emergencies, always call 911 first.\n\nHow can I help keep you safe today?",
            isFromUser: false
        )
        messages.append(welcomeMessage)
    }
}

// MARK: - Enhanced UI Components

// Streaming AI Service for real-time responses
class StreamingAIService: ObservableObject {
    func generateStreamingResponse(for prompt: String, onToken: @escaping (String, Bool) -> Bool) async {
        // Simulate streaming response - replace with real NexaAI streaming when SDK is integrated
        let safetyResponse = generateSafetyResponse(for: prompt)
        
        // Stream character by character
        for (_, char) in safetyResponse.enumerated() {
            let shouldContinue = onToken(String(char), false)
            if !shouldContinue { break }
            
            try? await Task.sleep(nanoseconds: 20_000_000) // 20ms delay
        }
        
        // Signal completion
        _ = onToken("", true)
    }
    
    private func generateSafetyResponse(for prompt: String) -> String {
        let lowercasePrompt = prompt.lowercased()
        
        if lowercasePrompt.contains("emergency") || lowercasePrompt.contains("help") {
            return "🚨 Emergency Response Protocol:\n\n1. Call 911 immediately for real emergencies\n2. Share your location with trusted contacts\n3. Use SafeGuardian's mesh network to alert nearby community members\n4. Stay calm and follow emergency responder instructions\n\nSafeGuardian's mesh network can coordinate community response even without internet."
        }
        
        if lowercasePrompt.contains("safe") || lowercasePrompt.contains("route") {
            return "🛡️ Safe Travel Guidelines:\n\n• Stick to well-lit, populated areas\n• Share your route with trusted contacts\n• Trust your instincts - leave if something feels wrong\n• Use SafeGuardian's mesh network to stay connected\n• Keep emergency contacts easily accessible\n\nSafeGuardian's Safety Map can show nearby emergency services and safe locations."
        }
        
        return "🛡️ SafeGuardian Safety Assistant:\n\nI'm here to provide safety guidance and emergency assistance. For immediate emergencies, always call 911 first.\n\nSafeGuardian's unique features:\n• Mesh network for offline communication\n• Community safety coordination\n• Emergency service location mapping\n• Real-time safety alerts\n\nWhat specific safety situation can I help you with?"
    }
}

// Enhanced AI Message Bubble with better styling
struct EnhancedAIMessageBubble: View {
    let message: AIMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 15, weight: .regular, design: .default))
                    .foregroundStyle(message.isFromUser ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        message.isFromUser ? 
                        AnyShapeStyle(LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)) :
                        AnyShapeStyle(Color(.systemGray5))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                
                Text(message.timestamp, style: .time)
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            if !message.isFromUser {
                Spacer(minLength: 50)
            }
        }
        .padding(.horizontal, 4)
    }
}

// Streaming Response Bubble for real-time AI generation
struct StreamingResponseBubble: View {
    let content: String
    @State private var showCursor = true
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .bottom) {
                    Text(content + (showCursor ? "|" : ""))
                        .font(.system(size: 15, weight: .regular, design: .default))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                
                Text("AI is typing...")
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
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

// Enhanced AI Input with cancel functionality
struct EnhancedAIInput: View {
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
                    Text("Download AI model above for enhanced responses")
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

// AI Status Indicator showing model readiness and mesh network status
struct AIStatusIndicator: View {
    @ObservedObject var meshManager: SafeGuardianMeshManager
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "brain.head.profile.fill")
                .foregroundStyle(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Enhanced AI Ready")
                    .font(.subheadline.weight(.medium))
                
                Text("Connected to \(meshManager.connectedPeers.count) peers")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Circle()
                .fill(.green)
                .frame(width: 8, height: 8)
        }
        .padding()
        .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.green.opacity(0.3), lineWidth: 1)
        )
    }
}

// Enhanced Empty State with quick actions
struct EnhancedEmptyAIState: View {
    @ObservedObject var nexaAI: NexaAIService
    let onQuickAction: (String) -> Void
    
    private let quickActions = [
        ("shield.checkered", "Safety Tips", "Give me important safety tips for daily life"),
        ("location.fill", "Safe Routes", "How do I plan safe routes when traveling?"),
        ("person.2.fill", "Community", "How can I coordinate with my community for safety?"),
        ("exclamationmark.triangle.fill", "Emergency", "What should I do to prepare for emergencies?")
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            // AI Status Section
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
                    Text("SafeGuardian AI Assistant")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    Text(nexaAI.modelDownloadStatus.canGenerate ? 
                         "AI model ready for intelligent safety guidance" :
                         "Enhanced responses available after model download")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Quick Actions
            if nexaAI.modelDownloadStatus.canGenerate {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Safety Topics")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                        ForEach(Array(quickActions.enumerated()), id: \.offset) { _, actionData in
                            let (icon, title, query) = actionData
                            AIQuickActionButton(icon: icon, title: title) {
                                onQuickAction(query)
                            }
                        }
                    }
                }
            }
            
            // Safety Notice
            VStack(spacing: 8) {
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
            }
            .padding(12)
            .background(.red.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
        }
        .padding()
    }
}

// AI Quick Action Button for safety topics
struct AIQuickActionButton: View {
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

// Streaming AI Indicator for active generation
struct StreamingAIIndicator: View {
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
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple.opacity(0.8)],
                            startPoint: .topLeading, 
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("AI is thinking...")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.primary)
                
                HStack(spacing: 6) {
                    ForEach(0..<4) { index in
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
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

// MARK: - Minimal AI Message Bubble
struct MinimalAIMessageBubble: View {
    let message: AIMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 15, weight: .regular, design: .default))
                    .foregroundStyle(message.isFromUser ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(message.isFromUser ? Color.blue : Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                Text(message.timestamp, style: .time)
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            if !message.isFromUser {
                Spacer(minLength: 50)
            }
        }
    }
}

// MARK: - Minimal AI Input
struct MinimalAIInput: View {
    @Binding var text: String
    let isProcessing: Bool
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("Ask for safety advice", text: $text)
                .font(.system(size: 15, weight: .regular, design: .default))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .disabled(isProcessing)
                .onSubmit(onSend)
            
            Button(action: onSend) {
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(canSend ? .blue : .gray)
                }
            }
            .disabled(!canSend || isProcessing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
    }
    
    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct AIGuideView: View {
    @StateObject private var safetyAI = SafetyAIGuide()
    @State private var inputText = ""
    @State private var showingEmergencyAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // AI Chat Messages
                if safetyAI.messages.isEmpty {
                    EmptyAIView(safetyAI: safetyAI)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(safetyAI.messages) { message in
                                    AIMessageBubble(message: message)
                                        .id(message.id)
                                }
                                
                                // Typing indicator
                                if safetyAI.isGenerating {
                                    TypingIndicator()
                                }
                            }
                            .padding()
                        }
                        .onChange(of: safetyAI.messages.count) { _, _ in
                            if let lastMessage = safetyAI.messages.last {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: safetyAI.isGenerating) { _, isGenerating in
                            if isGenerating {
                                // Scroll to show typing indicator
                                withAnimation(.easeOut(duration: 0.3)) {
                                    proxy.scrollTo("typing", anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                
                Divider()
                
                // Input Area
                VStack(spacing: 12) {
                    // Emergency Alert Banner
                    if isEmergencyQuery(inputText) {
                        EmergencyAlertBanner()
                    }
                    
                    // Input Field
                    HStack(spacing: 12) {
                        TextField("Ask about safety, emergencies, or get help...", text: $inputText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(1...4)
                        
                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(inputText.isEmpty ? Color.gray : Color.blue, in: Circle())
                        }
                        .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    
                    // Quick Safety Actions
                    if safetyAI.messages.isEmpty {
                        QuickSafetyActions { action in
                            inputText = action
                            sendMessage()
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
            }
            .navigationTitle("Safety AI Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Emergency") {
                        showingEmergencyAlert = true
                    }
                    .foregroundStyle(.red)
                    .fontWeight(.semibold)
                }
            }
        }
        .alert("Emergency Help", isPresented: $showingEmergencyAlert) {
            Button("Call 911", role: .destructive) {
                if let url = URL(string: "tel://911") {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("For immediate emergencies, call 911 directly. The AI guide is for safety information only.")
        }
    }
    
    private func sendMessage() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        // Check for emergency keywords and show alert
        if isEmergencyQuery(trimmedText) {
            showingEmergencyAlert = true
        }
        
        // Send to AI
        Task {
            await safetyAI.sendMessage(trimmedText)
        }
        inputText = ""
    }
    
    private func isEmergencyQuery(_ text: String) -> Bool {
        let emergencyKeywords = ["emergency", "help", "911", "urgent", "danger", "attack", "accident"]
        let lowercaseText = text.lowercased()
        return emergencyKeywords.contains { lowercaseText.contains($0) }
    }
}

// MARK: - Emergency Alert Banner
struct EmergencyAlertBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Emergency Detected")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                
                Text("For immediate help, call 911 directly")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button("Call 911") {
                if let url = URL(string: "tel://911") {
                    UIApplication.shared.open(url)
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.red, in: Capsule())
        }
        .padding(12)
        .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.red.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Quick Safety Actions
struct QuickSafetyActions: View {
    let onAction: (String) -> Void
    
    private let safetyActions = [
        ("shield.checkered", "Safety Tips", "Give me general safety tips for daily life"),
        ("location.fill", "Safe Routes", "How do I find safe routes when walking?"),
        ("person.2.fill", "Community Safety", "How can I stay safe in my community?"),
        ("exclamationmark.triangle.fill", "Emergency Prep", "How should I prepare for emergencies?")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Safety Topics")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                ForEach(Array(safetyActions.enumerated()), id: \.offset) { _, actionData in
                    let (icon, title, query) = actionData
                    Button(action: { onAction(query) }) {
                        HStack(spacing: 8) {
                            Image(systemName: icon)
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                                .frame(width: 20)
                            
                            Text(title)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    @State private var animationPhase = 0
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "brain.head.profile.fill")
                .font(.title3)
                .foregroundStyle(.blue)
            
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(.secondary)
                        .frame(width: 6, height: 6)
                        .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: animationPhase)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
        .id("typing")
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}

#Preview {
    AIGuideView()
}

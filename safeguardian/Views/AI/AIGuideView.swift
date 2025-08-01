import SwiftUI

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
                .background(.regularMaterial)
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
        safetyAI.sendMessage(trimmedText)
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
                ForEach(Array(safetyActions.enumerated()), id: \.offset) { index, actionData in
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
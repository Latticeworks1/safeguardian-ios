import SwiftUI

struct MeshChatView: View {
    @StateObject private var meshManager = SafeGuardianMeshManager()
    @State private var newMessage = ""
    @State private var showingEmergencyAlert = false
    @State private var emergencyFlashMessage: SafeGuardianMessage?
    @State private var showEmergencyFlash = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Emergency Flash Alert (appears at top when emergency message received)
                if showEmergencyFlash, let emergencyMessage = emergencyFlashMessage {
                    EmergencyFlashAlert(message: emergencyMessage)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                        .onTapGesture {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                showEmergencyFlash = false
                            }
                        }
                }
                
                // Enhanced Connection Status Bar
                MeshConnectionStatusSection(meshManager: meshManager)
                
                // Messages Area
                if meshManager.messages.isEmpty {
                    EmptyMeshChatView(meshManager: meshManager)
                } else {
                    MeshMessagesList(meshManager: meshManager)
                }
                
                // Enhanced Message Input
                MessageInputSection(
                    newMessage: $newMessage,
                    meshManager: meshManager,
                    showingEmergencyAlert: $showingEmergencyAlert,
                    onSend: sendMessage
                )
            }
            .navigationTitle("Mesh Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ConnectionQualityIndicator(meshManager: meshManager)
                }
            }
            .alert("Emergency Message Detected", isPresented: $showingEmergencyAlert) {
                Button("Send Emergency Broadcast", role: .destructive) {
                    meshManager.sendEmergencyBroadcast(newMessage.trimmingCharacters(in: .whitespacesAndNewlines))
                    newMessage = ""
                }
                Button("Send Normal Message") {
                    meshManager.sendMessage(newMessage.trimmingCharacters(in: .whitespacesAndNewlines))
                    newMessage = ""
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This message contains emergency keywords. Would you like to send it as an emergency broadcast to all connected peers?")
            }
            .onAppear {
                // BitChat automatically starts scanning for peers
                print("SafeGuardian mesh chat initialized")
            }
            .onChange(of: meshManager.messages) { _, newMessages in
                // Check for new emergency messages
                if let latestMessage = newMessages.last,
                   meshManager.isEmergencyMessage(latestMessage.content),
                   latestMessage.sender != meshManager.nickname {
                    
                    // Show emergency flash alert
                    emergencyFlashMessage = latestMessage
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showEmergencyFlash = true
                    }
                    
                    // Auto-hide after 10 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            showEmergencyFlash = false
                        }
                    }
                }
            }
        }
    }
    
    private func sendMessage() {
        guard !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let trimmedMessage = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for emergency messages and show alert
        if meshManager.isEmergencyMessage(trimmedMessage) {
            showingEmergencyAlert = true
        } else {
            meshManager.sendMessage(trimmedMessage)
            newMessage = ""
        }
    }
}

// MARK: - Minimal Chat View
struct MinimalChatView: View {
    @ObservedObject var meshManager: SafeGuardianMeshManager
    @State private var newMessage = ""
    @State private var showingEmergencyAlert = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Enhanced header with connection status
            VStack(spacing: 0) {
                MinimalTopHeader(title: "Chat", meshManager: meshManager)
                MeshConnectionStatusSection(meshManager: meshManager)
            }
            
            // Messages or empty state
            if meshManager.messages.isEmpty {
                EmptyMeshChatView(meshManager: meshManager)
            } else {
                MeshMessagesList(meshManager: meshManager)
            }
            
            // Minimal input
            MessageInputSection(
                newMessage: $newMessage,
                meshManager: meshManager,
                showingEmergencyAlert: $showingEmergencyAlert,
                onSend: handleSendMessage
            )
        }
        .background(Color(.systemBackground))
        .alert("Emergency Message", isPresented: $showingEmergencyAlert) {
            Button("Send Emergency", role: .destructive) {
                sendEmergencyMessage()
            }
            Button("Send Normal", role: .cancel) {
                sendNormalMessage()
            }
        } message: {
            Text("This message contains emergency keywords. Would you like to send it as a priority emergency broadcast?")
        }
        .alert("Message Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func handleSendMessage() {
        let trimmedMessage = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Input validation
        guard !trimmedMessage.isEmpty else { return }
        
        guard trimmedMessage.count <= 500 else {
            errorMessage = "Message is too long. Please keep messages under 500 characters."
            showingError = true
            return
        }
        
        if isEmergencyMessage(trimmedMessage) {
            showingEmergencyAlert = true
        } else {
            sendNormalMessage()
        }
    }
    
    private func isEmergencyMessage(_ message: String) -> Bool {
        let emergencyKeywords = ["emergency", "help", "urgent", "danger", "911", "sos", "fire", "medical", "police"]
        let lowercased = message.lowercased()
        return emergencyKeywords.contains { lowercased.contains($0) }
    }
    
    private func sendEmergencyMessage() {
        let message = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        meshManager.sendEmergencyBroadcast(message)
        newMessage = ""
    }
    
    private func sendNormalMessage() {
        let message = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        meshManager.sendMessage(message)
        newMessage = ""
    }
}

// MARK: - Minimal Empty Chat
struct MinimalEmptyChat: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            MinimalEmptyState(
                icon: "message",
                title: "No messages",
                subtitle: "Connect with nearby users to start chatting"
            )
            Spacer()
        }
    }
}

// MARK: - Minimal Message Bubble
struct MinimalMessageBubble: View {
    let message: SafeGuardianMessage
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 2) {
                if !isFromCurrentUser {
                    Text(message.sender)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                
                Text(message.content)
                    .font(.system(size: 15, weight: .regular, design: .default))
                    .foregroundStyle(isFromCurrentUser ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isFromCurrentUser ? Color.blue : Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                Text(message.timestamp, style: .time)
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            if !isFromCurrentUser {
                Spacer(minLength: 50)
            }
        }
    }
}

// MARK: - Minimal Message Input
struct MinimalMessageInput: View {
    @Binding var text: String
    let isConnected: Bool
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("Message", text: $text)
                .font(.system(size: 15, weight: .regular, design: .default))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .disabled(!isConnected)
                .onSubmit(onSend)
            
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(canSend ? .blue : .gray)
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }
    
    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && isConnected
    }
}

struct MessageBubbleView: View {
    let message: SafeGuardianMessage
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isCurrentUser {
                    Text(message.sender)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(isCurrentUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(isCurrentUser ? .white : .primary)
                    .cornerRadius(18)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !isCurrentUser {
                Spacer()
            }
        }
    }
}

#Preview {
    MeshChatView()
}
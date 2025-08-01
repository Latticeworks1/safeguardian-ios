import SwiftUI

struct MeshChatView: View {
    @StateObject private var meshManager = SafeGuardianMeshManager()
    @State private var newMessage = ""
    @State private var showingEmergencyAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
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
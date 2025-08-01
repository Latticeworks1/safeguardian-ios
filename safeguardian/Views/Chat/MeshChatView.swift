import SwiftUI

struct MeshChatView: View {
    @StateObject private var meshManager = SafeGuardianMeshManager()
    @State private var newMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Connection Status Bar
                HStack {
                    Circle()
                        .fill(meshManager.isConnected ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                    
                    Text(meshManager.isConnected ? "Connected" : "Offline")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    if meshManager.isConnected {
                        Text("• \(meshManager.connectedPeers.count) peers")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(meshManager.getNetworkQuality().description)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(meshManager.getNetworkQuality().color).opacity(0.2))
                        .cornerRadius(8)
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Messages Area
                if meshManager.messages.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "message.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("No messages yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Start chatting with nearby SafeGuardian users through the mesh network")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    Spacer()
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(meshManager.messages, id: \.id) { message in
                                    MessageBubbleView(
                                        message: message,
                                        isCurrentUser: message.sender == meshManager.nickname
                                    )
                                    .id(message.id)
                                }
                            }
                            .padding()
                        }
                        .onChange(of: meshManager.messages.count) { _, _ in
                            if let lastMessage = meshManager.messages.last {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                
                // Message Input
                HStack {
                    TextField("Type a message...", text: $newMessage)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(!meshManager.isConnected)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(newMessage.isEmpty ? Color.gray : Color.blue)
                            .clipShape(Circle())
                    }
                    .disabled(newMessage.isEmpty || !meshManager.isConnected)
                }
                .padding()
            }
            .navigationTitle("Mesh Chat")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // BitChat automatically starts scanning for peers
                print("SafeGuardian mesh chat initialized")
            }
        }
    }
    
    private func sendMessage() {
        guard !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let trimmedMessage = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for emergency messages
        if meshManager.isEmergencyMessage(trimmedMessage) {
            meshManager.sendEmergencyBroadcast(trimmedMessage)
        } else {
            meshManager.sendMessage(trimmedMessage)
        }
        
        newMessage = ""
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
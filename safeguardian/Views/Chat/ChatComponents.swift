import SwiftUI

// MARK: - Connection Status Bar
struct ConnectionStatusBar: View {
    let status: ConnectionStatus
    let peerCount: Int
    let signalStrength: SignalStrength?
    let lastConnectionTime: Date?
    @State private var isAnimating = false
    
    init(status: ConnectionStatus, peerCount: Int = 0, signalStrength: SignalStrength? = nil, lastConnectionTime: Date? = nil) {
        self.status = status
        self.peerCount = peerCount
        self.signalStrength = signalStrength
        self.lastConnectionTime = lastConnectionTime
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Connection status indicator with animation
            HStack(spacing: 6) {
                Circle()
                    .fill(status.color)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isAnimating && (isConnectingState) ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                
                Text(status.description)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            
            // Signal strength indicator
            if let signalStrength = signalStrength {
                HStack(spacing: 4) {
                    Image(systemName: signalStrength.icon)
                        .font(.caption2)
                        .foregroundStyle(signalStrength.color)
                    
                    Text(signalStrength.description)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            // Peer count and connection info
            HStack(spacing: 6) {
                if peerCount > 0 {
                    Image(systemName: "person.2.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Text(status.deviceCount(peerCount: peerCount))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            // Last connection time for offline status
            if case .offline = status, let lastTime = lastConnectionTime {
                Text("Last: \(formatRelativeTime(lastTime))")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .onAppear {
            // Start animation for connecting states
            isAnimating = isConnectingState
        }
        .onChange(of: status) { _, _ in
            isAnimating = isConnectingState
        }
    }
    
    private var isConnectingState: Bool {
        switch status {
        case .searching:
            return true
        default:
            return false
        }
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

// MARK: - Empty Messages View
struct EmptyMessagesView: View {
    let connectionStatus: ConnectionStatus
    let onRetryConnection: (() -> Void)?
    
    init(connectionStatus: ConnectionStatus = .offline, onRetryConnection: (() -> Void)? = nil) {
        self.connectionStatus = connectionStatus
        self.onRetryConnection = onRetryConnection
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Status-specific icon
            Image(systemName: statusIcon)
                .font(.system(size: 64))
                .foregroundStyle(statusIconColor)
                .symbolEffect(.pulse, options: .repeating, value: isConnecting)
            
            VStack(spacing: 12) {
                Text(statusTitle)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                
                Text(statusMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            // Action buttons based on status
            if showActionButton {
                Button(action: {
                    onRetryConnection?()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: actionButtonIcon)
                            .font(.callout)
                        Text(actionButtonText)
                            .font(.callout.weight(.medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(actionButtonColor)
                    )
                }
                .buttonStyle(.plain)
            }
            
            // Safety tips
            if case .offline = connectionStatus {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "shield.checkered")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Text("Safety Tip")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                    
                    Text("In emergency situations, always contact 911 first. Mesh networks can supplement but not replace official emergency services.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.orange.opacity(0.1))
                        .stroke(.orange.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
    
    private var statusIcon: String {
        switch connectionStatus {
        case .offline: return "network.slash"
        case .searching: return "magnifyingglass"
        case .connecting: return "dot.radiowaves.left.and.right"
        case .online: return "message.circle.fill"
        }
    }
    
    private var statusIconColor: Color {
        switch connectionStatus {
        case .offline: return .red
        case .searching: return .orange
        case .connecting: return .green
        case .online: return .blue
        }
    }
    
    private var statusTitle: String {
        switch connectionStatus {
        case .offline: return "No Connection"
        case .searching: return "Searching for Peers"
        case .connecting: return "Connecting..."
        case .online: return "Ready to Chat"
        }
    }
    
    private var statusMessage: String {
        switch connectionStatus {
        case .offline: 
            return "Unable to connect to mesh network or internet. Check your device settings and try again."
        case .searching: 
            return "Looking for nearby devices to connect with. Make sure others have the app open and are nearby."
        case .connecting: 
            return "Connecting to mesh network..."
        case .online: 
            return "Connected to the internet and ready for enhanced communication features."
        }
    }
    
    private var showActionButton: Bool {
        switch connectionStatus {
        case .offline: return onRetryConnection != nil
        case .searching: return false
        case .connecting, .online: return false
        }
    }
    
    private var actionButtonText: String {
        "Retry Connection"
    }
    
    private var actionButtonIcon: String {
        "arrow.clockwise"
    }
    
    private var actionButtonColor: Color {
        .blue
    }
    
    private var isConnecting: Bool {
        switch connectionStatus {
        case .searching: return true
        default: return false
        }
    }
}

// MARK: - Message Input Bar
struct MessageInputBar: View {
    @Binding var text: String
    let onSend: () -> Void
    let isConnected: Bool
    @State private var showCommandSuggestions = false
    @State private var commandSuggestions: [CommandSuggestion] = []
    @FocusState private var isTextFieldFocused: Bool
    
    init(text: Binding<String>, isConnected: Bool = true, onSend: @escaping () -> Void) {
        self._text = text
        self.onSend = onSend
        self.isConnected = isConnected
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Command suggestions
            if showCommandSuggestions && !commandSuggestions.isEmpty {
                CommandSuggestionsView(
                    suggestions: commandSuggestions,
                    onSelect: { command in
                        text = command.command + " "
                        showCommandSuggestions = false
                        commandSuggestions = []
                    }
                )
            }
            
            // Input bar
            HStack(spacing: 12) {
                // Text input
                HStack(spacing: 8) {
                    TextField(inputPlaceholder, text: $text)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .focused($isTextFieldFocused)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onSubmit {
                            if isValidInput {
                                onSend()
                            }
                        }
                        .onChange(of: text) { _, newValue in
                            updateCommandSuggestions(for: newValue)
                        }
                    
                    // Character count for long messages
                    if text.count > 200 {
                        Text("\(text.count)/500")
                            .font(.caption2)
                            .foregroundStyle(text.count > 500 ? .red : .secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.quaternary.opacity(0.3))
                        .stroke(.quaternary, lineWidth: isTextFieldFocused ? 1 : 0)
                )
                
                // Send button
                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(sendButtonColor)
                        .scaleEffect(isValidInput ? 1.0 : 0.8)
                        .animation(.easeInOut(duration: 0.15), value: isValidInput)
                }
                .disabled(!isValidInput)
                .accessibilityLabel("Send message")
                .accessibilityHint(isValidInput ? "Double tap to send" : "Enter a message to send")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
        .onAppear {
            // Auto-focus text field with delay to avoid constraint warnings
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTextFieldFocused = true
            }
        }
    }
    
    private var inputPlaceholder: String {
        if !isConnected {
            return "Connect to send messages..."
        }
        return "Message neighbors..."
    }
    
    private var isValidInput: Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 500 && isConnected
    }
    
    private var sendButtonColor: Color {
        if !isConnected {
            return .secondary
        }
        return isValidInput ? .blue : .secondary
    }
    
    private func updateCommandSuggestions(for input: String) {
        guard input.hasPrefix("/") && input.count >= 1 else {
            showCommandSuggestions = false
            commandSuggestions = []
            return
        }
        
        let availableCommands: [CommandSuggestion] = [
            CommandSuggestion(command: "/help", description: "Show available commands"),
            CommandSuggestion(command: "/status", description: "Show connection status"),
            CommandSuggestion(command: "/clear", description: "Clear chat messages"),
            CommandSuggestion(command: "/ping", description: "Test connection to peers"),
            CommandSuggestion(command: "/emergency", description: "Send emergency alert")
        ]
        
        let filtered = availableCommands.filter { 
            $0.command.lowercased().hasPrefix(input.lowercased()) 
        }
        
        commandSuggestions = filtered
        showCommandSuggestions = !filtered.isEmpty
    }
}

// MARK: - Command Suggestion
struct CommandSuggestion: Identifiable {
    let id = UUID()
    let command: String
    let description: String
}

// MARK: - Command Suggestions View
struct CommandSuggestionsView: View {
    let suggestions: [CommandSuggestion]
    let onSelect: (CommandSuggestion) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(suggestions) { suggestion in
                Button(action: {
                    onSelect(suggestion)
                }) {
                    HStack(spacing: 12) {
                        Text(suggestion.command)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        
                        Text(suggestion.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .background(Color.secondary.opacity(0.1))
                
                if suggestion.id != suggestions.last?.id {
                    Divider()
                }
            }
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isCurrentUser { 
                Spacer(minLength: 50) 
            }
            
            VStack(alignment: message.isCurrentUser ? .trailing : .leading, spacing: 4) {
                // Sender name for received messages
                if !message.isCurrentUser {
                    HStack(spacing: 4) {
                        Text(message.sender)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                        
                        // Show if user is mentioned
                        if let mentions = message.mentions, !mentions.isEmpty {
                            Image(systemName: "at")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                
                // Message content
                HStack(alignment: .bottom, spacing: 8) {
                    Text(message.text)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(bubbleBackgroundColor)
                        )
                        .foregroundStyle(bubbleTextColor)
                        .textSelection(.enabled)
                    
                    // Delivery status for sent messages
                    if message.isCurrentUser, let deliveryStatus = message.deliveryStatus {
                        DeliveryStatusIndicator(status: deliveryStatus)
                            .padding(.bottom, 2)
                    }
                }
                
                // Timestamp
                HStack(spacing: 4) {
                    if message.isCurrentUser { Spacer() }
                    
                    Text(formatMessageTime(message.timestamp))
                        .font(.caption2)
                        .foregroundStyle(.quaternary)
                    
                    if !message.isCurrentUser { Spacer() }
                }
            }
            
            if !message.isCurrentUser { 
                Spacer(minLength: 50) 
            }
        }
        .padding(.horizontal, 4)
    }
    
    private var bubbleBackgroundColor: Color {
        if message.isCurrentUser {
            return .blue
        } else {
            return colorScheme == .dark ? 
                Color.secondary.opacity(0.3) : 
                Color.secondary.opacity(0.15)
        }
    }
    
    private var bubbleTextColor: Color {
        if message.isCurrentUser {
            return .white
        } else {
            return .primary
        }
    }
    
    private func formatMessageTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

// MARK: - Delivery Status Indicator
struct DeliveryStatusIndicator: View {
    let status: MessageDeliveryStatus
    
    var body: some View {
        Image(systemName: status.icon)
            .font(.caption2)
            .foregroundStyle(status.iconColor)
    }
}

#Preview {
    VStack(spacing: 16) {
        // Connection status examples
        ConnectionStatusBar(
            status: .online, 
            peerCount: 3, 
            signalStrength: .good
        )
        
        ConnectionStatusBar(
            status: .searching, 
            peerCount: 0
        )
        
        ConnectionStatusBar(
            status: .offline, 
            peerCount: 0, 
            lastConnectionTime: Date().addingTimeInterval(-3600)
        )
        
        Divider()
        
        // Message examples
        MessageBubble(message: ChatMessage(
            text: "Hello everyone! How is everyone doing today?", 
            sender: "John", 
            isCurrentUser: false,
            senderPeerID: "peer123",
            mentions: ["Sarah"]
        ))
        
        MessageBubble(message: ChatMessage(
            text: "Hi there! I'm doing well, thanks for asking.", 
            sender: "You", 
            isCurrentUser: true,
            senderPeerID: "local",
            mentions: nil
        ))
        
        Divider()
        
        // Empty state examples
        EmptyMessagesView(connectionStatus: .offline) {
            print("Retry connection tapped")
        }
    }
    .padding()
}

// MARK: - Mesh Chat Specific Components

// MARK: - Mesh Connection Status Section
struct MeshConnectionStatusSection: View {
    @ObservedObject var meshManager: SafeGuardianMeshManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Connection status indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(connectionStatusColor)
                    .frame(width: 10, height: 10)
                
                Text(connectionStatusText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
            }
            
            // Network quality indicator
            HStack(spacing: 4) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.caption)
                    .foregroundStyle(networkQualityColor)
                
                Text(meshManager.getNetworkQuality().description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Peer count
            if meshManager.isConnected {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("\(meshManager.connectedPeers.count)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }
    
    private var connectionStatusColor: Color {
        meshManager.isConnected ? .green : .red
    }
    
    private var connectionStatusText: String {
        meshManager.isConnected ? "Connected" : "Offline"
    }
    
    private var networkQualityColor: Color {
        switch meshManager.getNetworkQuality().color {
        case "green": return .green
        case "yellow": return .yellow  
        case "orange": return .orange
        default: return .red
        }
    }
}

// MARK: - Empty Mesh Chat View
struct EmptyMeshChatView: View {
    @ObservedObject var meshManager: SafeGuardianMeshManager
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Status icon
            Image(systemName: meshManager.isConnected ? "message.circle.fill" : "network.slash")
                .font(.system(size: 60))
                .foregroundStyle(meshManager.isConnected ? .blue : .secondary)
                .symbolEffect(.pulse, options: .repeating, value: !meshManager.isConnected)
            
            VStack(spacing: 12) {
                Text(meshManager.isConnected ? "Ready to Chat" : "No Connection")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                
                Text(emptyStateMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    private var emptyStateMessage: String {
        if meshManager.isConnected {
            return "You're connected to \(meshManager.connectedPeers.count) peer\(meshManager.connectedPeers.count == 1 ? "" : "s"). Start a conversation!"
        } else {
            return "Connect to the mesh network to chat with nearby SafeGuardian users even without internet."
        }
    }
}

// MARK: - Mesh Messages List
struct MeshMessagesList: View {
    @ObservedObject var meshManager: SafeGuardianMeshManager
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(meshManager.messages, id: \.id) { message in
                        EnhancedMessageBubble(
                            message: message,
                            isCurrentUser: message.sender == meshManager.nickname,
                            meshManager: meshManager
                        )
                        .id(message.id)
                    }
                }
                .padding()
            }
            .onChange(of: meshManager.messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = meshManager.messages.last {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

// MARK: - Enhanced Message Bubble with Delivery Status
struct EnhancedMessageBubble: View {
    let message: SafeGuardianMessage
    let isCurrentUser: Bool
    let meshManager: SafeGuardianMeshManager
    @State private var showDetailedStatus = false
    
    var body: some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 6) {
            HStack {
                if isCurrentUser {
                    Spacer()
                }
                
                VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                    // Sender name for received messages
                    if !isCurrentUser && !message.sender.isEmpty {
                        Text(message.sender)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    
                    // Message content with context menu
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(messageBackgroundColor)
                        .foregroundStyle(messageTextColor)
                        .cornerRadius(18)
                        .contextMenu {
                            Button(action: {
                                showDetailedStatus.toggle()
                            }) {
                                Label("Message Details", systemImage: "info.circle")
                            }
                            
                            if isCurrentUser && message.deliveryStatus?.needsRetry == true {
                                Button(action: {
                                    meshManager.retryMessage(message.id)
                                }) {
                                    Label("Retry Send", systemImage: "arrow.clockwise")
                                }
                            }
                            
                            Button(action: {
                                // Copy message logic would go here
                                UIPasteboard.general.string = message.content
                            }) {
                                Label("Copy Message", systemImage: "doc.on.doc")
                            }
                        }
                    
                    // Message metadata
                    HStack(spacing: 4) {
                        Text(message.timestamp, style: .time)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        
                        // Enhanced delivery status for sent messages
                        if isCurrentUser, let deliveryStatus = message.deliveryStatus {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showDetailedStatus.toggle()
                                }
                            }) {
                                VStack(alignment: .trailing, spacing: 1) {
                                    SafeGuardianDeliveryStatusIcon(status: deliveryStatus)
                                    
                                    // Show brief delivery info
                                    if case .delivered(let to, _) = deliveryStatus {
                                        Text("to \(to)")
                                            .font(.system(size: 8, weight: .medium, design: .rounded))
                                            .foregroundStyle(.tertiary)
                                    } else if case .read(let by, _) = deliveryStatus {
                                        Text("read by \(by)")
                                            .font(.system(size: 8, weight: .medium, design: .rounded))
                                            .foregroundStyle(.tertiary)
                                    } else if case .failed(_) = deliveryStatus {
                                        Text("tap to retry")
                                            .font(.system(size: 8, weight: .medium, design: .rounded))
                                            .foregroundStyle(.orange)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Priority emergency indicator
                        if isEmergencyMessage(message.content) {
                            HStack(spacing: 2) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                                Text("PRIORITY")
                                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.red)
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(.red.opacity(0.1), in: Capsule())
                        }
                    }
                }
                
                if !isCurrentUser {
                    Spacer()
                }
            }
            
            // Expandable detailed status
            if showDetailedStatus {
                MessageStatusDetailView(message: message)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 0.8).combined(with: .opacity)
                    ))
            }
        }
    }
    
    private var messageBackgroundColor: Color {
        if isEmergencyMessage(message.content) {
            return .red
        }
        return isCurrentUser ? .blue : Color(.systemGray5)
    }
    
    private var messageTextColor: Color {
        if isEmergencyMessage(message.content) {
            return .white
        }
        return isCurrentUser ? .white : .primary
    }
    
    private func isEmergencyMessage(_ content: String) -> Bool {
        let emergencyKeywords = ["emergency", "help", "urgent", "danger", "911", "sos"]
        return emergencyKeywords.contains { content.lowercased().contains($0) }
    }
}

// MARK: - Enhanced SafeGuardian Delivery Status Icon
struct SafeGuardianDeliveryStatusIcon: View {
    let status: SafeGuardianDeliveryStatus
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: iconName)
                .font(.caption2)
                .foregroundStyle(iconColor)
                .scaleEffect(isAnimating && shouldAnimate ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
            
            if showProgress {
                Text(progressText)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            isAnimating = shouldAnimate
        }
        .onChange(of: status) { _, _ in
            isAnimating = shouldAnimate
        }
    }
    
    private var iconName: String {
        switch status {
        case .sending:
            return "clock.arrow.circlepath"
        case .sent:
            return "paperplane.fill"
        case .delivered(_, _):
            return "checkmark.circle.fill"
        case .read(_, _):
            return "eye.circle.fill"
        case .failed(_):
            return "exclamationmark.triangle.fill"
        case .partiallyDelivered(let reached, let total):
            return reached > total / 2 ? "checkmark.circle.badge.questionmark" : "clock.badge.questionmark"
        }
    }
    
    private var iconColor: Color {
        switch status {
        case .sending:
            return .orange
        case .sent:
            return .blue
        case .delivered(_, _):
            return .green
        case .read(_, _):
            return .cyan
        case .failed(_):
            return .red
        case .partiallyDelivered(let reached, let total):
            return reached > total / 2 ? .yellow : .orange
        }
    }
    
    private var shouldAnimate: Bool {
        switch status {
        case .sending:
            return true
        case .failed(_):
            return true
        default:
            return false
        }
    }
    
    private var showProgress: Bool {
        switch status {
        case .partiallyDelivered(_, _):
            return true
        default:
            return false
        }
    }
    
    private var progressText: String {
        switch status {
        case .partiallyDelivered(let reached, let total):
            return "\(reached)/\(total)"
        default:
            return ""
        }
    }
}

// MARK: - Message Input Section
struct MessageInputSection: View {
    @Binding var newMessage: String
    @ObservedObject var meshManager: SafeGuardianMeshManager
    @Binding var showingEmergencyAlert: Bool
    let onSend: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Emergency warning banner
            if isEmergencyMessage && !newMessage.isEmpty {
                EmergencyMessageWarning()
            }
            
            // Input area
            HStack(spacing: 12) {
                TextField("Type a message...", text: $newMessage, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                
                Button(action: onSend) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(sendButtonColor, in: Circle())
                }
                .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(.regularMaterial)
        }
    }
    
    private var isEmergencyMessage: Bool {
        let lowercased = newMessage.lowercased()
        return lowercased.contains("emergency") || lowercased.contains("help") || 
               lowercased.contains("urgent") || lowercased.contains("danger")
    }
    
    private var sendButtonColor: Color {
        if newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .gray
        }
        return isEmergencyMessage ? .red : .blue
    }
}

// MARK: - Emergency Message Warning
struct EmergencyMessageWarning: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.red)
            
            Text("Emergency message detected - will be sent as priority broadcast")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.red.opacity(0.1))
    }
}

// MARK: - Advanced Message Status Detail View
struct MessageStatusDetailView: View {
    let message: SafeGuardianMessage
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Text("Message Details")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    // Message ID
                    DetailRow(label: "ID", value: String(message.id.prefix(8)) + "...")
                    
                    // Sender info
                    if let senderPeerID = message.senderPeerID {
                        DetailRow(label: "Peer ID", value: String(senderPeerID.prefix(8)) + "...")
                    }
                    
                    // Delivery status details
                    if let deliveryStatus = message.deliveryStatus {
                        DetailRow(label: "Status", value: deliveryStatusDescription(deliveryStatus))
                    }
                    
                    // Relay info
                    if message.isRelay, let originalSender = message.originalSender {
                        DetailRow(label: "Relayed from", value: originalSender)
                    }
                    
                    // Emergency indicator
                    if isEmergencyMessage(message.content) {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundStyle(.red)
                            Text("Emergency Message")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.red)
                        }
                    }
                    
                    // Network quality at time of sending
                    HStack(spacing: 4) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("Mesh quality: Good") // This would come from actual network quality
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    private func deliveryStatusDescription(_ status: SafeGuardianDeliveryStatus) -> String {
        switch status {
        case .sending:
            return "Sending via mesh..."
        case .sent:
            return "Sent to mesh network"
        case .delivered(let to, let at):
            return "Delivered to \\(to) at \\(DateFormatter.timeFormatter.string(from: at))"
        case .read(let by, let at):
            return "Read by \\(by) at \\(DateFormatter.timeFormatter.string(from: at))"
        case .failed(let reason):
            return "Failed: \\(reason)"
        case .partiallyDelivered(let reached, let total):
            return "Delivered to \\(reached) of \\(total) peers"
        }
    }
    
    private func isEmergencyMessage(_ content: String) -> Bool {
        let emergencyKeywords = ["emergency", "help", "urgent", "danger", "911", "sos"]
        return emergencyKeywords.contains { content.lowercased().contains($0) }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.tertiary)
            
            Spacer()
            
            Text(value)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Connection Quality Indicator
struct ConnectionQualityIndicator: View {
    @ObservedObject var meshManager: SafeGuardianMeshManager
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: qualityIcon)
                .font(.caption)
                .foregroundStyle(qualityColor)
            
            Text("\(meshManager.connectedPeers.count)")
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(qualityColor.opacity(0.1), in: Capsule())
    }
    
    private var qualityIcon: String {
        let quality = meshManager.getNetworkQuality()
        switch quality {
        case .offline:
            return "antenna.radiowaves.left.and.right.slash"
        case .poor:
            return "antenna.radiowaves.left.and.right"
        case .good:
            return "antenna.radiowaves.left.and.right"
        case .excellent:
            return "antenna.radiowaves.left.and.right"
        }
    }
    
    private var qualityColor: Color {
        let quality = meshManager.getNetworkQuality()
        switch quality.color {
        case "green": return .green
        case "yellow": return .yellow  
        case "orange": return .orange
        default: return .red
        }
    }
}

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

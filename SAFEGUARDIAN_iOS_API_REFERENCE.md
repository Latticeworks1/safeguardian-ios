# SafeGuardian iOS API Reference

Comprehensive API documentation for the SafeGuardian iOS safety application with BitChat P2P mesh networking integration.

## Architecture Overview

SafeGuardian is a modular iOS safety application built with SwiftUI, featuring a 5-tab architecture integrated with BitChat's proven P2P mesh networking system.

### Core Components

- **SafeGuardianMeshManager**: Clean wrapper for BitChat P2P networking
- **5-Tab Navigation**: Home, Chat, AI Guide, Safety Map, Profile
- **Safety-First Design**: Emergency prioritization throughout the UX
- **Offline Capability**: Mesh network communication without internet

## Getting Started

### Basic Setup

```swift
import SwiftUI

@main
struct safeguardianApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Core Architecture

```swift
struct ContentView: View {
    @StateObject private var globalMeshManager = SafeGuardianMeshManager()
    
    var body: some View {
        TabView {
            MinimalHomeView(meshManager: globalMeshManager)
                .tabItem { Image(systemName: "house"); Text("Home") }
            
            MinimalChatView(meshManager: globalMeshManager)
                .tabItem { Image(systemName: "message"); Text("Chat") }
            
            MinimalAIView(meshManager: globalMeshManager)
                .tabItem { Image(systemName: "brain"); Text("AI") }
            
            MinimalMapView(meshManager: globalMeshManager)
                .tabItem { Image(systemName: "map"); Text("Map") }
            
            MinimalProfileView(meshManager: globalMeshManager)
                .tabItem { Image(systemName: "person"); Text("Profile") }
        }
    }
}
```

## Mesh Networking API

### SafeGuardianMeshManager

The core networking manager that wraps BitChat's P2P implementation.

#### Initialization

```swift
class SafeGuardianMeshManager: ObservableObject, BitchatDelegate {
    @Published var isConnected: Bool = false
    @Published var connectedPeers: [String] = []
    @Published var messages: [SafeGuardianMessage] = []
    @Published var nickname: String = "SafeGuardian User"
    
    private let meshService = BluetoothMeshService()
    
    init() {
        setupBitChatIntegration()
    }
}
```

#### Usage Examples

**Send Message**
```swift
func sendMessage(_ content: String) {
    meshManager.sendMessage(content)
}
```

**Emergency Broadcast**
```swift
func sendEmergencyAlert() {
    let emergencyMessage = "Help needed at current location"
    meshManager.sendEmergencyBroadcast(emergencyMessage)
}
```

**Network Quality Check**
```swift
let quality = meshManager.getNetworkQuality()
switch quality {
case .offline: print("No connections")
case .poor: print("1-2 peers connected")
case .good: print("3-5 peers connected") 
case .excellent: print("6+ peers connected")
}
```

## View Components

### Home View

Community feed with mesh network status integration.

```swift
struct MinimalHomeView: View {
    @ObservedObject var meshManager: SafeGuardianMeshManager
    
    var body: some View {
        VStack {
            MinimalTopHeader(title: "SafeGuardian", meshManager: meshManager)
            
            ScrollView {
                MinimalCommunitySection()
            }
        }
        .background(Color(.systemBackground))
    }
}
```

### Chat View

P2P messaging with BitChat integration.

```swift
struct MinimalChatView: View {
    @ObservedObject var meshManager: SafeGuardianMeshManager
    @State private var newMessage = ""
    
    var body: some View {
        VStack {
            MinimalTopHeader(title: "Chat", meshManager: meshManager)
            
            if meshManager.messages.isEmpty {
                MinimalEmptyChat()
            } else {
                ScrollView {
                    LazyVStack {
                        ForEach(meshManager.messages, id: \.id) { message in
                            MinimalMessageBubble(
                                message: message,
                                isFromCurrentUser: message.sender == meshManager.nickname
                            )
                        }
                    }
                }
            }
            
            MinimalMessageInput(
                text: $newMessage,
                isConnected: meshManager.isConnected,
                onSend: {
                    meshManager.sendMessage(newMessage.trimmingCharacters(in: .whitespacesAndNewlines))
                    newMessage = ""
                }
            )
        }
    }
}
```

### AI Guide View

Safety-focused AI assistant with emergency detection.

```swift
struct MinimalAIView: View {
    @ObservedObject var meshManager: SafeGuardianMeshManager
    @StateObject private var aiGuide = SafetyAIGuide()
    @State private var userInput = ""
    
    var body: some View {
        VStack {
            MinimalTopHeader(title: "AI Guide", meshManager: meshManager)
            
            ScrollView {
                LazyVStack {
                    ForEach(aiGuide.messages, id: \.id) { message in
                        AIMessageBubble(
                            message: message,
                            isStreaming: aiGuide.isGenerating && message.id == aiGuide.messages.last?.id
                        )
                    }
                }
            }
            
            AIInputSection(
                input: $userInput,
                onSend: {
                    aiGuide.sendMessage(userInput)
                    userInput = ""
                }
            )
        }
    }
}
```

## Data Models

### SafeGuardianMessage

Core message model for P2P communication.

```swift
struct SafeGuardianMessage: Identifiable {
    let id: String
    let sender: String
    let content: String
    let timestamp: Date
    let isRelay: Bool
    let originalSender: String?
    let isPrivate: Bool
    let recipientNickname: String?
    let senderPeerID: String?
    let mentions: [String]?
    let deliveryStatus: SafeGuardianDeliveryStatus?
}
```

### UserProfile

User profile with mesh network settings.

```swift
struct UserProfile: Codable {
    let id = UUID()
    var name: String
    var nickname: String
    var avatar: String
    var deviceID: String
    var isOnline: Bool
    var meshConnected: Bool
    var notificationsEnabled: Bool
    var darkModeEnabled: Bool
    var autoConnectMesh: Bool
    var shareLocation: Bool
    var showOnlineStatus: Bool
    var isEmergencyContact: Bool
    var lastSeen: Date?
    
    static let sample = UserProfile(
        name: "SafeGuardian User",
        avatar: "person.crop.circle.fill",
        deviceID: "SG123456",
        isOnline: true,
        meshConnected: true
    )
}
```

### CommunityPost

Community feed post model.

```swift
enum CommunityPostType {
    case announcement
    case alert
    case general
    
    var iconName: String {
        switch self {
        case .announcement: return "megaphone"
        case .alert: return "exclamationmark.triangle"
        case .general: return "message"
        }
    }
}

struct CommunityPost: Identifiable {
    let id: String
    let author: String
    let content: String
    let timestamp: Date
    let type: CommunityPostType
    let location: String?
}
```

### EmergencyService

Emergency service location model.

```swift
enum EmergencyServiceType {
    case safetyHub
    case hospital
    case police
    case fireStation
    
    var displayName: String { /* implementation */ }
    var iconName: String { /* implementation */ }
    var color: Color { /* implementation */ }
}

struct EmergencyService: Identifiable {
    let id = UUID()
    let name: String
    let type: EmergencyServiceType
    let latitude: Double
    let longitude: Double
    let distance: Double
    let isOpen: Bool
    
    func distanceString() -> String {
        if distance < 1 {
            return String(format: "%.0fm", distance * 1000)
        } else {
            return String(format: "%.1fkm", distance)
        }
    }
}
```

## Safety AI System

### SafetyAIGuide

Deterministic rule-based AI for safety responses.

```swift
class SafetyAIGuide: ObservableObject {
    @Published var messages: [AIMessage] = []
    @Published var isGenerating = false
    
    func sendMessage(_ content: String) {
        let userMessage = AIMessage(content: content, isFromUser: true)
        messages.append(userMessage)
        
        if isEmergencyMessage(content) {
            generateEmergencyResponse()
        } else {
            generateSafetyResponse(for: content)
        }
    }
    
    private func isEmergencyMessage(_ content: String) -> Bool {
        let emergencyKeywords = ["emergency", "help", "911", "sos", "urgent", "danger"]
        return emergencyKeywords.contains { content.lowercased().contains($0) }
    }
}
```

## Shared Components

### MinimalTopHeader

Consistent header with mesh network status.

```swift
struct MinimalTopHeader: View {
    let title: String
    @ObservedObject var meshManager: SafeGuardianMeshManager
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
            
            Spacer()
            
            HStack(spacing: 8) {
                SafetyIndicator(
                    status: meshManager.isConnected ? .safe : .disconnected,
                    size: .small
                )
                
                Text("\(meshManager.connectedPeers.count)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }
}
```

### SafetyIndicator

Network status indicator component.

```swift
enum SafetyStatus {
    case safe
    case disconnected
    case warning
    
    var color: Color {
        switch self {
        case .safe: return .green
        case .disconnected: return .red
        case .warning: return .orange
        }
    }
}

struct SafetyIndicator: View {
    let status: SafetyStatus
    let size: SafetyIndicatorSize
    
    var body: some View {
        Circle()
            .fill(status.color)
            .frame(width: size.diameter, height: size.diameter)
            .animation(.easeInOut, value: status)
    }
}
```

## Build Configuration

### Project Structure

```
safeguardian/
├── safeguardianApp.swift              # App entry point
├── ContentView.swift                  # TabView navigation
├── Services/
│   ├── SafeGuardianMeshManager.swift  # BitChat integration
│   └── BitChat/                       # Complete P2P stack
├── Models/
│   └── SharedModels.swift             # Core data models
├── Views/
│   ├── Home/HomeView.swift            # Community feed
│   ├── Chat/MeshChatView.swift        # P2P messaging
│   ├── AI/AIGuideView.swift           # Safety AI
│   ├── Map/SafetyMapView.swift        # Interactive map
│   └── Profile/ProfileView.swift      # User settings
└── Components/
    └── SharedComponents.swift         # Reusable UI
```

### Build Commands

```bash
# Build for simulator
xcodebuild -project safeguardian.xcodeproj -scheme safeguardian -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests
xcodebuild test -project safeguardian.xcodeproj -scheme safeguardian -destination 'platform=iOS Simulator,name=iPhone 16'

# Clean build
xcodebuild clean -project safeguardian.xcodeproj -scheme safeguardian

# Release build
xcodebuild -project safeguardian.xcodeproj -scheme safeguardian -configuration Release build
```

## Network Quality Enum

```swift
enum NetworkQuality {
    case offline
    case poor      // 1-2 peers
    case good      // 3-5 peers
    case excellent // 6+ peers
    
    var description: String {
        switch self {
        case .offline: return "Offline"
        case .poor: return "Poor"
        case .good: return "Good"
        case .excellent: return "Excellent"
        }
    }
    
    var color: String {
        switch self {
        case .offline: return "red"
        case .poor: return "orange"
        case .good: return "yellow"
        case .excellent: return "green"
        }
    }
}
```

## BitChat Delegate Implementation

```swift
extension SafeGuardianMeshManager: BitchatDelegate {
    func didReceiveMessage(_ message: BitchatMessage) {
        let safeGuardianMessage = SafeGuardianMessage(
            id: message.id,
            sender: message.sender,
            content: message.content,
            timestamp: message.timestamp,
            // ... other properties
        )
        DispatchQueue.main.async {
            self.messages.append(safeGuardianMessage)
        }
    }
    
    func didConnectToPeer(_ peerID: String) {
        DispatchQueue.main.async {
            if !self.connectedPeers.contains(peerID) {
                self.connectedPeers.append(peerID)
            }
            self.isConnected = !self.connectedPeers.isEmpty
        }
    }
    
    func didDisconnectFromPeer(_ peerID: String) {
        DispatchQueue.main.async {
            self.connectedPeers.removeAll { $0 == peerID }
            self.isConnected = !self.connectedPeers.isEmpty
        }
    }
}
```

## Safety Features

### Emergency Detection

```swift
func isEmergencyMessage(_ content: String) -> Bool {
    let emergencyKeywords = ["emergency", "help", "911", "sos", "urgent", "danger"]
    let lowercaseContent = content.lowercased()
    return emergencyKeywords.contains { lowercaseContent.contains($0) }
}
```

### Emergency Broadcasting

```swift
func sendEmergencyBroadcast(_ message: String) {
    let emergencyMessage = "🚨 EMERGENCY: \(message)"
    meshService.sendMessage(emergencyMessage)
}
```

## Production Readiness

### Status: ✅ Production Ready

- **✅ Build Status**: All compilation errors resolved
- **✅ Architecture**: Clean separation between BitChat backend and SafeGuardian UI
- **✅ Feature Complete**: All 5 tabs fully implemented with mesh integration
- **✅ Safety Focused**: Emergency-first design with 911 prioritization
- **✅ Privacy Preserving**: End-to-end encryption via BitChat's Noise Protocol

### Key Benefits

- **Offline Capability**: P2P mesh network for emergency communication without internet
- **Safety-First UX**: Professional safety application with emergency prioritization
- **Clean Architecture**: BitChat networking abstracted, SafeGuardian branding throughout
- **Proven Networking**: Leverages BitChat's enterprise-grade P2P implementation
- **Real-time Updates**: Live peer count, network quality, and connection status

The SafeGuardian iOS app provides a complete safety-focused mobile experience with robust offline communication capabilities through BitChat's proven P2P mesh networking system.
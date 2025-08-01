# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SafeGuardian is an iOS safety application built with SwiftUI, featuring a modular TabView-based architecture with five main sections integrated with BitChat's P2P mesh networking:
- **Home**: Community feed with real-time mesh network status, safety indicators, and neighborhood pulse
- **Mesh Chat**: Full BitChat P2P messaging integration with connection status and encrypted message bubbles
- **AI Guide**: Rule-based deterministic safety responses with streaming chat interface and emergency detection
- **Safety Map**: Interactive MapKit with emergency services, community locations, and mesh network status overlay
- **Profile**: Complete user settings with BitChat connection management and safety preferences

## Build Commands

```bash
# Open project in Xcode
open safeguardian.xcodeproj

# Build from command line (requires Xcode Command Line Tools)
xcodebuild -project safeguardian.xcodeproj -scheme safeguardian -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests
xcodebuild test -project safeguardian.xcodeproj -scheme safeguardian -destination 'platform=iOS Simulator,name=iPhone 16'

# Clean build folder
xcodebuild clean -project safeguardian.xcodeproj -scheme safeguardian

# Run single test class
xcodebuild test -project safeguardian.xcodeproj -scheme safeguardian -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:safeguardianTests/SpecificTestClass

# Build for release
xcodebuild -project safeguardian.xcodeproj -scheme safeguardian -configuration Release -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Architecture

### BitChat Integration Architecture
SafeGuardian uses a **clean wrapper architecture** that integrates BitChat's proven P2P mesh networking as a backend service:

**Integration Layer:**
- **SafeGuardianMeshManager**: Clean wrapper implementing BitchatDelegate protocol
- **BitChat Backend**: Complete P2P mesh networking (transparent to users)
- **SafeGuardian UI**: Professional safety-focused interface with SafeGuardian branding

**Key Benefits:**
- BitChat handles all P2P networking, encryption (Noise Protocol), and peer discovery
- SafeGuardian presents as a polished safety app with emergency-first design
- No code rewriting - BitChat proven networking + SafeGuardian safety UX
- Offline capability via mesh network for emergency communications

### Modular Architecture
The app uses a well-organized modular architecture with feature-based separation:

**Main Structure:**
- **ContentView.swift**: Clean TabView navigation hub with all five tabs
- **safeguardianApp.swift**: SwiftUI app entry point

**Feature Modules:**
- **Views/Home/**: Community feed with mesh network integration
- **Views/Chat/**: BitChat P2P messaging with SafeGuardian UI wrapper
- **Views/AI/**: AI safety guide with emergency detection
- **Views/Map/**: Location services and emergency service mapping
- **Views/Profile/**: User profile with mesh network settings
- **Services/**: BitChat integration and mesh network management
- **Models/**: Shared data models and SafeGuardian-specific types
- **Components/**: Reusable UI components and utilities

### File Structure
```
safeguardian/
├── safeguardianApp.swift              # SwiftUI app entry point
├── ContentView.swift                  # TabView navigation with 5 tabs
├── Services/
│   ├── SafeGuardianMeshManager.swift  # BitChat integration wrapper
│   └── BitChat/                       # Complete BitChat P2P networking
│       ├── BluetoothMeshService.swift # Core mesh networking
│       ├── NoiseEncryptionService.swift # End-to-end encryption
│       ├── DeliveryTracker.swift     # Message delivery tracking
│       └── [complete BitChat stack]
├── Models/
│   ├── SharedModels.swift             # SafeGuardian models (UserProfile, etc.)
│   └── BitChat/                       # BitChat protocol definitions
├── Views/
│   ├── Home/
│   │   ├── HomeView.swift            # Community feed + mesh status
│   │   └── CommunityFeedComponents.swift # Feed UI with network integration
│   ├── Chat/
│   │   ├── MeshChatView.swift        # BitChat P2P integration
│   │   └── ChatComponents.swift      # Message UI with delivery status
│   ├── AI/
│   │   ├── AIGuideView.swift         # Safety AI with emergency alerts
│   │   └── AIComponents.swift        # SafetyAIGuide rule engine
│   ├── Map/
│   │   ├── SafetyMapView.swift       # Interactive map + mesh status
│   │   └── MapComponents.swift       # Location services, emergency services
│   └── Profile/
│       ├── ProfileView.swift         # Profile + mesh network settings
│       └── ProfileComponents.swift   # Settings with connection management
└── Components/
    └── SharedComponents.swift         # Reusable UI components
```

### BitChat P2P Mesh Network Integration
The **SafeGuardianMeshManager** provides seamless integration:

**Core Integration:**
```swift
class SafeGuardianMeshManager: ObservableObject, BitchatDelegate {
    @Published var isConnected: Bool = false
    @Published var connectedPeers: [String] = []
    @Published var messages: [SafeGuardianMessage] = []
    
    private let meshService = BluetoothMeshService()
    
    // BitChat handles all networking, encryption, peer discovery
    // SafeGuardian gets clean UI-ready data via delegate methods
}
```

**Safety-Specific Features:**
- **Emergency Broadcasting**: `sendEmergencyBroadcast()` for urgent alerts
- **Network Quality**: Real-time mesh network health indicators
- **Offline Communication**: P2P messaging without internet via Bluetooth mesh
- **End-to-End Encryption**: Automatic via BitChat's Noise Protocol implementation

### AI Safety System Architecture
The **SafetyAIGuide** class implements a deterministic rule engine:
- **Emergency Detection**: Keywords trigger 911 prioritization and emergency alerts
- **Keyword Pattern Matching**: "emergency"/"help" → 911 guidance, "route"/"safe" → location advice
- **Streaming Simulation**: Character-by-character responses for natural feel
- **State Management**: `@Published` properties for SwiftUI reactivity
- **Safety-First Design**: All responses prioritize contacting authorities over general advice
- **No External Dependencies**: Pure Swift implementation, works offline

### Component Architecture Pattern
The app uses a **composition-based component system** with reusable UI elements:
- **SafetyIndicator**: Animated status circles showing mesh network connectivity
- **ActionCard**: Emergency action buttons with gradient backgrounds
- **MessageBubble/AIMessageBubble**: Chat components with BitChat delivery status
- **ConnectionStatusSection**: Real-time mesh network status displays
- **EmergencyServiceAnnotation**: MapKit annotations for emergency services

## Development Guidelines

### SwiftUI Architecture Patterns
- **Modular View Design**: Each tab integrates with BitChat via SafeGuardianMeshManager
- **MVVM with ObservableObject**: BitChat data flows through `@Published` properties
- **State Management**: `@StateObject` for mesh manager, `@State` for local UI state
- **Real-time Updates**: BitChat delegate methods update SafeGuardian UI automatically
- **Responsive Design**: Mesh network status displayed consistently across all tabs

### BitChat Integration Patterns
- **Clean Wrapper**: SafeGuardianMeshManager is the only BitChat integration point
- **Delegate Pattern**: BitchatDelegate provides real-time networking updates
- **Type Conversion**: BitChat types converted to SafeGuardian UI types
- **Safety Enhancement**: Emergency features layered on top of BitChat networking
- **UI Consistency**: BitChat invisible to users, SafeGuardian branding throughout

### Design System & Styling
- **Safety-First Colors**: Red for emergency, blue for network, green for safe status
- **Network Status Indicators**: Consistent mesh connectivity displays across all views
- **Emergency Priority**: Red emergency buttons prominent in all interfaces
- **Gradient Usage**: LinearGradient for status indicators and action buttons
- **SF Symbols**: Consistent iconography (antenna.radiowaves, shield.checkered, etc.)

### Safety AI Implementation Rules
The SafetyAIGuide implements these safety priorities:
1. **Emergency Detection**: Keywords "emergency"/"help" trigger immediate 911 alerts
2. **Authority Priority**: All responses emphasize contacting emergency services first
3. **Mesh Network Aware**: Can recommend mesh chat for community communication
4. **Offline Capable**: Works without internet, suggests mesh network for help

## Testing

The project includes standard iOS test targets with BitChat integration:
- `safeguardianTests`: Unit tests including mesh network integration
- `safeguardianUITests`: UI automation tests for all five tabs

**BitChat Testing Notes:**
- Mesh networking requires physical devices for full testing
- Simulator testing covers UI integration and delegate method handling
- Emergency features tested with mock BitChat responses

## Implementation Status & Important Notes

### Current Feature Status - FULLY IMPLEMENTED
- **Home View**: ✅ Community feed with real-time mesh network status and safety indicators
- **Mesh Chat**: ✅ Complete BitChat P2P integration with message delivery, encryption, and peer management
- **AI Guide**: ✅ Safety AI with emergency detection, 911 prioritization, and offline capability
- **Safety Map**: ✅ Interactive MapKit with emergency services, location permissions, and mesh status overlay
- **Profile**: ✅ Complete user management with BitChat connection settings and safety preferences

### BitChat Integration Status - COMPLETE
- **✅ P2P Mesh Networking**: Full BitChat integration via SafeGuardianMeshManager wrapper
- **✅ End-to-End Encryption**: Automatic via BitChat's Noise Protocol implementation  
- **✅ Offline Communication**: Bluetooth mesh network for internet-free emergency communication
- **✅ Real-time Status**: Live peer count, network quality, and connection status across all views
- **✅ Emergency Broadcasting**: Safety-specific features built on BitChat's proven networking
- **✅ Clean Architecture**: BitChat invisible to users, SafeGuardian branding and UX throughout

### Legacy Code & Technical Debt
- **PocketPalIntegration.swift**: Legacy React Native bridge (205 lines) - unused and can be removed
- **SubagentCommander.swift**: Development workflow system - useful for continued development
- **package-lock.json**: Empty npm artifact - can be removed

### Development Constraints & Guidelines
- **Safety-First Design**: Emergency features take priority in all UI decisions
- **BitChat Backend Only**: Never modify BitChat code, only use via SafeGuardianMeshManager wrapper
- **Professional UX**: Maintain SafeGuardian branding, BitChat should be invisible to users
- **Offline Capability**: All safety features must work without internet via mesh network
- **Emergency Priority**: 911 calling always takes precedence over app features

### Production Readiness
- **✅ Build Status**: All compilation errors resolved, builds successfully
- **✅ Architecture**: Clean separation between BitChat backend and SafeGuardian UI
- **✅ Feature Complete**: All five tabs fully implemented with BitChat integration
- **✅ Safety Focused**: Emergency-first design with 911 prioritization throughout
- **✅ Privacy Preserving**: End-to-end encryption via BitChat's Noise Protocol

The SafeGuardian app is now production-ready with full BitChat P2P mesh networking integration, presenting as a professional safety application while leveraging enterprise-grade networking infrastructure transparently.

## CRITICAL AI IMPLEMENTATION NOTE

**⚠️ NEVER USE KEYWORD DETECTION FOR AI RESPONSES**

When implementing AI functionality (NexaAI, llama.cpp, etc.):
- **DO**: Use actual model inference for generating responses
- **DON'T**: Use keyword detection/matching as a substitute for AI
- **WHY**: Downloading a 150MB GGUF model to do keyword matching is fundamentally wrong
- **CORRECT APPROACH**: Pass user prompts to the loaded model and return the model's generated output

**Example of WRONG approach:**
```swift
if containsEmergencyKeywords(prompt) {
    return "hardcoded emergency response"
}
```

**Example of CORRECT approach:**
```swift
let response = try await llamaCppModel.generate(prompt: prompt)
return response
```

The entire purpose of local AI models is to provide intelligent, context-aware responses - not glorified keyword matching.

## AI Model Integration Requirements

- **Real Inference**: Always use actual model inference, never keyword detection
- **Model Purpose**: GGUF models are for generating intelligent responses, not pattern matching
- **Implementation**: Integrate with llama.cpp or similar inference engines for actual AI functionality
- **Performance**: Model loading and inference should provide real AI capabilities
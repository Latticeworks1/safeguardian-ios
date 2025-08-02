import Foundation
import SwiftUI

// MARK: - SafeGuardian Message Models
struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let sender: String
    let isCurrentUser: Bool
    let senderPeerID: String
    let mentions: [String]?
    let timestamp: Date
    var deliveryStatus: MessageDeliveryStatus?
    
    init(text: String, sender: String, isCurrentUser: Bool, senderPeerID: String, mentions: [String]? = nil, deliveryStatus: MessageDeliveryStatus? = nil) {
        self.text = text
        self.sender = sender
        self.isCurrentUser = isCurrentUser
        self.senderPeerID = senderPeerID
        self.mentions = mentions
        self.timestamp = Date()
        self.deliveryStatus = deliveryStatus
    }
}

enum MessageDeliveryStatus {
    case sending
    case sent
    case delivered(to: [String], at: Date)
    case failed(reason: String)
    
    var icon: String {
        switch self {
        case .sending: return "clock"
        case .sent: return "checkmark.circle"
        case .delivered: return "checkmark.circle.fill"
        case .failed: return "xmark.circle"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .sending: return .orange
        case .sent: return .blue
        case .delivered: return .green
        case .failed: return .red
        }
    }
}

// MARK: - Connection Status
enum ConnectionStatus {
    case online
    case offline
    case connecting
    case searching
    
    var color: Color {
        switch self {
        case .online: return .green
        case .offline: return .red
        case .connecting: return .orange
        case .searching: return .blue
        }
    }
    
    var description: String {
        switch self {
        case .online: return "Online"
        case .offline: return "Offline"
        case .connecting: return "Connecting"
        case .searching: return "Searching"
        }
    }
    
    func deviceCount(peerCount: Int) -> String {
        switch self {
        case .online, .connecting:
            return "\(peerCount) peer\(peerCount == 1 ? "" : "s") connected"
        case .offline:
            return "No connections"
        case .searching:
            return "Searching for peers..."
        }
    }
}

enum SignalStrength: CaseIterable {
    case weak
    case good
    case strong
    
    var icon: String {
        switch self {
        case .weak: return "wifi"
        case .good: return "wifi"
        case .strong: return "wifi"
        }
    }
    
    var color: Color {
        switch self {
        case .weak: return .red
        case .good: return .orange
        case .strong: return .green
        }
    }
    
    var description: String {
        switch self {
        case .weak: return "Weak"
        case .good: return "Good"
        case .strong: return "Strong"
        }
    }
}

// MARK: - User Profile
struct UserProfile: Codable {
    var id: UUID
    var name: String
    var nickname: String // For backward compatibility
    var avatar: String
    var deviceID: String
    
    init(name: String = "", nickname: String = "", avatar: String = "", deviceID: String = "") {
        self.id = UUID()
        self.name = name
        self.nickname = nickname
        self.avatar = avatar
        self.deviceID = deviceID
        self.isOnline = false
        self.meshConnected = false
        self.notificationsEnabled = true
        self.darkModeEnabled = false
        self.autoConnectMesh = true
        self.shareLocation = false
        self.showOnlineStatus = true
        self.isEmergencyContact = false
        self.lastSeen = nil
        
        // Initialize advanced mesh network settings
        self.meshDisplayName = name.isEmpty ? "SafeGuardian User" : name
        self.allowPeerDiscovery = true
        self.emergencyBroadcastEnabled = true
        self.meshEncryptionEnabled = true
        self.autoRetryFailedMessages = true
        self.maxPeerConnections = 10
        self.connectionTimeoutSeconds = 30
        self.emergencyContactMeshSharing = true
        self.locationSharingRadius = 5.0 // km
        self.meshNetworkPriority = .balanced
        self.encryptionLevel = .standard
        self.peerTrustLevel = .moderate
        self.dataUsageLimit = .unlimited
        self.emergencyAlertTypes = [.all]
        self.safetyProtocolLevel = .standard
        self.crisisResponseMode = .automatic
    }
    var isOnline: Bool
    var meshConnected: Bool
    var notificationsEnabled: Bool
    var darkModeEnabled: Bool
    var autoConnectMesh: Bool
    var shareLocation: Bool
    var showOnlineStatus: Bool
    var isEmergencyContact: Bool
    var lastSeen: Date?
    
    // MARK: - Advanced Mesh Network Settings
    var meshDisplayName: String
    var allowPeerDiscovery: Bool
    var emergencyBroadcastEnabled: Bool
    var meshEncryptionEnabled: Bool
    var autoRetryFailedMessages: Bool
    var maxPeerConnections: Int
    var connectionTimeoutSeconds: Int
    
    // MARK: - Emergency Contact Integration
    var emergencyContactMeshSharing: Bool
    var locationSharingRadius: Double // in kilometers
    
    // MARK: - Advanced Privacy Controls
    var meshNetworkPriority: MeshNetworkPriority
    var encryptionLevel: EncryptionLevel
    var peerTrustLevel: PeerTrustLevel
    var dataUsageLimit: DataUsageLimit
    
    // MARK: - Safety Preference Categories
    var emergencyAlertTypes: [EmergencyAlertType]
    var safetyProtocolLevel: SafetyProtocolLevel
    var crisisResponseMode: CrisisResponseMode
    
    init(name: String = "User", avatar: String = "person.crop.circle.fill", deviceID: String, isOnline: Bool = false, meshConnected: Bool = false, notificationsEnabled: Bool = true, darkModeEnabled: Bool = false, autoConnectMesh: Bool = true, shareLocation: Bool = false, showOnlineStatus: Bool = true, isEmergencyContact: Bool = false, lastSeen: Date? = nil) {
        self.id = UUID()
        self.name = name
        self.nickname = name // Set nickname to name for compatibility
        self.avatar = avatar
        self.deviceID = deviceID
        self.isOnline = isOnline
        self.meshConnected = meshConnected
        self.notificationsEnabled = notificationsEnabled
        self.darkModeEnabled = darkModeEnabled
        self.autoConnectMesh = autoConnectMesh
        self.shareLocation = shareLocation
        self.showOnlineStatus = showOnlineStatus
        self.isEmergencyContact = isEmergencyContact
        self.lastSeen = lastSeen
        
        // Initialize advanced mesh network settings
        self.meshDisplayName = name.isEmpty ? "SafeGuardian User" : name
        self.allowPeerDiscovery = true
        self.emergencyBroadcastEnabled = true
        self.meshEncryptionEnabled = true
        self.autoRetryFailedMessages = true
        self.maxPeerConnections = 10
        self.connectionTimeoutSeconds = 30
        self.emergencyContactMeshSharing = true
        self.locationSharingRadius = 5.0 // km
        self.meshNetworkPriority = .balanced
        self.encryptionLevel = .standard
        self.peerTrustLevel = .moderate
        self.dataUsageLimit = .unlimited
        self.emergencyAlertTypes = [.all]
        self.safetyProtocolLevel = .standard
        self.crisisResponseMode = .automatic
    }
    
    // Alternative constructor for backward compatibility
    init(nickname: String, isEmergencyContact: Bool, lastSeen: Date? = nil) {
        self.id = UUID()
        self.name = nickname
        self.nickname = nickname
        self.avatar = "person.crop.circle.fill"
        self.deviceID = UUID().uuidString.prefix(8).uppercased().description
        self.isOnline = false
        self.meshConnected = false
        self.notificationsEnabled = true
        self.darkModeEnabled = false
        self.autoConnectMesh = true
        self.shareLocation = false
        self.showOnlineStatus = true
        self.isEmergencyContact = isEmergencyContact
        self.lastSeen = lastSeen
        
        // Initialize advanced mesh network settings
        self.meshDisplayName = nickname.isEmpty ? "SafeGuardian User" : nickname
        self.allowPeerDiscovery = true
        self.emergencyBroadcastEnabled = true
        self.meshEncryptionEnabled = true
        self.autoRetryFailedMessages = true
        self.maxPeerConnections = 10
        self.connectionTimeoutSeconds = 30
        self.emergencyContactMeshSharing = true
        self.locationSharingRadius = 5.0 // km
        self.meshNetworkPriority = .balanced
        self.encryptionLevel = .standard
        self.peerTrustLevel = .moderate
        self.dataUsageLimit = .unlimited
        self.emergencyAlertTypes = [.all]
        self.safetyProtocolLevel = .standard
        self.crisisResponseMode = .automatic
    }
}

// MARK: - Emergency Contact
struct EmergencyContact: Identifiable, Codable {
    var id: UUID
    let name: String
    let phone: String
    let relationship: String
    let isVerified: Bool
    
    init(name: String, phone: String, relationship: String, isVerified: Bool = false) {
        self.id = UUID()
        self.name = name
        self.phone = phone
        self.relationship = relationship
        self.isVerified = isVerified
    }
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool = false
    
    func toggleDarkMode() {
        isDarkMode.toggle()
    }
    
    func updateTheme(darkModeEnabled: Bool) {
        isDarkMode = darkModeEnabled
    }
}

// MARK: - AI Message Models
struct AIMessage: Identifiable {
    let id = UUID()
    let content: String
    let text: String // Alias for content for compatibility
    let isFromUser: Bool
    let isUser: Bool // Alias for isFromUser for compatibility
    let timestamp: Date
    
    init(content: String, isFromUser: Bool, timestamp: Date = Date(), hasEmergencyAlert: Bool = false) {
        self.content = content
        self.text = content // Set alias
        self.isFromUser = isFromUser
        self.isUser = isFromUser // Set alias
        self.timestamp = timestamp
        self.hasEmergencyAlert = hasEmergencyAlert
    }
    
    // Alternative constructor for compatibility
    init(text: String, isUser: Bool) {
        self.content = text
        self.text = text
        self.isFromUser = isUser
        self.isUser = isUser
        self.timestamp = Date()
    }
}

// MARK: - Emergency Services
enum EmergencyServiceType {
    case safetyHub
    case hospital
    case police
    case fireStation
    
    var displayName: String {
        switch self {
        case .safetyHub: return "Safety Hub"
        case .hospital: return "Hospital"
        case .police: return "Police Station"
        case .fireStation: return "Fire Station"
        }
    }
    
    var iconName: String {
        switch self {
        case .safetyHub: return "shield.checkered"
        case .hospital: return "cross.fill"
        case .police: return "person.badge.shield.checkmark"
        case .fireStation: return "flame.fill"
        }
    }
    
    var icon: String { return iconName } // Alias for compatibility
    
    var color: Color {
        switch self {
        case .safetyHub: return .blue
        case .hospital: return .red
        case .police: return .blue
        case .fireStation: return .orange
        }
    }
}

struct EmergencyService: Identifiable {
    let id = UUID()
    let name: String
    let type: EmergencyServiceType
    let latitude: Double
    let longitude: Double
    let distance: Double
    let isOpen: Bool
    
    init(name: String, type: EmergencyServiceType, latitude: Double, longitude: Double, distance: Double, isOpen: Bool = true) {
        self.name = name
        self.type = type
        self.latitude = latitude
        self.longitude = longitude
        self.distance = distance
        self.isOpen = isOpen
    }
    
    func distanceString() -> String {
        if distance < 1 {
            return String(format: "%.0fm", distance * 1000)
        } else {
            return String(format: "%.1fkm", distance)
        }
    }
}

// MARK: - Community Models
struct CommunityLocation: Identifiable {
    let id = UUID()
    let name: String
    let type: EmergencyServiceType?
    let latitude: Double
    let longitude: Double
    let safetyRating: Int
    let lastUpdate: Date
    
    init(name: String, type: EmergencyServiceType? = nil, latitude: Double, longitude: Double, safetyRating: Int, lastUpdate: Date) {
        self.name = name
        self.type = type
        self.latitude = latitude
        self.longitude = longitude
        self.safetyRating = safetyRating
        self.lastUpdate = lastUpdate
    }
}

// MARK: - Community Post Models
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
    
    var color: Color {
        switch self {
        case .announcement: return .blue
        case .alert: return .orange
        case .general: return .secondary
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
    
    init(id: String, author: String, content: String, timestamp: Date, type: CommunityPostType, location: String? = nil) {
        self.id = id
        self.author = author
        self.content = content
        self.timestamp = timestamp
        self.type = type
        self.location = location
    }
}

// MARK: - Advanced Profile Setting Types

enum MeshNetworkPriority: String, CaseIterable, Codable {
    case lowPower = "low_power"
    case balanced = "balanced" 
    case performance = "performance"
    case emergency = "emergency"
    
    var displayName: String {
        switch self {
        case .lowPower: return "Low Power"
        case .balanced: return "Balanced"
        case .performance: return "Performance"
        case .emergency: return "Emergency Priority"
        }
    }
    
    var description: String {
        switch self {
        case .lowPower: return "Conserve battery, slower connections"
        case .balanced: return "Balance battery and performance"
        case .performance: return "Best performance, higher battery usage"
        case .emergency: return "Maximum priority for emergency situations"
        }
    }
}

enum EncryptionLevel: String, CaseIterable, Codable {
    case basic = "basic"
    case standard = "standard"
    case enhanced = "enhanced"
    case maximum = "maximum"
    
    var displayName: String {
        switch self {
        case .basic: return "Basic"
        case .standard: return "Standard"
        case .enhanced: return "Enhanced"
        case .maximum: return "Maximum"
        }
    }
    
    var description: String {
        switch self {
        case .basic: return "Basic encryption for general messages"
        case .standard: return "Standard encryption for most use cases"
        case .enhanced: return "Enhanced encryption for sensitive data"
        case .maximum: return "Maximum encryption for emergency communications"
        }
    }
}

enum PeerTrustLevel: String, CaseIterable, Codable {
    case open = "open"
    case moderate = "moderate"
    case strict = "strict"
    case emergencyOnly = "emergency_only"
    
    var displayName: String {
        switch self {
        case .open: return "Open"
        case .moderate: return "Moderate"
        case .strict: return "Strict"
        case .emergencyOnly: return "Emergency Only"
        }
    }
    
    var description: String {
        switch self {
        case .open: return "Accept connections from any peer"
        case .moderate: return "Accept connections from verified peers"
        case .strict: return "Only connect to trusted peers"
        case .emergencyOnly: return "Only connect during emergencies"
        }
    }
}

enum DataUsageLimit: String, CaseIterable, Codable {
    case restricted = "restricted"
    case moderate = "moderate"
    case high = "high"
    case unlimited = "unlimited"
    
    var displayName: String {
        switch self {
        case .restricted: return "Restricted"
        case .moderate: return "Moderate"
        case .high: return "High"
        case .unlimited: return "Unlimited"
        }
    }
    
    var description: String {
        switch self {
        case .restricted: return "Minimal data usage, emergency only"
        case .moderate: return "Moderate data usage for safety features"
        case .high: return "High data usage for full functionality"
        case .unlimited: return "No data usage restrictions"
        }
    }
}

enum EmergencyAlertType: String, CaseIterable, Codable {
    case all = "all"
    case medical = "medical"
    case fire = "fire"
    case police = "police"
    case natural = "natural"
    case security = "security"
    
    var displayName: String {
        switch self {
        case .all: return "All Emergencies"
        case .medical: return "Medical"
        case .fire: return "Fire"
        case .police: return "Police"
        case .natural: return "Natural Disasters"
        case .security: return "Security"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "exclamationmark.triangle.fill"
        case .medical: return "cross.fill"
        case .fire: return "flame.fill"
        case .police: return "person.badge.shield.checkmark.fill"
        case .natural: return "cloud.bolt.rain.fill"
        case .security: return "lock.shield.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .red
        case .medical: return .red
        case .fire: return .orange
        case .police: return .blue
        case .natural: return .purple
        case .security: return .indigo
        }
    }
}

enum SafetyProtocolLevel: String, CaseIterable, Codable {
    case basic = "basic"
    case standard = "standard"
    case enhanced = "enhanced"
    case maximum = "maximum"
    
    var displayName: String {
        switch self {
        case .basic: return "Basic"
        case .standard: return "Standard"
        case .enhanced: return "Enhanced"
        case .maximum: return "Maximum"
        }
    }
    
    var description: String {
        switch self {
        case .basic: return "Basic safety protocols"
        case .standard: return "Standard safety protocols for most situations"
        case .enhanced: return "Enhanced protocols for high-risk areas"
        case .maximum: return "Maximum safety protocols for emergency zones"
        }
    }
}

enum CrisisResponseMode: String, CaseIterable, Codable {
    case manual = "manual"
    case semiAutomatic = "semi_automatic"
    case automatic = "automatic"
    case emergencyFirst = "emergency_first"
    
    var displayName: String {
        switch self {
        case .manual: return "Manual"
        case .semiAutomatic: return "Semi-Automatic"
        case .automatic: return "Automatic"
        case .emergencyFirst: return "Emergency First"
        }
    }
    
    var description: String {
        switch self {
        case .manual: return "Manual crisis response activation"
        case .semiAutomatic: return "Confirm before activating crisis response"
        case .automatic: return "Automatically activate crisis response"
        case .emergencyFirst: return "Prioritize emergency services in all situations"
        }
    }
}

// MARK: - Enhanced Emergency Contact
struct EnhancedEmergencyContact: Identifiable, Codable {
    var id: UUID
    let name: String
    let phone: String
    let relationship: String
    let isVerified: Bool
    let meshNetworkEnabled: Bool
    let priorityLevel: ContactPriorityLevel
    let lastVerified: Date?
    let meshPeerID: String?
    
    init(name: String, phone: String, relationship: String, isVerified: Bool = false, meshNetworkEnabled: Bool = true, priorityLevel: ContactPriorityLevel = .normal, lastVerified: Date? = nil, meshPeerID: String? = nil) {
        self.id = UUID()
        self.name = name
        self.phone = phone
        self.relationship = relationship
        self.isVerified = isVerified
        self.meshNetworkEnabled = meshNetworkEnabled
        self.priorityLevel = priorityLevel
        self.lastVerified = lastVerified
        self.meshPeerID = meshPeerID
    }
}

enum ContactPriorityLevel: String, CaseIterable, Codable {
    case emergency = "emergency"
    case high = "high"
    case normal = "normal"
    case low = "low"
    
    var displayName: String {
        switch self {
        case .emergency: return "Emergency"
        case .high: return "High"
        case .normal: return "Normal"
        case .low: return "Low"
        }
    }
    
    var color: Color {
        switch self {
        case .emergency: return .red
        case .high: return .orange
        case .normal: return .blue
        case .low: return .gray
        }
    }
    
    var description: String {
        switch self {
        case .emergency: return "Contact immediately in any emergency"
        case .high: return "Contact for serious situations"
        case .normal: return "Contact for general safety concerns"
        case .low: return "Contact for non-urgent updates"
        }
    }
}

// MARK: - Mesh Network Diagnostics
struct MeshNetworkDiagnostics: Codable {
    let timestamp: Date
    let connectedPeers: Int
    let signalStrength: Double
    let latency: TimeInterval
    let throughput: Double
    let errorRate: Double
    let batteryImpact: Double
    
    var overallHealth: NetworkHealth {
        let healthScore = (signalStrength * 0.3) + 
                         ((100 - errorRate) * 0.3) + 
                         (min(throughput / 1000, 1.0) * 0.2) + 
                         ((100 - batteryImpact) * 0.2)
        
        switch healthScore {
        case 80...100: return .excellent
        case 60..<80: return .good
        case 40..<60: return .fair
        default: return .poor
        }
    }
}

enum NetworkHealth: String, CaseIterable, Codable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    
    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        }
    }
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        }
    }
    
    var description: String {
        switch self {
        case .excellent: return "Network is performing optimally"
        case .good: return "Network is performing well"
        case .fair: return "Network has some performance issues"
        case .poor: return "Network has significant issues"
        }
    }
}

extension UserProfile {
    static let sample = UserProfile(
        name: "SafeGuardian User",
        avatar: "person.crop.circle.fill",
        deviceID: "SG123456",
        isOnline: true,
        meshConnected: true,
        notificationsEnabled: true,
        darkModeEnabled: false,
        autoConnectMesh: true,
        shareLocation: true,
        showOnlineStatus: true,
        isEmergencyContact: false,
        lastSeen: Date()
    )
}

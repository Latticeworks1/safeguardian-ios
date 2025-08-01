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
    let id = UUID()
    var name: String
    var nickname: String // For backward compatibility
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
    
    init(name: String = "User", avatar: String = "person.crop.circle.fill", deviceID: String, isOnline: Bool = false, meshConnected: Bool = false, notificationsEnabled: Bool = true, darkModeEnabled: Bool = false, autoConnectMesh: Bool = true, shareLocation: Bool = false, showOnlineStatus: Bool = true, isEmergencyContact: Bool = false, lastSeen: Date? = nil) {
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
    }
    
    // Alternative constructor for backward compatibility
    init(nickname: String, isEmergencyContact: Bool, lastSeen: Date? = nil) {
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
    }
}

// MARK: - Emergency Contact
struct EmergencyContact: Identifiable, Codable {
    let id = UUID()
    let name: String
    let phone: String
    let relationship: String
    let isVerified: Bool
    
    init(name: String, phone: String, relationship: String, isVerified: Bool = false) {
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
    
    init(content: String, isFromUser: Bool) {
        self.content = content
        self.text = content // Set alias
        self.isFromUser = isFromUser
        self.isUser = isFromUser // Set alias
        self.timestamp = Date()
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

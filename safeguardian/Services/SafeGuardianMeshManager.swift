import Foundation
import SwiftUI
import Combine

// BitChat protocols and types are included directly in project
// No separate import needed - using local BitChat implementation

/// SafeGuardian's mesh networking manager that wraps BitChat's proven P2P implementation
class SafeGuardianMeshManager: ObservableObject, BitchatDelegate {
    
    // MARK: - Published Properties for SafeGuardian UI
    @Published var isConnected: Bool = false
    @Published var connectedPeers: [String] = []
    @Published var messages: [SafeGuardianMessage] = []
    @Published var nickname: String = "SafeGuardian User"
    
    // MARK: - BitChat Backend (core networking only)
    private let meshService = BluetoothMeshService()
    
    // MARK: - BitchatDelegate Implementation
    func didReceiveMessage(_ message: BitchatMessage) {
        let safeGuardianMessage = SafeGuardianMessage(
            id: message.id,
            sender: message.sender,
            content: message.content,
            timestamp: message.timestamp,
            isRelay: message.isRelay,
            originalSender: message.originalSender,
            isPrivate: message.isPrivate,
            recipientNickname: message.recipientNickname,
            senderPeerID: message.senderPeerID,
            mentions: message.mentions,
            deliveryStatus: convertDeliveryStatus(message.deliveryStatus)
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
    
    func didUpdatePeerList(_ peers: [String]) {
        DispatchQueue.main.async {
            self.connectedPeers = peers
            self.isConnected = !peers.isEmpty
        }
    }
    
    func isFavorite(fingerprint: String) -> Bool {
        return false // SafeGuardian doesn't use favorites yet
    }
    
    func didReceiveDeliveryAck(_ ack: DeliveryAck) {
        // Handle delivery acknowledgments
    }
    
    func didReceiveReadReceipt(_ receipt: ReadReceipt) {
        // Handle read receipts
    }
    
    func didUpdateMessageDeliveryStatus(_ messageID: String, status: DeliveryStatus) {
        // Update message delivery status in UI
    }
    
    func peerAvailabilityChanged(_ peerID: String, available: Bool) {
        // Handle peer availability changes
    }
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupBitChatIntegration()
    }
    
    // MARK: - Private Setup
    private func setupBitChatIntegration() {
        // Set ourselves as the delegate for BitChat's mesh service
        meshService.delegate = self
        
        // BitChat will call our delegate methods directly
        // No need for Combine publishers
    }
    
    // MARK: - Public Interface for SafeGuardian
    
    /// Send a message through the mesh network
    func sendMessage(_ content: String) {
        meshService.sendMessage(content)
    }
    
    /// Send an emergency broadcast to all connected peers
    func sendEmergencyBroadcast(_ message: String) {
        let emergencyMessage = "🚨 EMERGENCY: \(message)"
        meshService.sendMessage(emergencyMessage)
    }
    
    /// Convert BitChat delivery status to SafeGuardian delivery status
    private func convertDeliveryStatus(_ bitchatStatus: DeliveryStatus?) -> SafeGuardianDeliveryStatus? {
        guard let status = bitchatStatus else { return nil }
        
        switch status {
        case .sending:
            return .sending
        case .sent:
            return .sent
        case .delivered(let to, let at):
            return .delivered(to: to, at: at)
        case .read(let by, let at):
            return .read(by: by, at: at)
        case .failed(let reason):
            return .failed(reason: reason)
        case .partiallyDelivered(let reached, let total):
            return .partiallyDelivered(reached: reached, total: total)
        }
    }
    
    
    // MARK: - Safety-Specific Features
    
    /// Check if any emergency keywords are in the message
    func isEmergencyMessage(_ content: String) -> Bool {
        let emergencyKeywords = ["emergency", "help", "911", "sos", "urgent", "danger"]
        let lowercaseContent = content.lowercased()
        return emergencyKeywords.contains { lowercaseContent.contains($0) }
    }
    
    /// Get network quality description
    func getNetworkQuality() -> NetworkQuality {
        if !isConnected {
            return .offline
        }
        
        switch connectedPeers.count {
        case 0:
            return .offline
        case 1...2:
            return .poor
        case 3...5:
            return .good
        default:
            return .excellent
        }
    }
}

// MARK: - SafeGuardian-Specific Types

/// SafeGuardian's message model (lightweight wrapper for UI)
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

/// SafeGuardian's delivery status (mirrors BitChat's)
enum SafeGuardianDeliveryStatus {
    case sending
    case sent
    case delivered(to: String, at: Date)
    case read(by: String, at: Date)
    case failed(reason: String)
    case partiallyDelivered(reached: Int, total: Int)
}

/// Network quality levels for SafeGuardian UI
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
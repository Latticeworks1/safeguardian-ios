import Foundation

// Minimal MessageRetryService stub for BitChat compatibility
class MessageRetryService {
    static let shared = MessageRetryService()
    
    func queueMessageForRetry(_ message: Any, toPeer peerID: String) {
        // Stub for BitChat compatibility
    }
    
    func addMessageForRetry(content: String, mentions: [String]?, isPrivate: Bool, recipientPeerID: String?, recipientNickname: String?, originalMessageID: String, originalTimestamp: Date) {
        // Stub for BitChat compatibility
    }
}
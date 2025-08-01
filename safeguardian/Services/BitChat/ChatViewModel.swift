import Foundation

// Minimal ChatViewModel stub for BitChat compatibility
class ChatViewModel {
    func registerPeerPublicKey(peerID: String, publicKeyData: Data) {
        // Stub for BitChat compatibility
    }
    
    func updateEncryptionStatusForPeer(_ peerID: String) {
        // Stub for BitChat compatibility  
    }
    
    func updateEncryptionStatusForPeers() {
        // Stub for BitChat compatibility
    }
    
    var nickname: String? {
        return "SafeGuardian User"
    }
}
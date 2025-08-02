import Foundation
import SwiftUI
import Security
import CryptoKit

// MARK: - Authentication Models
struct User: Codable, Identifiable {
    let id: UUID
    var email: String
    var displayName: String
    var profileImageURL: String?
    var meshNetworkID: String
    var emergencyContacts: [EmergencyContact]
    var safetyPreferences: SafetyPreferences
    var accountCreatedDate: Date
    var lastLoginDate: Date
    
    init(email: String, displayName: String) {
        self.id = UUID()
        self.email = email
        self.displayName = displayName
        self.meshNetworkID = UUID().uuidString
        self.emergencyContacts = []
        self.safetyPreferences = SafetyPreferences()
        self.accountCreatedDate = Date()
        self.lastLoginDate = Date()
    }
}

struct SafetyPreferences: Codable {
    var emergencyAlertEnabled: Bool = true
    var meshNetworkParticipation: Bool = true
    var locationSharingEnabled: Bool = false
    var voiceCommandsEnabled: Bool = true
    var biometricAuthEnabled: Bool = false
    var autoEmergencyDetection: Bool = true
    var communityAlertsEnabled: Bool = true
    
    init() {}
}

enum AuthenticationState {
    case unauthenticated
    case authenticating
    case authenticated(User)
    case error(String)
}

// MARK: - Enhanced Authentication Service
class AuthenticationService: ObservableObject {
    @Published var authState: AuthenticationState = .unauthenticated
    @Published var isLoading = false
    @Published var showingSignIn = false
    @Published var showingSignUp = false
    
    // Biometric authentication
    @Published var biometricAuthAvailable = false
    @Published var biometricType: BiometricType = .none
    
    // User session management
    private let keychain = KeychainManager.shared
    private let userDefaults = UserDefaults.standard
    
    // Security and encryption
    private var currentUser: User? {
        didSet {
            if let user = currentUser {
                authState = .authenticated(user)
                saveUserSession(user)
            } else {
                authState = .unauthenticated
                clearUserSession()
            }
        }
    }
    
    init() {
        checkExistingSession()
        setupBiometricAuth()
    }
    
    // MARK: - Session Management
    private func checkExistingSession() {
        if let userData = keychain.getData(forKey: "current_user"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            currentUser = user
        }
    }
    
    private func saveUserSession(_ user: User) {
        if let userData = try? JSONEncoder().encode(user) {
            keychain.setData(userData, forKey: "current_user")
            userDefaults.set(user.id.uuidString, forKey: "user_id")
            userDefaults.set(Date(), forKey: "last_login")
        }
    }
    
    private func clearUserSession() {
        keychain.removeData(forKey: "current_user")
        userDefaults.removeObject(forKey: "user_id")
        currentUser = nil
    }
    
    // MARK: - Sign Up
    func signUp(email: String, password: String, displayName: String) async {
        await MainActor.run {
            isLoading = true
            authState = .authenticating
        }
        
        do {
            // Validate inputs
            try validateSignUpInputs(email: email, password: password, displayName: displayName)
            
            // Check if user already exists
            if userExists(email: email) {
                throw AuthError.userAlreadyExists
            }
            
            // Hash password securely
            let hashedPassword = try hashPassword(password)
            
            // Create new user
            let newUser = User(email: email, displayName: displayName)
            
            // Store user credentials securely
            try storeUserCredentials(user: newUser, hashedPassword: hashedPassword)
            
            // Set up mesh network identity
            setupMeshNetworkIdentity(for: newUser)
            
            await MainActor.run {
                currentUser = newUser
                isLoading = false
                showingSignUp = false
            }
            
        } catch {
            await MainActor.run {
                authState = .error(error.localizedDescription)
                isLoading = false
            }
        }
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String) async {
        await MainActor.run {
            isLoading = true
            authState = .authenticating
        }
        
        do {
            // Validate inputs
            try validateSignInInputs(email: email, password: password)
            
            // Verify credentials
            let user = try verifyUserCredentials(email: email, password: password)
            
            // Update last login
            var updatedUser = user
            updatedUser.lastLoginDate = Date()
            
            await MainActor.run {
                currentUser = updatedUser
                isLoading = false
                showingSignIn = false
            }
            
        } catch {
            await MainActor.run {
                authState = .error(error.localizedDescription)
                isLoading = false
            }
        }
    }
    
    // MARK: - Biometric Authentication
    private func setupBiometricAuth() {
        // Check biometric availability
        checkBiometricAvailability()
    }
    
    private func checkBiometricAvailability() {
        // Implementation would use LocalAuthentication framework
        // For now, simulate availability
        biometricAuthAvailable = true
        biometricType = .faceID // or .touchID based on device
    }
    
    func signInWithBiometrics() async {
        guard biometricAuthAvailable else { return }
        
        await MainActor.run {
            isLoading = true
            authState = .authenticating
        }
        
        do {
            // Get stored user ID
            guard let userID = userDefaults.string(forKey: "user_id"),
                  let userData = keychain.getData(forKey: "current_user"),
                  let user = try? JSONDecoder().decode(User.self, from: userData) else {
                throw AuthError.noStoredCredentials
            }
            
            // Perform biometric authentication
            let authenticated = try await performBiometricAuth()
            
            if authenticated {
                var updatedUser = user
                updatedUser.lastLoginDate = Date()
                
                await MainActor.run {
                    currentUser = updatedUser
                    isLoading = false
                }
            } else {
                throw AuthError.biometricFailed
            }
            
        } catch {
            await MainActor.run {
                authState = .error(error.localizedDescription)
                isLoading = false
            }
        }
    }
    
    private func performBiometricAuth() async throws -> Bool {
        // TODO: Implement actual LocalAuthentication
        // For now, simulate successful authentication
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        return true
    }
    
    // MARK: - Sign Out
    func signOut() {
        currentUser = nil
        clearUserSession()
    }
    
    // MARK: - User Management
    func updateUser(_ updatedUser: User) async {
        await MainActor.run {
            currentUser = updatedUser
        }
    }
    
    func updateSafetyPreferences(_ preferences: SafetyPreferences) async {
        guard var user = currentUser else { return }
        user.safetyPreferences = preferences
        await updateUser(user)
    }
    
    func addEmergencyContact(_ contact: EmergencyContact) async {
        guard var user = currentUser else { return }
        user.emergencyContacts.append(contact)
        await updateUser(user)
    }
    
    // MARK: - Validation
    private func validateSignUpInputs(email: String, password: String, displayName: String) throws {
        guard !email.isEmpty else { throw AuthError.invalidEmail }
        guard email.contains("@") && email.contains(".") else { throw AuthError.invalidEmail }
        guard !password.isEmpty else { throw AuthError.invalidPassword }
        guard password.count >= 8 else { throw AuthError.passwordTooShort }
        guard !displayName.isEmpty else { throw AuthError.invalidDisplayName }
    }
    
    private func validateSignInInputs(email: String, password: String) throws {
        guard !email.isEmpty else { throw AuthError.invalidEmail }
        guard !password.isEmpty else { throw AuthError.invalidPassword }
    }
    
    // MARK: - Security
    private func hashPassword(_ password: String) throws -> String {
        guard let data = password.data(using: .utf8) else {
            throw AuthError.passwordHashingFailed
        }
        
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func userExists(email: String) -> Bool {
        return keychain.getData(forKey: "user_\(email)") != nil
    }
    
    private func storeUserCredentials(user: User, hashedPassword: String) throws {
        // Store user data
        guard let userData = try? JSONEncoder().encode(user) else {
            throw AuthError.userStorageFailed
        }
        
        keychain.setData(userData, forKey: "user_\(user.email)")
        keychain.setString(hashedPassword, forKey: "password_\(user.email)")
    }
    
    private func verifyUserCredentials(email: String, password: String) throws -> User {
        // Get stored user
        guard let userData = keychain.getData(forKey: "user_\(email)"),
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            throw AuthError.userNotFound
        }
        
        // Verify password
        guard let storedPasswordHash = keychain.getString(forKey: "password_\(email)") else {
            throw AuthError.userNotFound
        }
        
        let inputPasswordHash = try hashPassword(password)
        guard inputPasswordHash == storedPasswordHash else {
            throw AuthError.incorrectPassword
        }
        
        return user
    }
    
    private func setupMeshNetworkIdentity(for user: User) {
        // Set up mesh network identity and keys
        // This would integrate with SafeGuardianMeshManager
        NotificationCenter.default.post(
            name: .userRegistered,
            object: user,
            userInfo: ["meshNetworkID": user.meshNetworkID]
        )
    }
}

// MARK: - Authentication Errors
enum AuthError: LocalizedError {
    case invalidEmail
    case invalidPassword
    case passwordTooShort
    case invalidDisplayName
    case userAlreadyExists
    case userNotFound
    case incorrectPassword
    case passwordHashingFailed
    case userStorageFailed
    case noStoredCredentials
    case biometricFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .invalidPassword:
            return "Password cannot be empty"
        case .passwordTooShort:
            return "Password must be at least 8 characters"
        case .invalidDisplayName:
            return "Display name cannot be empty"
        case .userAlreadyExists:
            return "An account with this email already exists"
        case .userNotFound:
            return "No account found with this email"
        case .incorrectPassword:
            return "Incorrect password"
        case .passwordHashingFailed:
            return "Password security setup failed"
        case .userStorageFailed:
            return "Failed to create account"
        case .noStoredCredentials:
            return "No stored credentials found"
        case .biometricFailed:
            return "Biometric authentication failed"
        }
    }
}

// MARK: - Biometric Types
enum BiometricType {
    case none
    case touchID
    case faceID
    case opticID
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .touchID: return "Touch ID"
        case .faceID: return "Face ID"
        case .opticID: return "Optic ID"
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "lock"
        case .touchID: return "touchid"
        case .faceID: return "faceid"
        case .opticID: return "opticid"
        }
    }
}

// MARK: - Keychain Manager
class KeychainManager {
    static let shared = KeychainManager()
    private init() {}
    
    func setString(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }
        setData(data, forKey: key)
    }
    
    func getString(forKey key: String) -> String? {
        guard let data = getData(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func setData(_ data: Data, forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func getData(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }
    
    func removeData(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let userRegistered = Notification.Name("userRegistered")
}
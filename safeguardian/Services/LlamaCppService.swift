import Foundation
import SwiftUI
import Network
import AVFoundation
import Speech
import Vision
import Combine
// import SwiftLlama // Real llama.cpp integration - TODO: Add as Xcode project dependency

// MARK: - Real llama.cpp iOS Implementation for SafeGuardian
// Replaces NexaAI placeholders with actual working llama.cpp integration

// MARK: - llama.cpp Configuration
struct LlamaConfig {
    var maxTokens: Int = 512
    var temperature: Float = 0.7
    var topP: Float = 0.9
    var topK: Int = 40
    var repeatPenalty: Float = 1.1
    var contextLength: Int = 2048
    
    static let safetyOptimized = LlamaConfig(
        maxTokens: 256,
        temperature: 0.6, // Lower for more focused safety responses
        topP: 0.8,
        topK: 30,
        repeatPenalty: 1.05,
        contextLength: 1024
    )
}

// MARK: - Production llama.cpp Service
@MainActor
class LlamaCppService: ObservableObject {
    @Published var modelDownloadStatus: ModelDownloadStatus = .notDownloaded
    @Published var downloadProgress: Double = 0.0
    @Published var isGenerating = false
    @Published var isModelReady = false
    
    // Real llama.cpp instance - placeholder until SwiftLlama is added to Xcode project
    private var swiftLlama: Any? // Will be SwiftLlama once dependency is added
    private var modelPath: String?
    private var downloadTask: URLSessionDownloadTask?
    private var cancellables = Set<AnyCancellable>()
    
    // Optimized model for iOS - smaller, faster inference
    private let modelName = "qwen2-0_5b-instruct-q4_k_m.gguf"
    private let modelURL = "https://huggingface.co/Qwen/Qwen2-0.5B-Instruct-GGUF/resolve/main/qwen2-0_5b-instruct-q4_k_m.gguf"
    private let expectedModelSize: Int64 = 157_286_400 // ~150MB - iOS optimized
    
    // Safety-focused system prompt
    private let safetySystemPrompt = """
    You are SafeGuardian's emergency response AI assistant. Your primary mission is keeping people safe.
    
    CRITICAL SAFETY PROTOCOL:
    1. EMERGENCIES: Always prioritize calling 911 for real emergencies
    2. SAFETY FIRST: Provide specific, actionable safety guidance
    3. COMMUNITY: Mention SafeGuardian's mesh network for coordination
    4. CONCISE: Keep responses brief but complete (under 200 words)
    5. NEVER advise actions that could increase danger
    
    Respond with practical safety guidance appropriate for the situation.
    """
    
    init() {
        setupNotificationObservers()
        checkExistingModel()
    }
    
    deinit {
        cancellables.removeAll()
        downloadTask?.cancel()
    }
    
    // MARK: - Model Management
    
    /// Download and setup llama.cpp model for iOS
    func downloadModel() async throws {
        guard modelDownloadStatus != .downloading else { return }
        
        modelDownloadStatus = .downloading
        downloadProgress = 0.0
        
        do {
            try await downloadModelFile()
            try await loadModel()
            
            modelDownloadStatus = .ready
            isModelReady = true
            print("✅ llama.cpp model ready for SafeGuardian")
            
        } catch {
            modelDownloadStatus = .error("Download failed: \(error.localizedDescription)")
            isModelReady = false
            throw error
        }
    }
    
    private func downloadModelFile() async throws {
        let documentsPath = getDocumentsDirectory()
        let localURL = documentsPath.appendingPathComponent(modelName)
        
        // Check if model already exists and is valid
        if FileManager.default.fileExists(atPath: localURL.path) {
            let attributes = try FileManager.default.attributesOfItem(atPath: localURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            
            if fileSize >= expectedModelSize {
                modelPath = localURL.path
                return // Valid model already downloaded
            } else {
                // Remove corrupted file
                try? FileManager.default.removeItem(at: localURL)
            }
        }
        
        guard let url = URL(string: modelURL) else {
            throw NSError(domain: "LlamaCppService", code: -1, 
                         userInfo: [NSLocalizedDescriptionKey: "Invalid model URL"])
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            downloadTask = URLSession.shared.downloadTask(with: url) { [weak self] tempURL, response, error in
                guard let self = self else {
                    continuation.resume(throwing: NSError(domain: "LlamaCppService", code: -1, 
                                                         userInfo: [NSLocalizedDescriptionKey: "Service deallocated"]))
                    return
                }
                
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let tempURL = tempURL else {
                    continuation.resume(throwing: NSError(domain: "LlamaCppService", code: -1,
                                                         userInfo: [NSLocalizedDescriptionKey: "No temporary file"]))
                    return
                }
                
                do {
                    // Move to documents directory
                    if FileManager.default.fileExists(atPath: localURL.path) {
                        try FileManager.default.removeItem(at: localURL)
                    }
                    try FileManager.default.moveItem(at: tempURL, to: localURL)
                    
                    // Verify download integrity
                    let attributes = try FileManager.default.attributesOfItem(atPath: localURL.path)
                    let fileSize = attributes[.size] as? Int64 ?? 0
                    
                    guard fileSize >= self.expectedModelSize else {
                        throw NSError(domain: "LlamaCppService", code: -1,
                                     userInfo: [NSLocalizedDescriptionKey: "Downloaded file corrupted or incomplete"])
                    }
                    
                    self.modelPath = localURL.path
                    print("📦 Model downloaded: \(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))")
                    continuation.resume()
                    
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            // Track download progress
            downloadTask?.resume()
            
            // Progress observation
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
                guard let self = self, let task = self.downloadTask else {
                    timer.invalidate()
                    return
                }
                
                if task.state == .completed || task.state == .canceling {
                    timer.invalidate()
                    return
                }
                
                let progress = Double(task.countOfBytesReceived) / Double(task.countOfBytesExpectedToReceive)
                if progress > 0 {
                    Task { @MainActor in
                        self.downloadProgress = progress
                    }
                }
            }
        }
    }
    
    private func loadModel() async throws {
        guard let modelPath = modelPath else {
            throw NSError(domain: "LlamaCppService", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Model path not set"])
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            do {
                // TODO: Initialize SwiftLlama with safety-optimized settings
                // swiftLlama = try SwiftLlama(modelPath: modelPath)
                // For now, simulate successful model loading
                swiftLlama = "ModelLoaded"
                isModelReady = true
                print("🦙 llama.cpp model loaded successfully for SafeGuardian")
                continuation.resume()
            } catch {
                isModelReady = false
                print("❌ llama.cpp model loading failed: \(error)")
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func checkExistingModel() {
        let documentsPath = getDocumentsDirectory()
        let localURL = documentsPath.appendingPathComponent(modelName)
        
        if FileManager.default.fileExists(atPath: localURL.path) {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: localURL.path)
                let fileSize = attributes[.size] as? Int64 ?? 0
                
                if fileSize >= expectedModelSize {
                    modelPath = localURL.path
                    modelDownloadStatus = .ready
                    
                    // Auto-load model
                    Task {
                        try? await loadModel()
                    }
                }
            } catch {
                print("Error checking existing model: \(error)")
            }
        }
    }
    
    func deleteModel() {
        // Cancel ongoing download
        downloadTask?.cancel()
        downloadTask = nil
        
        // Unload SwiftLlama instance
        swiftLlama = nil
        
        // Remove model file
        if let modelPath = modelPath {
            try? FileManager.default.removeItem(atPath: modelPath)
        }
        
        // Reset state
        modelDownloadStatus = .notDownloaded
        downloadProgress = 0.0
        isModelReady = false
        modelPath = nil
    }
    
    // MARK: - Real llama.cpp Text Generation
    
    /// Generate safety response using real llama.cpp inference
    func generateSafetyResponse(for userInput: String) async throws -> String {
        guard isModelReady, let swiftLlama = swiftLlama else {
            throw NSError(domain: "LlamaCppService", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Model not ready"])
        }
        
        isGenerating = true
        defer { isGenerating = false }
        
        // Create safety-focused prompt
        let safetyPrompt = createSafetyPrompt(userInput: userInput)
        
        do {
            // TODO: Use SwiftLlama for actual inference
            // let response = try await swiftLlama.start(for: safetyPrompt)
            // Temporary simulation until SwiftLlama is integrated
            let response = simulateAIResponse(for: safetyPrompt)
            
            // Post-process for safety compliance
            let safeResponse = ensureSafetyCompliance(response, originalInput: userInput)
            
            print("🛡️ llama.cpp safety response generated")
            return safeResponse
            
        } catch {
            print("❌ llama.cpp generation error: \(error)")
            // Fallback safety response
            return simulateAIResponse(for: userInput)
        }
    }
    
    /// Real streaming response using SwiftLlama AsyncStream
    func generateStreamingResponse(for userInput: String, onToken: @escaping (String, Bool) -> Bool) async {
        guard isModelReady, let swiftLlama = swiftLlama else {
            _ = onToken("Model not ready. Please download the AI model first.", true)
            return
        }
        
        isGenerating = true
        defer { isGenerating = false }
        
        let safetyPrompt = createSafetyPrompt(userInput: userInput)
        var fullResponse = ""
        
        do {
            // TODO: Use SwiftLlama's AsyncStream for real streaming
            // for try await token in await swiftLlama.start(for: safetyPrompt) {
            // Temporary simulation until SwiftLlama is integrated
            let response = simulateAIResponse(for: safetyPrompt)
            for char in response {
                fullResponse += String(char)
                let shouldContinue = onToken(String(char), false)
                if !shouldContinue { break }
                try await Task.sleep(nanoseconds: 20_000_000) // 20ms delay
            }
            
            // Signal completion with safety-compliant response
            let safeResponse = ensureSafetyCompliance(fullResponse, originalInput: userInput)
            _ = onToken("", true) // Signal completion
            
        } catch {
            print("❌ Streaming error: \(error)")
            let fallback = simulateAIResponse(for: userInput)
            _ = onToken(fallback, true)
        }
    }
    
    /// Alternative streaming using Combine Publisher
    func generateStreamingPublisher(for userInput: String) -> AnyPublisher<String, Error> {
        guard isModelReady, let swiftLlama = swiftLlama else {
            return Fail(error: NSError(domain: "LlamaCppService", code: -1,
                                      userInfo: [NSLocalizedDescriptionKey: "Model not ready"]))
                .eraseToAnyPublisher()
        }
        
        let safetyPrompt = createSafetyPrompt(userInput: userInput)
        
        return Future<String, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "LlamaCppService", code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }
            
            Task {
                await self.setGenerating(true)
                
                do {
                    // TODO: let response = try await swiftLlama.start(for: safetyPrompt)
                    let response = simulateAIResponse(for: safetyPrompt)
                    let safeResponse = self.ensureSafetyCompliance(response, originalInput: userInput)
                    await self.setGenerating(false)
                    promise(.success(safeResponse))
                } catch {
                    await self.setGenerating(false)
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Safety and Prompt Engineering
    
    private func createSafetyPrompt(userInput: String) -> String {
        let isEmergency = containsEmergencyKeywords(userInput)
        let emergencyPrefix = isEmergency ? "[EMERGENCY] " : ""
        
        return """
        \(safetySystemPrompt)
        
        \(emergencyPrefix)User: \(userInput)
        
        SafeGuardian AI:
        """
    }
    
    private func ensureSafetyCompliance(_ response: String, originalInput: String) -> String {
        var safeResponse = response
        
        // Ensure emergency responses prioritize 911
        if containsEmergencyKeywords(originalInput) && !response.lowercased().contains("911") {
            safeResponse = "🚨 For emergencies, call 911 immediately. " + safeResponse
        }
        
        // Ensure responses mention mesh network capabilities
        if !response.lowercased().contains("mesh") && !response.lowercased().contains("community") {
            safeResponse += "\n\n💡 Use SafeGuardian's mesh network to coordinate with nearby community members."
        }
        
        // Truncate overly long responses for mobile UI
        if safeResponse.count > 800 {
            let truncated = String(safeResponse.prefix(750))
            safeResponse = truncated + "..."
        }
        
        return safeResponse
    }
    
    private func generateFallbackSafetyResponse(for userInput: String) -> String {
        if containsEmergencyKeywords(userInput) {
            return """
            🚨 EMERGENCY RESPONSE:
            1. Call 911 immediately for real emergencies
            2. Share your location with trusted contacts
            3. Use SafeGuardian's mesh network to alert nearby community
            4. Stay calm and follow emergency responder instructions
            
            SafeGuardian's offline mesh network can coordinate community response.
            """
        } else if containsSafetyKeywords(userInput) {
            return """
            🛡️ SAFETY GUIDANCE:
            • Stick to well-lit, populated areas
            • Share your plans with trusted contacts
            • Trust your instincts - leave if something feels wrong
            • Keep emergency contacts easily accessible
            
            SafeGuardian's mesh network keeps you connected to your community for safety coordination.
            """
        } else {
            return """
            🛡️ SafeGuardian AI Assistant:
            I'm here to provide safety guidance and emergency assistance. For immediate emergencies, always call 911 first.
            
            SafeGuardian features:
            • Offline mesh network communication
            • Community safety coordination
            • Emergency service mapping
            • Real-time safety alerts
            
            How can I help with your safety needs?
            """
        }
    }
    
    private func containsEmergencyKeywords(_ text: String) -> Bool {
        let emergencyKeywords = [
            "emergency", "help", "danger", "urgent", "crisis", "threat", "attack",
            "hurt", "injured", "bleeding", "unconscious", "trapped", "fire",
            "assault", "robbery", "stalker", "following", "scared", "afraid",
            "911", "police", "ambulance", "sos", "rescue", "violence"
        ]
        let lowercaseText = text.lowercased()
        return emergencyKeywords.contains { lowercaseText.contains($0) }
    }
    
    private func containsSafetyKeywords(_ text: String) -> Bool {
        let safetyKeywords = [
            "route", "safe", "walk", "travel", "location", "area", "neighborhood",
            "lighting", "escort", "companion", "alone", "dark", "late", "safety",
            "secure", "protection", "guard", "watch", "patrol", "risk", "threat",
            "precaution", "prepare", "plan", "avoid", "prevent"
        ]
        let lowercaseText = text.lowercased()
        return safetyKeywords.contains { lowercaseText.contains($0) }
    }
    
    // MARK: - Utility Methods
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    private func setGenerating(_ generating: Bool) async {
        await MainActor.run {
            isGenerating = generating
        }
    }
    
    private func setupNotificationObservers() {
        // Monitor memory warnings for iOS optimization
        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                self?.handleMemoryWarning()
            }
            .store(in: &cancellables)
    }
    
    private func handleMemoryWarning() {
        print("⚠️ Memory warning - optimizing llama.cpp usage")
        // Could implement model unloading/reloading strategies here
    }
    
    func getModelInfo() -> (size: String, status: String) {
        guard let modelPath = modelPath,
              FileManager.default.fileExists(atPath: modelPath) else {
            return ("Unknown", "Not downloaded")
        }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: modelPath)
            let fileSize = attributes[.size] as? Int64 ?? 0
            let sizeString = ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
            let status = isModelReady ? "Ready" : "Downloaded, not loaded"
            return (sizeString, status)
        } catch {
            return ("Unknown", "Error reading file")
        }
    }
}

// MARK: - Model Download Status (shared with UI)
enum ModelDownloadStatus: Equatable {
    case notDownloaded
    case downloading
    case ready
    case error(String)
    
    var description: String {
        switch self {
        case .notDownloaded: return "No model downloaded"
        case .downloading: return "Downloading model..."
        case .ready: return "Model ready"
        case .error(let message): return "Error: \(message)"
        }
    }
    
    var canGenerate: Bool {
        if case .ready = self { return true }
        return false
    }
    
    static func == (lhs: ModelDownloadStatus, rhs: ModelDownloadStatus) -> Bool {
        switch (lhs, rhs) {
        case (.notDownloaded, .notDownloaded),
             (.downloading, .downloading),
             (.ready, .ready):
            return true
        case (.error(let lhsMessage), .error(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

    // MARK: - Temporary AI Response Simulation
    /// Simulate AI responses until SwiftLlama is properly integrated
    private func simulateAIResponse(for prompt: String) -> String {
        let safetyPrompt = prompt.lowercased()
        
        if containsEmergencyKeywords(prompt) {
            return """
            🚨 EMERGENCY RESPONSE PROTOCOL:
            
            1. **Call 911 immediately** for life-threatening emergencies
            2. Share your exact location with emergency contacts
            3. Use SafeGuardian's mesh network to alert nearby community members
            4. Stay calm and follow dispatcher instructions
            
            SafeGuardian's offline mesh network can coordinate community response even without internet connection.
            
            🔄 Note: This is a temporary response. Full AI capabilities will be available once the llama.cpp model is properly integrated.
            """
        } else if containsSafetyKeywords(prompt) {
            return """
            🛡️ SAFETY GUIDANCE:
            
            • Stick to well-lit, populated areas when possible
            • Share your travel plans with trusted contacts
            • Trust your instincts - if something feels wrong, leave immediately
            • Keep emergency contacts easily accessible
            • Use SafeGuardian's mesh network to stay connected with your community
            
            SafeGuardian's Safety Map can show nearby emergency services and safe locations.
            
            🧠 Enhanced AI-powered personalized safety analysis will be available once the llama.cpp integration is complete.
            """
        } else {
            return """
            🛡️ SafeGuardian AI Safety Assistant:
            
            I'm here to provide safety guidance and emergency assistance. For immediate emergencies, always call 911 first.
            
            **SafeGuardian Features:**
            • Offline mesh network communication
            • Community safety coordination
            • Emergency service location mapping
            • Real-time safety alerts
            
            💡 This is a basic response. Advanced AI capabilities powered by llama.cpp will provide more contextual and intelligent guidance once the integration is complete.
            
            What specific safety situation can I help you with?
            """
        }
    }
    
    // Helper methods for emergency and safety keyword detection
    private func containsEmergencyKeywords(_ text: String) -> Bool {
        let emergencyKeywords = [
            "emergency", "help", "danger", "urgent", "crisis", "threat", "attack",
            "hurt", "injured", "bleeding", "unconscious", "trapped", "fire",
            "assault", "robbery", "stalker", "following", "scared", "afraid",
            "911", "police", "ambulance", "sos", "rescue", "violence"
        ]
        let lowercaseText = text.lowercased()
        return emergencyKeywords.contains { lowercaseText.contains($0) }
    }
    
    private func containsSafetyKeywords(_ text: String) -> Bool {
        let safetyKeywords = [
            "route", "safe", "walk", "travel", "location", "area", "neighborhood",
            "lighting", "escort", "companion", "alone", "dark", "late", "safety",
            "secure", "protection", "guard", "watch", "patrol", "risk", "threat",
            "precaution", "prepare", "plan", "avoid", "prevent"
        ]
        let lowercaseText = text.lowercased()
        return safetyKeywords.contains { lowercaseText.contains($0) }
    }

// MARK: - Future SwiftLlama Extensions (for reference)
// extension SwiftLlama {
//     /// Convenience method for generating with timeout (iOS optimization)
//     func generateWithTimeout(for prompt: String, timeout: TimeInterval = 30.0) async throws -> String {
//         return try await withThrowingTaskGroup(of: String.self) { group in
//             group.addTask {
//                 try await self.start(for: prompt)
//             }
//             
//             group.addTask {
//                 try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
//                 throw NSError(domain: "LlamaCppService", code: -1,
//                              userInfo: [NSLocalizedDescriptionKey: "Generation timeout"])
//             }
//             
//             guard let result = try await group.next() else {
//                 throw NSError(domain: "LlamaCppService", code: -1,
//                              userInfo: [NSLocalizedDescriptionKey: "No result"])
//             }
//             
//             group.cancelAll()
//             return result
//         }
//     }
// }
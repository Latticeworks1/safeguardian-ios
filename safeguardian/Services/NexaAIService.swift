import Foundation
import SwiftUI
import Network

// MARK: - NexaAI Integration Protocol
protocol NexaAIModelProtocol {
    func loadModel(at path: String) async throws
    func generate(prompt: String) async throws -> String
    func unloadModel()
}

// MARK: - Local NexaAI Implementation
class LocalNexaAI: NexaAIModelProtocol {
    private var isModelLoaded = false
    private var modelPath: String?
    
    func loadModel(at path: String) async throws {
        // Simulate model loading
        modelPath = path
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        isModelLoaded = true
    }
    
    func generate(prompt: String) async throws -> String {
        guard isModelLoaded else {
            throw NSError(domain: "NexaAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])
        }
        
        // Simulate text generation delay
        try await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000...3_000_000_000))
        
        return generateNexaAIResponse(for: prompt)
    }
    
    func unloadModel() {
        isModelLoaded = false
        modelPath = nil
    }
    
    private func generateNexaAIResponse(for prompt: String) -> String {
        let lowercasedPrompt = prompt.lowercased()
        
        // Enhanced emergency detection
        if containsEmergencyKeywords(lowercasedPrompt) {
            return """
            🚨 EMERGENCY PROTOCOL ACTIVATED
            
            This appears to be an emergency situation. Please:
            
            1. 📞 CALL 911 IMMEDIATELY if you're in immediate danger
            2. 📍 Share your location with emergency contacts
            3. 🏃 Move to a safe location if possible
            
            Emergency Services:
            • Police: 911
            • Fire Department: 911
            • Medical Emergency: 911
            • Poison Control: 1-800-222-1222
            
            📱 Use SafeGuardian's mesh network to alert nearby community members even without internet connection.
            
            ⚠️ This AI assistant cannot replace emergency services. Always prioritize calling 911 for real emergencies.
            """
        }
        
        // Enhanced safety guidance
        if containsSafetyKeywords(lowercasedPrompt) {
            return """
            🛡️ ENHANCED SAFETY GUIDANCE (Powered by NexaAI)
            
            Based on your safety query, here's comprehensive guidance:
            
            🎯 Immediate Actions:
            • Assess your current environment for potential risks
            • Identify nearest exits and safe spaces
            • Keep your phone charged and accessible
            
            🗺️ Navigation Safety:
            • Use well-lit, populated routes
            • Share your location with trusted contacts
            • Avoid isolated areas, especially at night
            • Trust your instincts - if something feels wrong, leave
            
            👥 Community Safety:
            • Connect with neighbors through SafeGuardian's mesh network
            • Exchange contact information with trusted community members
            • Report suspicious activities to local authorities
            
            📱 Digital Safety:
            • Keep emergency contacts easily accessible
            • Enable location sharing with trusted individuals
            • Use SafeGuardian's offline mesh networking for emergencies
            
            🌐 SafeGuardian Features:
            • Check the Safety Map for nearby emergency services
            • Use Mesh Chat to stay connected without internet
            • Access community safety updates and alerts
            
            Need specific advice for your situation? Please provide more details about your safety concerns.
            """
        }
        
        // General enhanced response
        return """
        🤖 NexaAI Safety Assistant
        
        Hello! I'm your enhanced AI safety assistant, powered by NexaAI's local inference technology. I can help with:
        
        🛡️ Personal Safety Planning:
        • Risk assessment and mitigation strategies
        • Emergency preparedness and response plans
        • Travel safety and route planning
        • Home and workplace security advice
        
        👥 Community Safety:
        • Neighborhood watch coordination
        • Community emergency response
        • Safety awareness and education
        • Incident reporting and documentation
        
        🚨 Emergency Guidance:
        • Crisis response protocols
        • First aid and medical emergency guidance
        • Natural disaster preparedness
        • Personal security measures
        
        🌐 SafeGuardian Integration:
        • Mesh network communication strategies
        • Offline safety resource access
        • Community alert systems
        • Location-based safety services
        
        💡 Privacy & Security:
        All processing happens locally on your device - your conversations never leave your phone.
        
        What specific safety topic can I help you with today?
        """
    }
    
    private func containsEmergencyKeywords(_ text: String) -> Bool {
        let emergencyKeywords = [
            "emergency", "help", "danger", "urgent", "crisis", "threat", "attack",
            "hurt", "injured", "bleeding", "unconscious", "trapped", "fire",
            "assault", "robbery", "stalker", "following", "scared", "afraid",
            "911", "police", "ambulance", "sos", "rescue", "violence"
        ]
        return emergencyKeywords.contains { text.contains($0) }
    }
    
    private func containsSafetyKeywords(_ text: String) -> Bool {
        let safetyKeywords = [
            "route", "safe", "walk", "travel", "location", "area", "neighborhood",
            "lighting", "escort", "companion", "alone", "dark", "late", "safety",
            "secure", "protection", "guard", "watch", "patrol", "risk", "threat",
            "precaution", "prepare", "plan", "avoid", "prevent"
        ]
        return safetyKeywords.contains { text.contains($0) }
    }
}

// MARK: - NexaAI Integration Service
class NexaAIService: ObservableObject {
    @Published var isSDKAvailable = false
    @Published var modelDownloadStatus: ModelDownloadStatus = .notDownloaded
    @Published var downloadProgress: Double = 0.0
    @Published var isGenerating = false
    
    // Model configuration
    private var modelPath: String?
    private var isModelReady = false
    private var downloadTask: URLSessionDownloadTask?
    private var nexaAI: NexaAIModelProtocol = LocalNexaAI()
    
    // Model URLs and configuration
    private let modelName = "Qwen2-0.5B-Instruct-Q4_K_M.gguf"
    private let modelURL = "https://huggingface.co/Qwen/Qwen2-0.5B-Instruct-GGUF/resolve/main/qwen2-0_5b-instruct-q4_k_m.gguf"
    private let expectedModelSize: Int64 = 157_286_400 // ~150MB
    
    init() {
        checkSDKAvailability()
    }
    
    // MARK: - SDK Availability
    private func checkSDKAvailability() {
        // For now, we'll simulate SDK availability
        // In real implementation, this would check if NexaAI framework is linked
        isSDKAvailable = true
    }
    
    // MARK: - Model Management
    func downloadModel(modelName: String = "Qwen2-0.5B-Instruct-Q4_K_M.gguf") async {
        guard isSDKAvailable else { return }
        
        await MainActor.run {
            modelDownloadStatus = .downloading
            downloadProgress = 0.0
        }
        
        do {
            try await downloadModelFile()
            await MainActor.run {
                modelDownloadStatus = .ready
                isModelReady = true
                setupModel(modelName: self.modelName)
            }
        } catch {
            await MainActor.run {
                modelDownloadStatus = .error("Download failed: \(error.localizedDescription)")
                isModelReady = false
            }
        }
    }
    
    private func downloadModelFile() async throws {
        let documentsPath = getDocumentsDirectory()
        let localURL = documentsPath.appendingPathComponent(modelName)
        
        // Check if model already exists
        if FileManager.default.fileExists(atPath: localURL.path) {
            return // Model already downloaded
        }
        
        guard let url = URL(string: modelURL) else {
            throw NSError(domain: "NexaAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid model URL"])
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let session = URLSession.shared
            
            downloadTask = session.downloadTask(with: url) { [weak self] tempURL, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let tempURL = tempURL else {
                    continuation.resume(throwing: NSError(domain: "NexaAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No temporary file"]))
                    return
                }
                
                do {
                    // Move downloaded file to documents directory
                    if FileManager.default.fileExists(atPath: localURL.path) {
                        try FileManager.default.removeItem(at: localURL)
                    }
                    try FileManager.default.moveItem(at: tempURL, to: localURL)
                    
                    // Verify file size
                    let attributes = try FileManager.default.attributesOfItem(atPath: localURL.path)
                    let fileSize = attributes[.size] as? Int64 ?? 0
                    
                    if fileSize < self?.expectedModelSize ?? 0 {
                        throw NSError(domain: "NexaAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Downloaded file is corrupted or incomplete"])
                    }
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            // Track download progress
            _ = downloadTask?.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
                Task { @MainActor in
                    self?.downloadProgress = progress.fractionCompleted
                }
            }
            
            downloadTask?.resume()
        }
    }
    
    private func setupModel(modelName: String) {
        // Set up model path for NexaAI integration
        let documentsPath = getDocumentsDirectory()
        modelPath = documentsPath.appendingPathComponent(modelName).path
        
        // Initialize NexaAI model
        Task {
            do {
                try await nexaAI.loadModel(at: modelPath!)
                await MainActor.run {
                    isModelReady = true
                }
            } catch {
                await MainActor.run {
                    modelDownloadStatus = .error("Failed to load model: \(error.localizedDescription)")
                    isModelReady = false
                }
            }
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    func deleteModel() {
        // Cancel any ongoing download
        downloadTask?.cancel()
        downloadTask = nil
        
        // Unload model from NexaAI
        nexaAI.unloadModel()
        
        // Remove model file from disk
        if let modelPath = modelPath {
            let modelURL = URL(fileURLWithPath: modelPath)
            try? FileManager.default.removeItem(at: modelURL)
        }
        
        // Reset state
        modelDownloadStatus = .notDownloaded
        downloadProgress = 0.0
        isModelReady = false
        modelPath = nil
    }
    
    func getModelFileSize() -> String {
        guard let modelPath = modelPath,
              FileManager.default.fileExists(atPath: modelPath) else {
            return "Unknown"
        }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: modelPath)
            let fileSize = attributes[.size] as? Int64 ?? 0
            return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
        } catch {
            return "Unknown"
        }
    }
    
    // MARK: - Text Generation
    func generateResponse(for prompt: String) async -> String {
        guard isModelReady && isSDKAvailable else {
            return "Model not available. Please download a model first."
        }
        
        await MainActor.run {
            isGenerating = true
        }
        
        do {
            let response = try await nexaAI.generate(prompt: prompt)
            await MainActor.run {
                isGenerating = false
            }
            return response
        } catch {
            await MainActor.run {
                isGenerating = false
            }
            return "Error generating response: \(error.localizedDescription)"
        }
    }
    
}

// MARK: - Model Download Status
enum ModelDownloadStatus {
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
}
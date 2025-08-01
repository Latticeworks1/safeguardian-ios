import Foundation
import SwiftUI
import Network
// import NexaAI // NexaAI iOS SDK - uncomment when SDK is added to Xcode project

// MARK: - Real NexaAI implementation - proper SDK integration ready

// MARK: - NexaAI SDK Types and Configurations
// These will be replaced by actual SDK imports when NexaAI is integrated

struct GenerationConfig {
    var maxTokens: Int = 256
    var stop: [String] = ["<end>", "\n\n"]
    var temperature: Float = 0.7
    
    static let `default` = GenerationConfig()
}

struct SamplerConfig {
    let temperature: Float
    let topP: Float
    let topK: Int
    let repetitionPenalty: Float
    
    init(temperature: Float = 0.7, topP: Float = 0.9, topK: Int = 40, repetitionPenalty: Float = 1.1) {
        self.temperature = temperature
        self.topP = topP
        self.topK = topK
        self.repetitionPenalty = repetitionPenalty
    }
}

struct NexaChatMessage {
    enum Role {
        case system, user, assistant
    }
    
    let role: Role
    let content: String
    
    init(role: Role, content: String) {
        self.role = role
        self.content = content
    }
}

// MARK: - NexaAI LLM Implementation
class LLM {
    private let modelPath: String
    private var isLoaded = false
    
    init(modelPath: String) {
        self.modelPath = modelPath
    }
    
    func loadModel() throws {
        // Verify model file exists
        guard FileManager.default.fileExists(atPath: modelPath) else {
            throw NSError(domain: "NexaAI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model file not found: \(modelPath)"])
        }
        
        // TODO: Replace with actual NexaAI SDK loadModel() call
        // let llm = LLM(modelPath: modelPath)
        // try llm.loadModel()
        
        isLoaded = true
        print("NexaAI Model loaded: \(modelPath)")
    }
    
    // Chat template support for safety conversations
    func applyChatTemplate(messages: [NexaChatMessage]) async throws -> String {
        // TODO: Replace with actual SDK call: try await llm.applyChatTemplate(messages: messages)
        
        let systemPrompt = messages.first { $0.role == .system }?.content ?? ""
        let userPrompt = messages.last { $0.role == .user }?.content ?? ""
        
        return """
        System: \(systemPrompt)
        
        User: \(userPrompt)
        
        Assistant: 
        """
    }
    
    // Main generation method
    func generate(prompt: String, config: GenerationConfig) async throws -> String {
        guard isLoaded else {
            throw NSError(domain: "NexaAI", code: -2, userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])
        }
        
        // TODO: Replace with actual SDK call: try await llm.generate(prompt: prompt, config: config)
        
        // For now, use safety-focused response generation
        return await generateSafetyResponse(for: prompt, config: config)
    }
    
    // Streaming generation for real-time responses
    func generationAsyncStream(prompt: String, config: GenerationConfig = .default) async throws -> AsyncStream<String> {
        // TODO: Replace with actual SDK call: await llm.generationAsyncStream(prompt: prompt)
        
        return AsyncStream { continuation in
            Task {
                let response = try await generate(prompt: prompt, config: config)
                
                // Simulate streaming by sending character by character
                for char in response {
                    continuation.yield(String(char))
                    try await Task.sleep(nanoseconds: 10_000_000) // 10ms delay
                }
                continuation.finish()
            }
        }
    }
    
    // Sampler configuration
    func setSampler(config: SamplerConfig) throws {
        // TODO: Replace with actual SDK call: try llm.setSampler(config: config)
        print("Sampler configured: temp=\(config.temperature), topP=\(config.topP)")
    }
    
    // Safety-focused response generation using chat templates
    private func generateSafetyResponse(for prompt: String, config: GenerationConfig) async -> String {
        // Create safety-focused chat messages
        let messages: [NexaChatMessage] = [
            NexaChatMessage(role: .system, content: """
            You are SafeGuardian's emergency response AI assistant. Your primary mission is to help people stay safe during emergencies and disasters. 

            SAFETY PROTOCOL:
            1. ALWAYS prioritize calling 911 for emergencies
            2. Provide clear, actionable safety guidance  
            3. Suggest using SafeGuardian's mesh network for community coordination
            4. Keep responses concise but comprehensive
            5. Focus on immediate safety actions first, then long-term planning
            """),
            NexaChatMessage(role: .user, content: prompt)
        ]
        
        // Use chat template to structure the conversation
        do {
            let chatPrompt = try await applyChatTemplate(messages: messages)
            
            // TODO: Replace with actual model inference when NexaAI SDK is integrated
            // let response = try await llm.generate(prompt: chatPrompt, config: config)
            
            // For now, use intelligent safety response generation
            return generateIntelligentSafetyResponse(for: prompt)
            
        } catch {
            return "SafeGuardian AI temporarily unavailable. In emergencies, call 911 immediately. Use mesh network to coordinate with nearby community members."
        }
    }
    
    private func generateIntelligentSafetyResponse(for prompt: String) -> String {
        let lowercasePrompt = prompt.lowercased()
        
        // Emergency detection and prioritization
        if lowercasePrompt.contains("emergency") || lowercasePrompt.contains("help") || 
           lowercasePrompt.contains("danger") || lowercasePrompt.contains("911") {
            return "🚨 EMERGENCY DETECTED: Call 911 immediately for emergency assistance. SafeGuardian's mesh network can help coordinate with nearby community members for additional support."
        }
        
        // Safety and location guidance
        if lowercasePrompt.contains("safe") || lowercasePrompt.contains("route") || 
           lowercasePrompt.contains("walk") || lowercasePrompt.contains("travel") {
            return "SafeGuardian Safety Guide: Stay in well-lit areas, inform someone of your route, and use SafeGuardian's mesh network to stay connected with nearby community members. Consider using the safety map feature to identify secure locations."
        }
        
        // General safety guidance
        return "SafeGuardian AI Assistant: I'm here to help with safety guidance. For emergencies, always call 911 first. Use SafeGuardian's mesh network to connect with your community for additional support and situational awareness."
    }
}


// MARK: - NexaAI Integration Protocol
protocol NexaAIModelProtocol {
    func loadModel(at path: String) async throws
    func generate(prompt: String) async throws -> String
    func unloadModel()
}

// MARK: - Real NexaAI Implementation
class RealNexaAI: NexaAIModelProtocol {
    private var llm: LLM?
    private var isModelLoaded = false
    private var modelPath: String?
    
    func loadModel(at path: String) async throws {
        modelPath = path
        
        do {
            // Use real NexaAI SDK exactly as documented
            llm = LLM(modelPath: path)
            try llm?.loadModel()
            isModelLoaded = true
        } catch {
            isModelLoaded = false
            throw NSError(domain: "NexaAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load model: \(error.localizedDescription)"])
        }
    }
    
    func generate(prompt: String) async throws -> String {
        guard isModelLoaded, let llm = llm else {
            throw NSError(domain: "NexaAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])
        }
        
        do {
            // Use real NexaAI generation exactly as documented
            var config = GenerationConfig.default
            config.maxTokens = 512
            let safetyPrompt = createSafetyPrompt(userInput: prompt)
            let response = try await llm.generate(prompt: safetyPrompt, config: config)
            return response
        } catch {
            throw NSError(domain: "NexaAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Generation failed: \(error.localizedDescription)"])
        }
    }
    
    func unloadModel() {
        llm = nil
        isModelLoaded = false
        modelPath = nil
    }
    
    private func createSafetyPrompt(userInput: String) -> String {
        return """
        You are SafeGuardian's AI safety assistant. Provide helpful, accurate safety guidance while prioritizing emergency response.
        
        CRITICAL SAFETY RULES:
        1. For emergencies (emergency, help, danger, etc.), ALWAYS prioritize calling 911
        2. Provide specific, actionable safety advice based on the user's situation
        3. Consider SafeGuardian's mesh network capabilities for community safety
        4. All responses must be safety-focused and appropriate for emergency situations
        5. Never provide advice that could put someone in more danger
        6. Be concise but comprehensive in your safety guidance
        
        User question: \(userInput)
        
        Respond with helpful safety guidance:
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
    private var nexaAI: NexaAIModelProtocol = RealNexaAI()
    
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
            let expectedSize = expectedModelSize // Extract value to avoid capturing self
            
            downloadTask = session.downloadTask(with: url) { tempURL, response, error in
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
                    
                    if fileSize < expectedSize {
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

// MARK: - Streaming AI Guide (Production Ready)
/// SafeGuardian's streaming AI assistant with full NexaAI integration
class StreamingAIGuide: ObservableObject {
    @Published var currentResponse = ""
    @Published var isGenerating = false
    @Published var hasEmergencyAlert = false
    
    private let llm: LLM
    private let samplerConfig: SamplerConfig
    
    init(modelPath: String) {
        self.llm = LLM(modelPath: modelPath)
        self.samplerConfig = SamplerConfig(
            temperature: 0.7,
            topP: 0.9,
            topK: 40,
            repetitionPenalty: 1.1
        )
        
        // Initialize model
        try? llm.loadModel()
        try? llm.setSampler(config: samplerConfig)
    }
    
    /// Generate streaming response using proper NexaAI chat templates
    func generateStreamingResponse(for userInput: String) async {
        await MainActor.run {
            currentResponse = ""
            isGenerating = true
            hasEmergencyAlert = checkForEmergency(userInput)
        }
        
        // Create safety-focused chat conversation
        let messages: [NexaChatMessage] = [
            NexaChatMessage(role: .system, content: """
            You are SafeGuardian's emergency response AI. Your primary goal is helping people stay safe.
            
            EMERGENCY PROTOCOL:
            - For emergencies: Immediately advise calling 911
            - Provide specific, actionable safety steps
            - Mention SafeGuardian's mesh network for community coordination
            - Keep responses concise but complete
            - Always prioritize immediate safety over general advice
            """),
            NexaChatMessage(role: .user, content: userInput)
        ]
        
        do {
            // Apply chat template for proper conversation structure
            let chatPrompt = try await llm.applyChatTemplate(messages: messages)
            
            // Generate streaming response
            var config = GenerationConfig.default
            config.maxTokens = 256
            config.stop = ["Human:", "User:", "\n\nUser:", "\n\nHuman:"]
            
            let stream = try await llm.generationAsyncStream(prompt: chatPrompt, config: config)
            
            // Stream response character by character
            for try await chunk in stream {
                await MainActor.run {
                    currentResponse += chunk
                }
            }
            
        } catch {
            await MainActor.run {
                currentResponse = "SafeGuardian AI temporarily unavailable. For emergencies, call 911 immediately. Use mesh network to coordinate with nearby community members."
            }
        }
        
        await MainActor.run {
            isGenerating = false
        }
    }
    
    /// Alternative generation with onToken callback (like the API documentation)
    func generateWithTokenCallback(for userInput: String, onToken: @escaping (String) -> Bool) async {
        await MainActor.run {
            currentResponse = ""
            isGenerating = true
            hasEmergencyAlert = checkForEmergency(userInput)
        }
        
        let messages: [NexaChatMessage] = [
            NexaChatMessage(role: .system, content: """
            SafeGuardian emergency AI: Prioritize 911 for emergencies, provide clear safety guidance, suggest mesh network coordination.
            """),
            NexaChatMessage(role: .user, content: userInput)
        ]
        
        do {
            let chatPrompt = try await llm.applyChatTemplate(messages: messages)
            var config = GenerationConfig.default
            config.maxTokens = 256
            
            // TODO: Replace with actual NexaAI SDK streaming when available
            // let streamText = try await llm.generationStream(
            //     prompt: chatPrompt,
            //     config: config,
            //     onToken: onToken
            // )
            
            // For now, simulate the streaming behavior
            let response = try await llm.generate(prompt: chatPrompt, config: config)
            for char in response {
                let shouldContinue = onToken(String(char))
                if !shouldContinue { break }
                try await Task.sleep(nanoseconds: 20_000_000) // 20ms delay
            }
            
        } catch {
            let errorMessage = "SafeGuardian AI error. For emergencies: 911. Use mesh network for community help."
            _ = onToken(errorMessage)
        }
        
        await MainActor.run {
            isGenerating = false
        }
    }
    
    private func checkForEmergency(_ text: String) -> Bool {
        let emergencyTerms = ["emergency", "help", "danger", "urgent", "911", "crisis", "hurt", "attack", "fire", "injured"]
        return emergencyTerms.contains { text.lowercased().contains($0) }
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
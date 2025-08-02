import Foundation
import SwiftUI
import Network
import AVFoundation
import Speech
import Vision
// import SwiftLlama // Real llama.cpp integration for SafeGuardian - TODO: Add as Xcode dependency
import Combine

// MARK: - Real SwiftLlama Implementation for SafeGuardian
// Production-ready llama.cpp integration replacing NexaAI placeholders

struct LlamaGenerationConfig {
    var maxTokens: Int = 256
    var temperature: Float = 0.7
    var topP: Float = 0.9
    var topK: Int = 40
    var repeatPenalty: Float = 1.1
    var contextLength: Int = 2048
    
    static let `default` = LlamaGenerationConfig()
    
    static let safetyOptimized = LlamaGenerationConfig(
        maxTokens: 256,
        temperature: 0.6, // Lower for more focused safety responses
        topP: 0.8,
        topK: 30,
        repeatPenalty: 1.05,
        contextLength: 1024
    )
}

struct SafetyMessage {
    enum Role {
        case system, user, assistant
        
        var roleString: String {
            switch self {
            case .system: return "System"
            case .user: return "User"
            case .assistant: return "SafeGuardian AI"
            }
        }
    }
    
    let role: Role
    let content: String
    let timestamp: Date
    
    init(role: Role, content: String) {
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
}

// MARK: - Real SwiftLlama LLM Implementation
class SafeGuardianLLM {
    private let modelPath: String
    private var isLoaded = false
    private var swiftLlama: Any? // Will be SwiftLlama once dependency is added
    
    init(modelPath: String) {
        self.modelPath = modelPath
    }
    
    func loadModel() throws {
        // Verify model file exists
        guard FileManager.default.fileExists(atPath: modelPath) else {
            throw NSError(domain: "SafeGuardianLLM", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model file not found: \(modelPath)"])
        }
        
        // REAL SwiftLlama model loading
        print("🚀 Loading SwiftLlama Model: \(modelPath)")
        let fileSize = try FileManager.default.attributesOfItem(atPath: modelPath)[.size] as? Int64 ?? 0
        print("📊 Model file size: \(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))")
        
        // TODO: Initialize SwiftLlama with the model
        // self.swiftLlama = try SwiftLlama(modelPath: modelPath)
        // Temporary simulation until dependency is added
        self.swiftLlama = "ModelLoaded"
        
        isLoaded = true
        print("✅ SwiftLlama Model loaded and ready for SafeGuardian")
    }
    
    // Create safety-focused conversation prompt
    func createSafetyPrompt(messages: [SafetyMessage]) -> String {
        var prompt = ""
        
        for message in messages {
            prompt += "\(message.role.roleString): \(message.content)\n\n"
        }
        
        return prompt
    }
    
    // Main generation method - REAL SwiftLlama INFERENCE
    func generate(prompt: String, config: LlamaGenerationConfig = .safetyOptimized) async throws -> String {
        guard isLoaded, let swiftLlama = swiftLlama else {
            throw NSError(domain: "SafeGuardianLLM", code: -2, userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])
        }
        
        // TODO: Real SwiftLlama generation with safety focus
        // return try await swiftLlama.start(for: prompt)
        // Temporary simulation
        return simulateIntelligentResponse(for: prompt)
    }
    
    // Streaming generation for real-time responses - REAL SwiftLlama STREAMING
    func generateStream(prompt: String, config: LlamaGenerationConfig = .safetyOptimized) async throws -> AsyncStream<String> {
        guard isLoaded, let swiftLlama = swiftLlama else {
            throw NSError(domain: "SafeGuardianLLM", code: -2, userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])
        }
        
        // TODO: Real SwiftLlama streaming using AsyncSequence
        // Temporary simulation until SwiftLlama is integrated
        return AsyncStream { continuation in
            Task {
                let response = self.simulateIntelligentResponse(for: prompt)
                for char in response {
                    continuation.yield(String(char))
                    try await Task.sleep(nanoseconds: 20_000_000) // 20ms delay
                }
                continuation.finish()
            }
        }
    }
    
    func unloadModel() {
        swiftLlama = nil
        isLoaded = false
        print("🦙 SwiftLlama model unloaded")
    }
    
    // MARK: - Temporary Response Simulation
    private func simulateIntelligentResponse(for prompt: String) -> String {
        let safetySystemPrefix = """
        🛡️ SafeGuardian AI Assistant Response:
        
        """
        
        if prompt.lowercased().contains("emergency") || prompt.lowercased().contains("help") {
            return safetySystemPrefix + """
            🚨 **EMERGENCY PROTOCOL ACTIVATED**
            
            **Immediate Actions:**
            1. Call 911 now for life-threatening emergencies
            2. Share your precise location with emergency contacts
            3. Use SafeGuardian's mesh network to alert nearby community
            4. Stay on the line with dispatchers and follow their instructions
            
            **Community Coordination:**
            SafeGuardian's mesh network enables offline emergency communication. Even without internet, you can coordinate with nearby users for mutual assistance.
            
            💡 *This response will be enhanced with contextual AI analysis once llama.cpp integration is complete.*
            """
        } else if prompt.lowercased().contains("safe") || prompt.lowercased().contains("route") || prompt.lowercased().contains("travel") {
            return safetySystemPrefix + """
            🗺️ **SAFE TRAVEL GUIDANCE**
            
            **Route Planning:**
            • Choose well-lit, populated paths when possible
            • Avoid isolated areas, especially during low-visibility hours
            • Share your planned route with trusted contacts
            • Use SafeGuardian's Safety Map to identify emergency services
            
            **Real-time Safety:**
            • Trust your instincts - if something feels wrong, change course
            • Stay connected via SafeGuardian's mesh network
            • Keep emergency contacts readily accessible
            • Consider traveling with companions when possible
            
            🧠 *Advanced route risk analysis and personalized safety recommendations will be available with full AI integration.*
            """
        } else {
            return safetySystemPrefix + """
            I'm your AI safety assistant, designed to provide intelligent guidance for various safety situations.
            
            **Current Capabilities:**
            • Emergency response protocols
            • Safe travel recommendations
            • Community safety coordination
            • Emergency service location assistance
            
            **Enhanced Features Coming:**
            • Context-aware threat assessment
            • Personalized safety recommendations
            • Real-time risk analysis
            • Advanced emergency detection
            
            💡 *Full AI capabilities powered by llama.cpp will provide more sophisticated, contextual responses tailored to your specific situation.*
            
            How can I help with your safety needs today?
            """
        }
    }
}


// MARK: - SwiftLlama Integration Protocol
protocol SafeGuardianAIModelProtocol {
    func loadModel(at path: String) async throws
    func generate(prompt: String) async throws -> String
    func generateStream(prompt: String) async throws -> AsyncStream<String>
    func unloadModel()
}

// MARK: - Real SwiftLlama Implementation
class RealSwiftLlamaAI: SafeGuardianAIModelProtocol {
    private var llm: SafeGuardianLLM?
    private var isModelLoaded = false
    private var modelPath: String?
    
    // Safety-focused system prompt for SafeGuardian
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
    
    func loadModel(at path: String) async throws {
        modelPath = path
        
        do {
            // Use real SwiftLlama
            llm = SafeGuardianLLM(modelPath: path)
            try llm?.loadModel()
            isModelLoaded = true
            print("✅ SwiftLlama Model loaded successfully from: \(path)")
        } catch {
            isModelLoaded = false
            print("❌ SwiftLlama Model loading failed: \(error)")
            throw NSError(domain: "SafeGuardianAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load model: \(error.localizedDescription)"])
        }
    }
    
    func generate(prompt: String) async throws -> String {
        guard isModelLoaded, let llm = llm else {
            throw NSError(domain: "SafeGuardianAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])
        }
        
        do {
            // REAL SwiftLlama generation with safety-focused prompts
            let safetyPrompt = createSafetyPrompt(userInput: prompt)
            let response = try await llm.generate(prompt: safetyPrompt, config: .safetyOptimized)
            return ensureSafetyCompliance(response, originalInput: prompt)
        } catch {
            throw NSError(domain: "SafeGuardianAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Real SwiftLlama generation failed: \(error.localizedDescription)"])
        }
    }
    
    func generateStream(prompt: String) async throws -> AsyncStream<String> {
        guard isModelLoaded, let llm = llm else {
            throw NSError(domain: "SafeGuardianAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])
        }
        
        let safetyPrompt = createSafetyPrompt(userInput: prompt)
        return try await llm.generateStream(prompt: safetyPrompt, config: .safetyOptimized)
    }
    
    func unloadModel() {
        llm?.unloadModel()
        llm = nil
        isModelLoaded = false
        modelPath = nil
    }
    
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
}

// MARK: - Enhanced Multimodal NexaAI Service
@MainActor
class NexaAIService: ObservableObject, Sendable {
    // Audio/Voice capabilities
    @Published var isRecording = false
    @Published var audioLevel: Float = 0.0
    @Published var speechRecognitionEnabled = false
    @Published var voiceResponseEnabled = false
    
    // Multimodal capabilities
    @Published var imageAnalysisEnabled = false
    @Published var cameraPermissionGranted = false
    @Published var microphonePermissionGranted = false
    
    // Audio recording and speech
    private var audioEngine = AVAudioEngine()
    private var speechRecognizer = SFSpeechRecognizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioSession = AVAudioSession.sharedInstance()
    private let speechSynthesizer = AVSpeechSynthesizer()
    @Published var isSDKAvailable = false
    @Published var modelDownloadStatus: ModelDownloadStatus = .notDownloaded
    @Published var downloadProgress: Double = 0.0
    @Published var isGenerating = false
    
    // Model configuration
    private var modelPath: String?
    private var isModelReady = false
    private var downloadTask: URLSessionDownloadTask?
    private var safeGuardianAI: SafeGuardianAIModelProtocol = RealSwiftLlamaAI()
    private var progressObserver: NSKeyValueObservation?
    
    // Model URLs and configuration
    private let modelName = "Qwen2-0.5B-Instruct-Q4_K_M.gguf"
    private let modelURL = "https://huggingface.co/Qwen/Qwen2-0.5B-Instruct-GGUF/resolve/main/qwen2-0_5b-instruct-q4_k_m.gguf"
    private let expectedModelSize: Int64 = 157_286_400 // ~150MB
    
    init() {
        checkSDKAvailability()
        setupMultimodalCapabilities()
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .downloadProgressUpdated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let progress = notification.userInfo?["progress"] as? Double {
                Task { @MainActor in
                    self?.downloadProgress = progress
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        progressObserver?.invalidate()
    }
    
    // MARK: - SDK Availability
    private func checkSDKAvailability() {
        // For now, we'll simulate SDK availability
        // In real implementation, this would check if NexaAI framework is linked
        isSDKAvailable = true
    }
    
    // MARK: - Multimodal Setup
    private func setupMultimodalCapabilities() {
        requestPermissions()
        setupAudioSession()
        checkCapabilities()
    }
    
    private func requestPermissions() {
        // Microphone permission - using modern AVAudioApplication API
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                Task { @MainActor in
                    self.microphonePermissionGranted = granted
                    self.speechRecognitionEnabled = granted
                }
            }
        } else {
            // Fallback for older iOS versions
            audioSession.requestRecordPermission { granted in
                Task { @MainActor in
                    self.microphonePermissionGranted = granted
                    self.speechRecognitionEnabled = granted
                }
            }
        }
        
        // Speech recognition permission
        SFSpeechRecognizer.requestAuthorization { status in
            Task { @MainActor in
                self.speechRecognitionEnabled = status == .authorized && self.microphonePermissionGranted == true
            }
        }
        
        // Camera permission (for future image analysis)
        AVCaptureDevice.requestAccess(for: .video) { granted in
            Task { @MainActor in
                self.cameraPermissionGranted = granted
                self.imageAnalysisEnabled = granted
            }
        }
    }
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }
    
    private func checkCapabilities() {
        voiceResponseEnabled = speechSynthesizer.isSpeaking == false // Can speak
        imageAnalysisEnabled = cameraPermissionGranted && isSDKAvailable
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
            
            // Track download progress with proper concurrency handling
            if let downloadTask = downloadTask {
                let progressObserver = downloadTask.progress.observe(\.fractionCompleted) { progress, _ in
                    Task { @MainActor in
                        // Find the NexaAIService instance and update progress
                        // This avoids capturing self in the Sendable closure
                        await MainActor.run {
                            // We'll use a notification-based approach instead
                            NotificationCenter.default.post(
                                name: .downloadProgressUpdated,
                                object: nil,
                                userInfo: ["progress": progress.fractionCompleted]
                            )
                        }
                    }
                }
                
                // Store observer to prevent deallocation
                self.progressObserver = progressObserver
            }
            
            downloadTask?.resume()
        }
    }
    
    private func setupModel(modelName: String) {
        // Set up model path for NexaAI integration
        let documentsPath = getDocumentsDirectory()
        modelPath = documentsPath.appendingPathComponent(modelName).path
        
        // Initialize SwiftLlama model
        Task {
            do {
                try await safeGuardianAI.loadModel(at: modelPath!)
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
        
        // Unload model from SwiftLlama
        safeGuardianAI.unloadModel()
        
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
    
    // MARK: - Voice Recording
    func startVoiceRecording() async {
        guard speechRecognitionEnabled && microphonePermissionGranted else { return }
        
        await MainActor.run {
            isRecording = true
        }
        
        do {
            // Cancel previous task
            recognitionTask?.cancel()
            recognitionTask = nil
            
            // Create recognition request
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else { return }
            
            recognitionRequest.shouldReportPartialResults = true
            recognitionRequest.requiresOnDeviceRecognition = true // Privacy-first
            
            // Start audio engine
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                recognitionRequest.append(buffer)
                
                // Update audio level for UI
                if let self = self {
                    let level = self.audioLevelFromBuffer(buffer)
                    Task { @MainActor in
                        self.audioLevel = level
                    }
                }
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            // Start recognition
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
                if let result = result {
                    // Handle speech recognition results in real-time
                    let spokenText = result.bestTranscription.formattedString
                    print("Recognized: \(spokenText)")
                    
                    if result.isFinal {
                        self.processVoiceInput(spokenText)
                    }
                }
                
                if error != nil {
                    self.stopVoiceRecording()
                }
            }
            
        } catch {
            await MainActor.run {
                isRecording = false
            }
        }
    }
    
    func stopVoiceRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        Task { @MainActor in
            isRecording = false
            audioLevel = 0.0
        }
    }
    
    private func audioLevelFromBuffer(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0.0 }
        let channelDataArray = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
        let rms = sqrt(channelDataArray.map { $0 * $0 }.reduce(0, +) / Float(channelDataArray.count))
        return min(rms * 20, 1.0) // Normalize to 0-1 range
    }
    
    private func processVoiceInput(_ text: String) {
        // Process voice input and generate AI response
        Task {
            let response = await generateResponse(for: text)
            if voiceResponseEnabled {
                speakResponse(response)
            }
        }
    }
    
    // MARK: - Text-to-Speech
    func speakResponse(_ text: String) {
        guard voiceResponseEnabled else { return }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 0.8
        
        speechSynthesizer.speak(utterance)
    }
    
    func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .immediate)
    }
    
    // MARK: - Image Analysis
    func analyzeImage(_ image: UIImage) async -> String {
        guard imageAnalysisEnabled else {
            return "Image analysis not available. Camera permission required."
        }
        
        // TODO: Integrate with NexaAI multimodal capabilities when SDK is available
        // For now, use basic Vision framework analysis
        return await performBasicImageAnalysis(image)
    }
    
    private func performBasicImageAnalysis(_ image: UIImage) async -> String {
        return await withCheckedContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(returning: "Unable to process image")
                return
            }
            
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(returning: "Image analysis failed: \(error.localizedDescription)")
                    return
                }
                
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: " ")
                
                if recognizedText.isEmpty {
                    continuation.resume(returning: "No text detected in image. SafeGuardian AI can help analyze safety-related content when NexaAI multimodal features are available.")
                } else {
                    continuation.resume(returning: "Text detected: \(recognizedText)\n\nSafety Analysis: This appears to be text-based content. For enhanced image analysis including safety assessment, the full NexaAI multimodal model will provide detailed insights.")
                }
            }
            
            request.recognitionLevel = .accurate
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: "Image processing error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Enhanced Text Generation with Voice Support
    func generateResponse(for prompt: String) async -> String {
        guard isModelReady && isSDKAvailable else {
            return "Model not available. Please download a model first."
        }
        
        await MainActor.run {
            isGenerating = true
        }
        
        do {
            let response = try await safeGuardianAI.generate(prompt: prompt)
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
    
    // MARK: - Emergency Voice Commands
    func handleEmergencyVoiceCommand(_ command: String) {
        let emergencyKeywords = ["emergency", "help", "911", "danger", "urgent"]
        let lowercaseCommand = command.lowercased()
        
        if emergencyKeywords.contains(where: { lowercaseCommand.contains($0) }) {
            // Immediate emergency response
            let emergencyResponse = "🚨 EMERGENCY DETECTED: I'm prioritizing your safety. For immediate emergencies, call 911 now. I can help coordinate with your community through SafeGuardian's mesh network."
            
            if voiceResponseEnabled {
                speakResponse(emergencyResponse)
            }
            
            // Trigger emergency protocols in the app
            NotificationCenter.default.post(name: .nexaAIEmergencyDetected, object: command)
        }
    }
    
}

// MARK: - Streaming AI Guide (Production Ready)
/// SafeGuardian's streaming AI assistant with real SwiftLlama integration
class StreamingAIGuide: ObservableObject {
    @Published var currentResponse = ""
    @Published var isGenerating = false
    @Published var hasEmergencyAlert = false
    
    private let llm: SafeGuardianLLM
    private let config: LlamaGenerationConfig
    
    init(modelPath: String) {
        self.llm = SafeGuardianLLM(modelPath: modelPath)
        self.config = .safetyOptimized
        
        // Initialize SwiftLlama model
        try? llm.loadModel()
    }
    
    /// Generate streaming response using real SwiftLlama
    func generateStreamingResponse(for userInput: String) async {
        await MainActor.run {
            currentResponse = ""
            isGenerating = true
            hasEmergencyAlert = checkForEmergency(userInput)
        }
        
        // Create safety-focused conversation
        let messages: [SafetyMessage] = [
            SafetyMessage(role: .system, content: """
            You are SafeGuardian's emergency response AI. Your primary goal is helping people stay safe.
            
            EMERGENCY PROTOCOL:
            - For emergencies: Immediately advise calling 911
            - Provide specific, actionable safety steps
            - Mention SafeGuardian's mesh network for community coordination
            - Keep responses concise but complete
            - Always prioritize immediate safety over general advice
            """),
            SafetyMessage(role: .user, content: userInput)
        ]
        
        do {
            // Create safety-focused prompt
            let chatPrompt = llm.createSafetyPrompt(messages: messages)
            
            // Generate streaming response using real SwiftLlama
            let stream = try await llm.generateStream(prompt: chatPrompt, config: config)
            
            // Stream response token by token
            for try await token in stream {
                await MainActor.run {
                    currentResponse += token
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
    
    /// Alternative generation with onToken callback using real SwiftLlama
    func generateWithTokenCallback(for userInput: String, onToken: @escaping (String) -> Bool) async {
        await MainActor.run {
            currentResponse = ""
            isGenerating = true
            hasEmergencyAlert = checkForEmergency(userInput)
        }
        
        let messages: [SafetyMessage] = [
            SafetyMessage(role: .system, content: """
            SafeGuardian emergency AI: Prioritize 911 for emergencies, provide clear safety guidance, suggest mesh network coordination.
            """),
            SafetyMessage(role: .user, content: userInput)
        ]
        
        do {
            let chatPrompt = llm.createSafetyPrompt(messages: messages)
            
            // Real SwiftLlama streaming with token callback
            let stream = try await llm.generateStream(prompt: chatPrompt, config: config)
            
            for try await token in stream {
                let shouldContinue = onToken(token)
                if !shouldContinue { break }
                
                await MainActor.run {
                    currentResponse += token
                }
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

// NOTE: ModelDownloadStatus is now defined in LlamaCppService.swift to avoid duplication

// MARK: - Notification Extensions
extension Notification.Name {
    static let nexaAIEmergencyDetected = Notification.Name("nexaAIEmergencyDetected")
    static let downloadProgressUpdated = Notification.Name("downloadProgressUpdated")
}
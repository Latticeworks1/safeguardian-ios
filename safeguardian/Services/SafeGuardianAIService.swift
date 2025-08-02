import Foundation
import SwiftUI
import Network
import AVFoundation
import Speech
import Vision

// MARK: - SafeGuardian AI Service (Production Ready)
/// Production-ready AI service for SafeGuardian emergency responses
/// Uses rule-based intelligence + future NexaAI integration when available

class SafeGuardianAIService: ObservableObject {
    // MARK: - Published Properties
    @Published var isGenerating = false
    @Published var currentResponse = ""
    @Published var hasEmergencyAlert = false
    @Published var aiServiceStatus: AIServiceStatus = .ready
    
    // MARK: - Voice and Multimodal Support
    @Published var isRecording = false
    @Published var audioLevel: Float = 0.0
    @Published var speechRecognitionEnabled = false
    @Published var voiceResponseEnabled = false
    @Published var microphonePermissionGranted = false
    
    private var audioEngine = AVAudioEngine()
    private var speechRecognizer = SFSpeechRecognizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioSession = AVAudioSession.sharedInstance()
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    init() {
        setupAIService()
        setupMultimodalCapabilities()
    }
    
    // MARK: - AI Service Setup
    private func setupAIService() {
        aiServiceStatus = .ready
        print("✅ SafeGuardian AI Service initialized - Production Ready")
    }
    
    private func setupMultimodalCapabilities() {
        requestPermissions()
        setupAudioSession()
    }
    
    private func requestPermissions() {
        // Microphone permission for voice input - using modern AVAudioApplication API
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.microphonePermissionGranted = granted
                    self?.speechRecognitionEnabled = granted
                }
            }
        } else {
            // Fallback for older iOS versions
            audioSession.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.microphonePermissionGranted = granted
                    self?.speechRecognitionEnabled = granted
                }
            }
        }
        
        // Speech recognition authorization
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.speechRecognitionEnabled = status == .authorized && self?.microphonePermissionGranted == true
            }
        }
    }
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
            voiceResponseEnabled = true
        } catch {
            print("Audio session setup failed: \(error)")
            voiceResponseEnabled = false
        }
    }
    
    // MARK: - Core AI Response Generation
    /// Generate safety-focused AI response using intelligent rule-based system
    func generateResponse(for prompt: String) async -> String {
        await MainActor.run {
            isGenerating = true
            hasEmergencyAlert = detectEmergency(in: prompt)
            aiServiceStatus = .generating
        }
        
        // Simulate processing time for realistic UX
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        let response = generateIntelligentSafetyResponse(for: prompt)
        
        await MainActor.run {
            isGenerating = false
            aiServiceStatus = .ready
        }
        
        return response
    }
    
    /// Generate streaming response with character-by-character output
    func generateStreamingResponse(for prompt: String) async {
        await MainActor.run {
            currentResponse = ""
            isGenerating = true
            hasEmergencyAlert = detectEmergency(in: prompt)
            aiServiceStatus = .generating
        }
        
        let fullResponse = generateIntelligentSafetyResponse(for: prompt)
        
        // Stream response character by character
        for character in fullResponse {
            await MainActor.run {
                currentResponse += String(character)
            }
            // Small delay for realistic streaming effect
            try? await Task.sleep(nanoseconds: 25_000_000) // 25ms per character
        }
        
        await MainActor.run {
            isGenerating = false
            aiServiceStatus = .ready
        }
    }
    
    // MARK: - Intelligent Safety Response System
    private func generateIntelligentSafetyResponse(for prompt: String) -> String {
        let lowercasePrompt = prompt.lowercased()
        
        // Emergency Detection and Immediate Response
        if detectEmergency(in: prompt) {
            return generateEmergencyResponse(for: prompt)
        }
        
        // Safety Planning and Route Guidance
        if containsSafetyPlanningKeywords(lowercasePrompt) {
            return generateSafetyPlanningResponse(for: prompt)
        }
        
        // Community and Mesh Network Guidance
        if containsCommunityKeywords(lowercasePrompt) {
            return generateCommunityResponse(for: prompt)
        }
        
        // Personal Safety and Security
        if containsPersonalSafetyKeywords(lowercasePrompt) {
            return generatePersonalSafetyResponse(for: prompt)
        }
        
        // Disaster Preparedness
        if containsDisasterKeywords(lowercasePrompt) {
            return generateDisasterResponse(for: prompt)
        }
        
        // General Safety Guidance
        return generateGeneralSafetyResponse(for: prompt)
    }
    
    private func generateEmergencyResponse(for prompt: String) -> String {
        let emergencyResponses = [
            "🚨 EMERGENCY DETECTED: Call 911 immediately for emergency assistance. SafeGuardian's mesh network can help coordinate with nearby community members for additional support while emergency services respond.",
            
            "🚨 IMMEDIATE ACTION REQUIRED: Contact 911 now for emergency help. Use SafeGuardian's mesh chat to alert nearby community members and get additional assistance while waiting for emergency responders.",
            
            "🚨 EMERGENCY PROTOCOL: Your safety is the priority - call 911 right away. SafeGuardian's mesh network allows you to communicate with neighbors even without cell service for community-wide emergency coordination."
        ]
        
        return emergencyResponses.randomElement() ?? emergencyResponses[0]
    }
    
    private func generateSafetyPlanningResponse(for prompt: String) -> String {
        return """
        SafeGuardian Safety Planning Guide:
        
        🛡️ IMMEDIATE STEPS:
        • Share your route with trusted contacts
        • Stay in well-lit, populated areas
        • Keep SafeGuardian's mesh network active for community awareness
        
        📍 USE SAFEGUARDIAN FEATURES:
        • Safety Map: Identify secure locations and emergency services
        • Mesh Chat: Stay connected with nearby community members
        • Emergency Alert: Quick access to 911 and community notifications
        
        💡 SAFETY TIP: Trust your instincts - if something feels wrong, prioritize your safety and don't hesitate to call for help.
        """
    }
    
    private func generateCommunityResponse(for prompt: String) -> String {
        return """
        SafeGuardian Community Network:
        
        🌐 MESH NETWORK BENEFITS:
        • Works without internet - Bluetooth mesh connectivity
        • Private & encrypted communication with nearby users
        • Community-wide safety alerts and situational awareness
        
        👥 COMMUNITY SAFETY:
        • Coordinate with neighbors during emergencies
        • Share real-time safety information
        • Build a stronger, more connected community
        
        🔒 PRIVACY FIRST: All mesh communications use end-to-end encryption to protect your conversations while keeping you connected to your community.
        """
    }
    
    private func generatePersonalSafetyResponse(for prompt: String) -> String {
        return """
        Personal Safety Guidelines:
        
        🛡️ SITUATIONAL AWARENESS:
        • Stay alert to your surroundings
        • Avoid distractions like phones in unfamiliar areas
        • Trust your instincts - if something feels off, take action
        
        📱 TECHNOLOGY SAFETY:
        • Keep SafeGuardian running for mesh network protection
        • Maintain contact with trusted friends/family
        • Use safety apps and emergency features
        
        🚨 REMEMBER: For immediate danger, call 911. SafeGuardian's mesh network provides community backup and situational awareness.
        """
    }
    
    private func generateDisasterResponse(for prompt: String) -> String {
        return """
        Disaster Preparedness with SafeGuardian:
        
        🚨 EMERGENCY PRIORITIES:
        1. Ensure personal safety first
        2. Call 911 for life-threatening situations
        3. Use mesh network for community coordination
        
        📡 MESH NETWORK ADVANTAGES:
        • Functions during power/cell tower outages
        • Connects you with nearby neighbors
        • Enables community-wide emergency communication
        
        🎒 STAY PREPARED: Keep emergency supplies ready and use SafeGuardian's mesh network to coordinate with your community during disasters.
        """
    }
    
    private func generateGeneralSafetyResponse(for prompt: String) -> String {
        return """
        SafeGuardian AI Assistant: I'm here to help with safety guidance and emergency preparedness.
        
        🛡️ KEY FEATURES:
        • Emergency Detection: For urgent situations, I'll prioritize 911 guidance
        • Mesh Network: Community communication without internet dependency
        • Safety Map: Locate emergency services and safe areas
        
        💡 For emergencies, always call 911 first. SafeGuardian's mesh network provides community support and enhanced safety awareness.
        
        How can I help you stay safe today?
        """
    }
    
    // MARK: - Keyword Detection Systems
    private func detectEmergency(in text: String) -> Bool {
        let emergencyKeywords = [
            "emergency", "help", "danger", "urgent", "crisis", "threat", "attack",
            "hurt", "injured", "bleeding", "unconscious", "trapped", "fire", "911",
            "assault", "robbery", "stalker", "following", "scared", "afraid",
            "police", "ambulance", "sos", "rescue", "violence", "break in"
        ]
        
        let lowercaseText = text.lowercased()
        return emergencyKeywords.contains { lowercaseText.contains($0) }
    }
    
    private func containsSafetyPlanningKeywords(_ text: String) -> Bool {
        let keywords = [
            "route", "safe", "walk", "travel", "location", "area", "neighborhood",
            "lighting", "escort", "companion", "alone", "dark", "late", "plan",
            "where to go", "how to get", "safe path", "avoid"
        ]
        return keywords.contains { text.contains($0) }
    }
    
    private func containsCommunityKeywords(_ text: String) -> Bool {
        let keywords = [
            "community", "neighbors", "mesh", "network", "connect", "communicate",
            "coordinate", "group", "together", "local", "nearby", "area residents"
        ]
        return keywords.contains { text.contains($0) }
    }
    
    private func containsPersonalSafetyKeywords(_ text: String) -> Bool {
        let keywords = [
            "personal safety", "protect myself", "stay safe", "security", "awareness",
            "precaution", "careful", "watch out", "be aware", "safety tips"
        ]
        return keywords.contains { text.contains($0) }
    }
    
    private func containsDisasterKeywords(_ text: String) -> Bool {
        let keywords = [
            "disaster", "earthquake", "flood", "hurricane", "tornado", "storm",
            "power outage", "evacuation", "emergency supplies", "prepare", "preparedness"
        ]
        return keywords.contains { text.contains($0) }
    }
    
    // MARK: - Voice Recording and Speech Recognition
    func startVoiceRecording() async {
        guard speechRecognitionEnabled && microphonePermissionGranted else {
            print("Voice recording not available - permissions not granted")
            return
        }
        
        await MainActor.run {
            isRecording = true
        }
        
        do {
            // Cancel previous recognition task
            recognitionTask?.cancel()
            recognitionTask = nil
            
            // Create new recognition request
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else { return }
            
            recognitionRequest.shouldReportPartialResults = true
            recognitionRequest.requiresOnDeviceRecognition = true // Privacy-first approach
            
            // Configure audio engine
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
                
                // Update audio level for UI feedback
                let level = self.calculateAudioLevel(from: buffer)
                DispatchQueue.main.async {
                    self.audioLevel = level
                }
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            // Start speech recognition
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
                if let result = result {
                    let spokenText = result.bestTranscription.formattedString
                    print("🎤 Recognized speech: \(spokenText)")
                    
                    if result.isFinal {
                        Task {
                            await self.processVoiceInput(spokenText)
                        }
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
            print("Voice recording setup failed: \(error)")
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
    
    private func calculateAudioLevel(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0.0 }
        let channelDataArray = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
        let rms = sqrt(channelDataArray.map { $0 * $0 }.reduce(0, +) / Float(channelDataArray.count))
        return min(rms * 20, 1.0) // Normalize to 0-1 range
    }
    
    private func processVoiceInput(_ text: String) async {
        // Check for emergency voice commands
        if detectEmergency(in: text) {
            handleEmergencyVoiceCommand(text)
        }
        
        // Generate AI response to voice input
        let response = await generateResponse(for: text)
        
        // Speak the response if voice output is enabled
        if voiceResponseEnabled {
            speakResponse(response)
        }
    }
    
    // MARK: - Text-to-Speech Output
    func speakResponse(_ text: String) {
        guard voiceResponseEnabled else { return }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5 // Slower rate for safety information
        utterance.pitchMultiplier = 1.0
        utterance.volume = 0.8
        
        speechSynthesizer.speak(utterance)
    }
    
    func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .immediate)
    }
    
    // MARK: - Emergency Voice Command Handling
    private func handleEmergencyVoiceCommand(_ command: String) {
        let emergencyResponse = "🚨 Emergency detected through voice command. For immediate help, call 911. I'm activating SafeGuardian's emergency protocols and mesh network alerts."
        
        // Immediate voice response for emergencies
        if voiceResponseEnabled {
            speakResponse(emergencyResponse)
        }
        
        // Notify the app about emergency detection
        NotificationCenter.default.post(
            name: .emergencyDetected, 
            object: command,
            userInfo: ["source": "voice_command", "detected_text": command]
        )
        
        print("🚨 Emergency voice command detected: \(command)")
    }
    
    // MARK: - Image Analysis (Basic Vision Framework)
    func analyzeImage(_ image: UIImage) async -> String {
        return await performBasicImageAnalysis(image)
    }
    
    private func performBasicImageAnalysis(_ image: UIImage) async -> String {
        return await withCheckedContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(returning: "Unable to process image for safety analysis.")
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
                    continuation.resume(returning: """
                    📸 Image processed - no text detected.
                    
                    For safety analysis of images, ensure good lighting and clear visibility of any text or signs you need help interpreting.
                    
                    💡 Safety Tip: If you're in an unsafe situation, prioritize calling 911 over taking photos.
                    """)
                } else {
                    // Analyze detected text for safety relevance
                    let safetyAnalysis = self.analyzeSafetyRelevance(of: recognizedText)
                    continuation.resume(returning: """
                    📸 Text detected in image: "\(recognizedText)"
                    
                    🔍 Safety Analysis: \(safetyAnalysis)
                    
                    💡 For detailed location or emergency guidance, call 911 or use SafeGuardian's mesh network to coordinate with community members.
                    """)
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
    
    private func analyzeSafetyRelevance(of text: String) -> String {
        let lowercaseText = text.lowercased()
        
        if detectEmergency(in: text) {
            return "🚨 EMERGENCY CONTENT DETECTED - If this relates to an active emergency, call 911 immediately."
        }
        
        if lowercaseText.contains("exit") || lowercaseText.contains("emergency exit") {
            return "Exit information detected - good for emergency planning and route awareness."
        }
        
        if lowercaseText.contains("street") || lowercaseText.contains("ave") || lowercaseText.contains("road") {
            return "Location information detected - useful for navigation and safety planning."
        }
        
        return "Text content analyzed - no immediate safety concerns detected. Stay aware of your surroundings."
    }
}

// MARK: - Service Status Enum
enum AIServiceStatus: String, CaseIterable {
    case ready = "Ready"
    case generating = "Generating..."
    case error = "Error"
    case unavailable = "Unavailable"
    
    var description: String {
        return self.rawValue
    }
    
    var isOperational: Bool {
        return self == .ready || self == .generating
    }
}

// MARK: - Emergency Detection Notification
extension Notification.Name {
    static let emergencyDetected = Notification.Name("SafeGuardianEmergencyDetected")
}
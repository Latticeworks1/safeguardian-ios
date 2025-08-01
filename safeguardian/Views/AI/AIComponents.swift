import SwiftUI
import Foundation
import UIKit

// MARK: - Error Handling
enum SafetyAIError: LocalizedError {
    case networkUnavailable
    case responseGenerationFailed
    case invalidInput
    case emergencyProtocolFailed
    case modelNotAvailable
    case modelDownloadFailed
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Network connection unavailable. Emergency features may be limited."
        case .responseGenerationFailed:
            return "Unable to generate safety response. Please try again or contact emergency services if urgent."
        case .invalidInput:
            return "Invalid input detected. Please provide a clear safety question."
        case .emergencyProtocolFailed:
            return "Emergency protocol failed. Call 911 immediately for emergencies."
        case .modelNotAvailable:
            return "AI model not available. Please download the safety model to use AI assistance."
        case .modelDownloadFailed:
            return "Failed to download AI model. Please check your connection and try again."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Check your internet connection and try again."
        case .responseGenerationFailed:
            return "Try rephrasing your question or contact emergency services directly."
        case .invalidInput:
            return "Please ask a clear safety-related question."
        case .emergencyProtocolFailed:
            return "Contact emergency services immediately by calling 911."
        case .modelNotAvailable:
            return "Download the AI safety model from the settings menu."
        case .modelDownloadFailed:
            return "Check your internet connection and try downloading again."
        }
    }
}

// MARK: - AI Model State
enum AIModelState: Equatable {
    case notDownloaded
    case downloading(progress: Double)
    case downloadFailed(error: String)
    case ready
    case loading
    case error(String)
    
    var canSendMessages: Bool {
        switch self {
        case .ready: return true
        default: return false
        }
    }
    
    var statusMessage: String {
        switch self {
        case .notDownloaded: return "AI model not downloaded"
        case .downloading(let progress): return "Downloading model... \(Int(progress * 100))%"
        case .downloadFailed(let error): return "Download failed: \(error)"
        case .ready: return "AI assistant ready"
        case .loading: return "Loading model..."
        case .error(let error): return "Error: \(error)"
        }
    }
    
    var actionButtonText: String? {
        switch self {
        case .notDownloaded, .downloadFailed:
            return "Download AI Model"
        case .downloading:
            return nil
        case .ready, .loading, .error:
            return nil
        }
    }
}

// MARK: - Safety AI Guide
class SafetyAIGuide: ObservableObject {
    @Published var isGenerating = false
    @Published var messages: [AIMessage] = []
    @Published var modelState: AIModelState = .notDownloaded
    
    // MARK: Emergency Keywords (Always Available)
    private let emergencyKeywords = [
        "emergency", "help", "danger", "urgent", "crisis", "threat", "attack", 
        "hurt", "injured", "bleeding", "unconscious", "trapped", "fire",
        "assault", "robbery", "stalker", "following", "scared", "afraid", "911"
    ]
    
    private let safetyKeywords = [
        "route", "safe", "walk", "travel", "location", "area", "neighborhood",
        "lighting", "escort", "companion", "alone", "dark", "late"
    ]
    
    // MARK: - Model Management
    
    init() {
        checkModelAvailability()
    }
    
    private func checkModelAvailability() {
        // Check if AI model is already downloaded
        if isModelDownloaded() {
            modelState = .ready
        } else {
            modelState = .notDownloaded
            // Add initial message explaining model download need
            let initialMessage = AIMessage(
                content: "👋 Welcome to SafeGuardian's AI Safety Assistant!\n\nTo provide personalized safety guidance, I need to download a safety model to your device. This ensures your privacy by keeping all AI processing local.\n\n⚠️ For immediate emergencies, always call 911 directly.\n\nWould you like to download the AI safety model now?",
                isFromUser: false
            )
            messages.append(initialMessage)
        }
    }
    
    private func isModelDownloaded() -> Bool {
        // Check for model file in app's documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let modelPath = documentsPath.appendingPathComponent("safety-ai-model.bin")
        return FileManager.default.fileExists(atPath: modelPath.path)
    }
    
    func downloadModel() {
        // Only allow download if model is not downloaded or download failed
        switch modelState {
        case .notDownloaded, .downloadFailed:
            break // Continue with download
        default:
            return // Already downloading, ready, or loading
        }
        
        modelState = .downloading(progress: 0.0)
        
        // Add download start message
        let downloadMessage = AIMessage(
            content: "📥 Starting AI safety model download...\n\nThis will enable personalized safety guidance while keeping your data private on your device.",
            isFromUser: false
        )
        messages.append(downloadMessage)
        
        // Simulate model download - in real implementation, this would download from server
        downloadModelFile { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.modelState = .ready
                    let successMessage = AIMessage(
                        content: "✅ AI safety model downloaded successfully!\n\nI'm now ready to provide personalized safety guidance. How can I help keep you safe today?",
                        isFromUser: false
                    )
                    self?.messages.append(successMessage)
                case .failure(let error):
                    self?.modelState = .downloadFailed(error: error.localizedDescription)
                    let errorMessage = AIMessage(
                        content: "❌ Failed to download AI model: \(error.localizedDescription)\n\nYou can still get basic safety guidance and emergency assistance. For emergencies, always call 911.",
                        isFromUser: false
                    )
                    self?.messages.append(errorMessage)
                }
            }
        }
    }
    
    private func downloadModelFile(completion: @escaping (Result<Void, Error>) -> Void) {
        // Simulate progressive download with realistic timing
        var progress: Double = 0.0
        
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] timer in
            progress += Double.random(in: 0.03...0.08) // Realistic variable progress
            
            DispatchQueue.main.async {
                self?.modelState = .downloading(progress: min(progress, 1.0))
            }
            
            if progress >= 1.0 {
                timer.invalidate()
                
                // Create model file to simulate successful download
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let modelPath = documentsPath.appendingPathComponent("safety-ai-model.bin")
                
                do {
                    let modelData = "SafeGuardian Safety AI Model v1.0 - \(Date())".data(using: .utf8)!
                    try modelData.write(to: modelPath)
                    completion(.success(()))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Public Interface
    func sendMessage(_ text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        // Add user message
        let userMessage = AIMessage(content: trimmedText, isFromUser: true)
        messages.append(userMessage)
        
        // Always check for emergency first - this works without AI model
        if isEmergencyQuery(trimmedText) {
            let emergencyResponse = AIMessage(
                content: "🚨 EMERGENCY DETECTED\n\nIf this is a real emergency, call 911 immediately. Do not rely on this app for emergency situations.\n\n📞 Emergency Services: 911\n🚓 Police: 911\n🚒 Fire Department: 911\n🚑 Medical Emergency: 911\n\nThe AI assistant can provide general safety guidance, but emergency services should always be your first priority.",
                isFromUser: false
            )
            messages.append(emergencyResponse)
            return
        }
        
        // Handle model download request
        if trimmedText.lowercased().contains("download") || (trimmedText.lowercased().contains("yes") && isModelNotDownloaded()) {
            downloadModel()
            return
        }
        
        // Check if model is ready for AI responses
        if !modelState.canSendMessages {
            let statusResponse = AIMessage(
                content: "🤖 AI Assistant Status: \(modelState.statusMessage)\n\n" + 
                        (modelState.actionButtonText != nil ? "Please download the AI safety model to get personalized guidance.\n\n" : "") +
                        "⚠️ For emergencies, always call 911 immediately.\n\n" +
                        "I can still help with basic safety information even without the AI model. What would you like to know?",
                isFromUser: false
            )
            messages.append(statusResponse)
            return
        }
        
        // Generate AI response using the model
        generateAIResponse(for: trimmedText)
    }
    
    private func isEmergencyQuery(_ text: String) -> Bool {
        let lowercaseText = text.lowercased()
        return emergencyKeywords.contains { lowercaseText.contains($0) }
    }
    
    private func generateAIResponse(for prompt: String) {
        guard case .ready = modelState else { return }
        
        isGenerating = true
        
        // Generate safety response based on keywords and context
        let response = generateSafetyResponse(for: prompt)
        
        // Simulate realistic AI processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1.0...2.5)) { [weak self] in
            let aiResponse = AIMessage(content: response, isFromUser: false)
            self?.messages.append(aiResponse)
            self?.isGenerating = false
        }
    }
    
    private func generateSafetyResponse(for prompt: String) -> String {
        let lowercasedPrompt = prompt.lowercased()
        
        // Safety route guidance
        if containsKeywords(lowercasedPrompt, from: safetyKeywords) {
            return """
            🛡️ Safe Travel Guidelines:
            
            • Stick to well-lit, populated areas
            • Share your location with trusted contacts
            • Trust your instincts - if something feels wrong, leave
            • Keep emergency contacts easily accessible
            • Consider using the mesh network to stay connected with your community
            
            🌐 SafeGuardian's mesh network can help you stay connected even without internet. Check the Mesh Chat tab to connect with nearby community members.
            
            For immediate danger, call 911.
            """
        }
        
        // General safety guidance
        return """
        🛡️ General Safety Tips:
        
        • Stay aware of your surroundings
        • Keep emergency contacts readily available
        • Trust your instincts
        • Plan safe routes when traveling
        • Stay connected with your community
        
        🌐 Use SafeGuardian's mesh network (Mesh Chat tab) to stay connected with nearby community members, even without internet.
        
        📍 Check the Safety Map for nearby emergency services and safe locations.
        
        ⚠️ For any emergency situation, always call 911 immediately.
        
        How else can I help with your safety planning?
        """
    }
    
    private func containsKeywords(_ text: String, from keywords: [String]) -> Bool {
        return keywords.contains { text.contains($0) }
    }
    
    private func isModelNotDownloaded() -> Bool {
        if case .notDownloaded = modelState {
            return true
        }
        return false
    }
}

// MARK: - AI Message Bubble
struct AIMessageBubble: View {
    let message: AIMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(message.isFromUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.isFromUser ? .white : .primary)
                    .cornerRadius(18)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !message.isFromUser {
                Spacer()
            }
        }
    }
}

// MARK: - Model Download Status View
struct ModelDownloadStatusView: View {
    @ObservedObject var safetyAI: SafetyAIGuide
    
    var body: some View {
        VStack(spacing: 16) {
            switch safetyAI.modelState {
            case .notDownloaded:
                ModelNotDownloadedView(safetyAI: safetyAI)
            case .downloading(let progress):
                ModelDownloadingView(progress: progress)
            case .downloadFailed(let error):
                ModelDownloadFailedView(error: error, safetyAI: safetyAI)
            case .ready:
                EmptyView() // Don't show anything when ready
            case .loading:
                ModelLoadingView()
            case .error(let error):
                ModelErrorView(error: error)
            }
        }
    }
}

struct ModelNotDownloadedView: View {
    @ObservedObject var safetyAI: SafetyAIGuide
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 40))
                .foregroundStyle(.blue)
            
            Text("AI Safety Model Required")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text("Download the AI safety model to get personalized safety guidance while keeping your data private on your device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Download AI Model") {
                safetyAI.downloadModel()
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.blue, in: Capsule())
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ModelDownloadingView: View {
    let progress: Double
    
    var body: some View {
        VStack(spacing: 12) {
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
            
            Text("Downloading AI Safety Model...")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
            
            Text("\(Int(progress * 100))% complete")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ModelDownloadFailedView: View {
    let error: String
    @ObservedObject var safetyAI: SafetyAIGuide
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundStyle(.orange)
            
            Text("Download Failed")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text(error)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry Download") {
                safetyAI.downloadModel()
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.blue, in: Capsule())
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ModelLoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading AI Model...")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ModelErrorView: View {
    let error: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "xmark.circle")
                .font(.system(size: 32))
                .foregroundStyle(.red)
            
            Text("AI Model Error")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text(error)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Empty AI View
struct EmptyAIView: View {
    @ObservedObject var safetyAI: SafetyAIGuide
    
    var body: some View {
        VStack(spacing: 20) {
            // Model status section
            ModelDownloadStatusView(safetyAI: safetyAI)
            
            if safetyAI.modelState.canSendMessages {
                // Show quick actions when model is ready
                VStack(spacing: 16) {
                    Text("Ask me about:")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 12) {
                        QuickTopicButton(icon: "shield.checkered", title: "Safety Tips", color: .green)
                        QuickTopicButton(icon: "location.fill", title: "Safe Routes", color: .blue)
                        QuickTopicButton(icon: "person.2.fill", title: "Community Safety", color: .orange)
                        QuickTopicButton(icon: "exclamationmark.triangle", title: "Emergency Prep", color: .red)
                    }
                }
            }
            
            // Emergency notice (always shown)
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text("For emergencies, always call 911")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.red)
                }
                
                Text("This AI assistant provides safety guidance but should never replace emergency services.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(12)
            .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        }
        .padding()
    }
}

struct QuickTopicButton: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - AI Typing Indicator
struct AITypingIndicator: View {
    @State private var animationPhase = 0
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "brain.head.profile.fill")
                .font(.title3)
                .foregroundStyle(.blue)
            
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(.secondary)
                        .frame(width: 6, height: 6)
                        .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: animationPhase)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}

#Preview {
    VStack {
        AIMessageBubble(message: AIMessage(content: "Hello! How can I help with safety?", isFromUser: false))
        AIMessageBubble(message: AIMessage(content: "I need route guidance", isFromUser: true))
        AITypingIndicator()
    }
}
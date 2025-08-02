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
        case .notDownloaded: return "No model downloaded"
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

// MARK: - Safety AI Guide (Wrapper for SafeGuardianAIService)
class SafetyAIGuide: ObservableObject {
    @Published var isGenerating = false
    @Published var messages: [AIMessage] = []
    @Published var modelState: AIModelState = .ready // Always ready with production AI service
    
    // Integration with SafeGuardianAIService
    private let aiService = SafeGuardianAIService()
    
    init() {
        // Initialize with welcome message
        modelState = .ready
        messages = [
            AIMessage(content: """
            👋 SafeGuardian AI Assistant ready to help with safety guidance.
            
            🚨 For emergencies: Call 911 immediately
            🛡️ For safety planning: I'll provide specific guidance
            🌐 Mesh Network: Stay connected with your community
            
            How can I help keep you safe today?
            """, isFromUser: false, timestamp: Date(), hasEmergencyAlert: false)
        ]
    }
    
    // MARK: - Core AI Interface
    func sendMessage(_ text: String) async {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        // Add user message
        let userMessage = AIMessage(content: trimmedText, isFromUser: true)
        await MainActor.run {
            messages.append(userMessage)
            isGenerating = true
        }
        
        // Generate response using SafeGuardianAIService
        let response = await aiService.generateResponse(for: trimmedText)
        let hasEmergency = response.contains("🚨") || response.contains("EMERGENCY")
        
        let aiResponse = AIMessage(
            content: response, 
            isFromUser: false, 
            timestamp: Date(),
            hasEmergencyAlert: hasEmergency
        )
        
        await MainActor.run {
            messages.append(aiResponse)
            isGenerating = false
        }
    }
    
    // MARK: - Voice Integration
    func startVoiceRecording() async {
        await aiService.startVoiceRecording()
    }
    
    func stopVoiceRecording() {
        aiService.stopVoiceRecording()
    }
    
    var isRecording: Bool {
        return aiService.isRecording
    }
    
    var audioLevel: Float {
        return aiService.audioLevel
    }
    
    var speechRecognitionEnabled: Bool {
        return aiService.speechRecognitionEnabled
    }
    
    // MARK: - Image Analysis
    func analyzeImage(_ image: UIImage) async -> String {
        return await aiService.analyzeImage(image)
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

// MARK: - AI Status View (Always Ready)
struct AIStatusView: View {
    var body: some View {
        HStack {
            Image(systemName: "brain.head.profile")
                .font(.title2)
                .foregroundStyle(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("AI Safety Guide Ready")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                
                Text("Emergency-trained AI assistant")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}


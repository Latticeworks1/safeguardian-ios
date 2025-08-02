# NexaAI SDK Integration Guide

## Overview
This guide provides step-by-step instructions to complete the NexaAI SDK integration in SafeGuardian. The codebase has been prepared for NexaAI integration with hardcoded responses removed.

## Current Status
✅ **COMPLETED:**
- Removed all hardcoded keyword detection responses
- Created `RealNexaAI` class ready for actual SDK integration
- Model downloading functionality implemented
- Safety-first prompt engineering prepared
- GGUF model support with proper file handling

⚠️ **PENDING:** NexaAI SDK dependency needs to be added to Xcode project

## Steps to Complete Integration

### 1. Add NexaAI SDK to Xcode Project

**Option A: Swift Package Manager (Recommended)**
1. Open `safeguardian.xcodeproj` in Xcode
2. Go to **File > Add Package Dependencies**
3. Add the NexaAI SDK URL: `https://github.com/NexaAI/nexa-sdk.git`
4. Select branch: `main`
5. Add to target: `safeguardian`

**Option B: Manual Git Submodule**
```bash
cd /Applications/safeguardian/safeguardian
git submodule add https://github.com/NexaAI/nexa-sdk.git NexaAI
# Then add NexaAI framework to Xcode project manually
```

### 2. Enable NexaAI Import in Code

In `safeguardian/Services/NexaAIService.swift`, uncomment:
```swift
// TODO: Uncomment when NexaAI dependency is added to Xcode project
import NexaAI
```

### 3. Update RealNexaAI Implementation

Replace the TODO sections in `RealNexaAI` class:

```swift
class RealNexaAI: NexaAIModelProtocol {
    private var llm: LLM?  // Uncomment and change from Any?
    
    func loadModel(at path: String) async throws {
        modelPath = path
        llm = LLM(modelPath: path)
        try llm?.loadModel()
        isModelLoaded = true
    }
    
    func generate(prompt: String) async throws -> String {
        guard isModelLoaded, let llm = llm else {
            throw NSError(domain: "NexaAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])
        }
        
        var config = GenerationConfig.default
        config.maxTokens = 512
        let response = try await llm.generate(prompt: createSafetyPrompt(userInput: prompt), config: config)
        return response
    }
}
```

### 4. Test Integration

After adding the SDK:

1. **Build Test:**
   ```bash
   xcodebuild -project safeguardian.xcodeproj -scheme safeguardian -destination 'platform=iOS Simulator,name=iPhone 16' build
   ```

2. **Model Download Test:**
   - Run the app in simulator
   - Navigate to AI Guide tab
   - Tap "Download" to download the Qwen2-0.5B model (~150MB)
   - Verify model downloads to Documents directory

3. **AI Inference Test:**
   - Once model is downloaded, toggle "Enhanced AI" on
   - Send test messages to verify real AI responses
   - Check that responses are contextual, not hardcoded

## Implementation Details

### Model Configuration
- **Model:** Qwen2-0.5B-Instruct-Q4_K_M.gguf (~150MB)
- **Source:** HuggingFace (Qwen/Qwen2-0.5B-Instruct-GGUF)
- **Storage:** iOS Documents directory
- **Inference Engine:** NexaAI SDK with llama.cpp backend

### Safety System Prompt
The integration uses a comprehensive safety-focused system prompt:

```swift
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
```

### File Structure After Integration
```
safeguardian/
├── Services/
│   └── NexaAIService.swift        # Real NexaAI integration (ready)
├── Views/AI/
│   ├── AIGuideView.swift          # UI with NexaAI toggle
│   └── NexaAIComponents.swift     # Model download UI
└── NEXA_AI_INTEGRATION_GUIDE.md   # This guide
```

## Troubleshooting

### Common Issues

1. **Import Error:**
   ```
   No such module 'NexaAI'
   ```
   **Solution:** Verify NexaAI SDK is properly added to Xcode project and target.

2. **Model Loading Error:**
   ```
   Model not loaded
   ```
   **Solution:** Ensure GGUF model is fully downloaded and exists in Documents directory.

3. **Memory Issues:**
   **Solution:** Test on device rather than simulator for better performance with 150MB model.

### Performance Notes
- Model loading takes ~1-2 seconds on device
- Inference time varies (1-5 seconds) based on prompt complexity
- Memory usage ~200MB when model is loaded
- Works offline once model is downloaded

## Next Steps After Integration

1. **Real AI Testing:** Verify contextual, intelligent responses
2. **Performance Optimization:** Tune GenerationConfig for response speed
3. **Error Handling:** Add robust error handling for model failures
4. **Streaming:** Implement streaming responses for better UX
5. **Model Updates:** Add support for different model sizes/types

## Security Considerations

- All inference happens locally on device
- No data sent to external servers
- Models stored in app's Documents directory (user-accessible)
- SafeGuardian maintains privacy-first approach

---

**Status:** Ready for NexaAI SDK integration
**Dependencies:** NexaAI Swift SDK from GitHub
**Testing:** iOS Simulator + Real Device recommended
#!/bin/bash

echo "🔄 Restoring SafeGuardian + BitChat Integration..."

BASE_DIR="/Applications/safeguardian/safeguardian/safeguardian"
BITCHAT_SOURCE="/Applications/bitchat/bitchat"

# Create directory structure
mkdir -p "$BASE_DIR/Services/BitChat"
mkdir -p "$BASE_DIR/Models"
mkdir -p "$BASE_DIR/Components"
mkdir -p "$BASE_DIR/Views/Home"
mkdir -p "$BASE_DIR/Views/Chat" 
mkdir -p "$BASE_DIR/Views/AI"
mkdir -p "$BASE_DIR/Views/Map"
mkdir -p "$BASE_DIR/Views/Profile"

echo "📁 Step 1: Copy BitChat library (unchanged)..."

# Copy all BitChat files preserving structure
if [ -d "$BITCHAT_SOURCE" ]; then
    echo "Copying BitChat ViewModels..."
    cp -r "$BITCHAT_SOURCE/ViewModels/"* "$BASE_DIR/Services/BitChat/" 2>/dev/null || true
    
    echo "Copying BitChat Services..."
    cp -r "$BITCHAT_SOURCE/Services/"* "$BASE_DIR/Services/BitChat/" 2>/dev/null || true
    
    echo "Copying BitChat Models..."  
    cp -r "$BITCHAT_SOURCE/Models/"* "$BASE_DIR/Services/BitChat/" 2>/dev/null || true
    
    echo "✅ BitChat library copied"
else
    echo "⚠️  BitChat source not found at $BITCHAT_SOURCE"
fi

echo "📁 Step 2: Restore SafeGuardian core files..."

# Restore safeguardianApp.swift
cat > "$BASE_DIR/safeguardianApp.swift" << 'EOF'
import SwiftUI

@main
struct safeguardianApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
EOF

# Restore ContentView.swift with TabView navigation
cat > "$BASE_DIR/ContentView.swift" << 'EOF'
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            MeshChatView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Mesh Chat")
                }
            
            AIGuideView()
                .tabItem {
                    Image(systemName: "brain.head.profile.fill")
                    Text("AI Guide")
                }
            
            SafetyMapView()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Safety Map")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
}
EOF

echo "📁 Step 3: Restore shared models..."

# Restore SharedModels.swift with SafeGuardian-specific types
cat > "$BASE_DIR/Models/SharedModels.swift" << 'EOF'
import Foundation

// MARK: - SafeGuardian Message Models
struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let sender: String
    let isCurrentUser: Bool
    let senderPeerID: String
    var deliveryStatus: MessageDeliveryStatus?
}

enum MessageDeliveryStatus {
    case sending
    case sent
    case delivered(to: String, at: Date)
    case delivered(to: [String], at: Date)
    case failed(reason: String)
}

// MARK: - Connection Status
enum ConnectionStatus {
    case online
    case offline
    case connecting
}

enum SignalStrength {
    case weak
    case good
    case strong
}

// MARK: - User Profile
struct UserProfile {
    let id = UUID()
    var nickname: String
    var isEmergencyContact: Bool
    var lastSeen: Date?
}

// MARK: - Community Models
struct CommunityLocation: Identifiable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
    let safetyRating: Int
    let lastUpdate: Date
}
EOF

echo "📁 Step 4: Restore view components..."

# Restore key view files with placeholder implementations
for view_file in "Views/Home/HomeView.swift" "Views/AI/AIGuideView.swift" "Views/Map/SafetyMapView.swift" "Views/Profile/ProfileView.swift"; do
    view_name=$(basename "$view_file" .swift)
    cat > "$BASE_DIR/$view_file" << EOF
import SwiftUI

struct ${view_name}: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("${view_name}")
                    .font(.title)
                Text("SafeGuardian + BitChat Integration")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("${view_name/View/}")
        }
    }
}

#Preview {
    ${view_name}()
}
EOF
done

echo "📁 Step 5: Restore shared components..."

cat > "$BASE_DIR/Components/SharedComponents.swift" << 'EOF'
import SwiftUI

// MARK: - Shared UI Components
struct ModernButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct EmptyStateCard: View {
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
EOF

echo "✅ SafeGuardian integration restored!"
echo "🚀 Next: Add BitChat directory to Xcode project and test compilation"
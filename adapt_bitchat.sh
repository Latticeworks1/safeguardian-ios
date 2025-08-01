#!/bin/bash

# Script to adapt BitChat code for SafeGuardian integration
echo "🔄 Adapting BitChat code for SafeGuardian..."

# Define the base directory
BASE_DIR="/Applications/safeguardian/safeguardian/safeguardian"

# Function to replace text in files
replace_in_files() {
    local search="$1"
    local replace="$2"
    local file_pattern="$3"
    
    echo "Replacing '$search' with '$replace' in $file_pattern files..."
    find "$BASE_DIR" -name "$file_pattern" -type f -exec sed -i '' "s/$search/$replace/g" {} +
}

# Function to replace class/struct names
replace_class_names() {
    echo "🏗️  Updating class and struct names..."
    
    # Main service classes
    replace_in_files "class BluetoothMeshService" "class SafeGuardianMeshService" "*.swift"
    replace_in_files "BluetoothMeshService(" "SafeGuardianMeshService(" "*.swift"
    replace_in_files "BluetoothMeshService\." "SafeGuardianMeshService." "*.swift"
    
    # Message types
    replace_in_files "class BitchatMessage" "class SafeGuardianMessage" "*.swift"
    replace_in_files "BitchatMessage(" "SafeGuardianMessage(" "*.swift"
    replace_in_files "BitchatMessage\." "SafeGuardianMessage." "*.swift"
    replace_in_files "\[BitchatMessage\]" "[SafeGuardianMessage]" "*.swift"
    
    # View model
    replace_in_files "class ChatViewModel" "class MeshChatViewModel" "*.swift"
    replace_in_files "ChatViewModel(" "MeshChatViewModel(" "*.swift"
    replace_in_files "ChatViewModel\." "MeshChatViewModel." "*.swift"
    
    # Update comments and documentation
    replace_in_files "bitchat" "SafeGuardian" "*.swift"
    replace_in_files "BitChat" "SafeGuardian" "*.swift"
    replace_in_files "BITCHAT" "SAFEGUARDIAN" "*.swift"
}

# Function to update import statements and app-specific references
update_imports() {
    echo "📦 Updating imports and app references..."
    
    # Update service UUID to be SafeGuardian-specific
    replace_in_files "F47B5E2D-4A9E-4C5A-9B3F-8E1D2C3A4B5C" "5AFE6UAR-D1A4-4C5A-9B3F-8E1D2C3A4B5C" "*.swift"
    replace_in_files "A1B2C3D4-E5F6-4A5B-8C9D-0E1F2A3B4C5D" "5AFE6UAR-D1A4-4A5B-8C9D-0E1F2A3B4C5D" "*.swift"
    
    # Update app group references
    replace_in_files "group.chat.bitchat" "group.safety.safeguardian" "*.swift"
    
    # Update keychain and storage keys
    replace_in_files "bitchat\.nickname" "safeguardian.nickname" "*.swift"
    replace_in_files "bitchat\.favorites" "safeguardian.favorites" "*.swift"
}

# Function to add safety-specific features
add_safety_features() {
    echo "🚨 Adding safety-specific adaptations..."
    
    # Add emergency message priority (placeholder - will be implemented later)
    # This is just a marker for where we'll add safety features
    echo "# TODO: Add emergency message priority handling" >> "$BASE_DIR/Services/P2P/SafeGuardianMeshService.swift"
    echo "# TODO: Add location sharing integration" >> "$BASE_DIR/Services/P2P/SafeGuardianMeshService.swift"
    echo "# TODO: Add safety protocol features" >> "$BASE_DIR/Services/P2P/SafeGuardianMeshService.swift"
}

# Execute the adaptations
replace_class_names
update_imports
add_safety_features

echo "✅ BitChat code adaptation complete!"
echo "📁 Files are organized in:"
echo "   - Services/P2P/ (networking and encryption)"
echo "   - Models/P2P/ (protocols and message models)"
echo "   - ViewModels/P2P/ (MVVM view models)"
echo ""
echo "🔧 Next steps:"
echo "   1. Add files to Xcode project"
echo "   2. Fix any remaining compilation errors"
echo "   3. Integrate with SafeGuardian views"
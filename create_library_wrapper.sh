#!/bin/bash

echo "🔄 Creating clean BitChat library wrapper for SafeGuardian..."

BASE_DIR="/Applications/safeguardian/safeguardian/safeguardian"

# Remove the problematic renamed files
echo "Cleaning up problematic renamed files..."
rm -rf "$BASE_DIR/Services/P2P"
rm -rf "$BASE_DIR/Models/P2P" 
rm -rf "$BASE_DIR/ViewModels/P2P"

# Copy BitChat files as-is (no renaming)
echo "Copying BitChat files as library..."
mkdir -p "$BASE_DIR/Services/BitChat"
mkdir -p "$BASE_DIR/Models/BitChat"
mkdir -p "$BASE_DIR/ViewModels/BitChat"

cp -r /Applications/bitchat/bitchat/Services/* "$BASE_DIR/Services/BitChat/"
cp -r /Applications/bitchat/bitchat/Protocols/* "$BASE_DIR/Models/BitChat/"
cp -r /Applications/bitchat/bitchat/ViewModels/* "$BASE_DIR/ViewModels/BitChat/"
cp -r /Applications/bitchat/bitchat/Noise "$BASE_DIR/Services/BitChat/"
cp -r /Applications/bitchat/bitchat/Utils "$BASE_DIR/Services/BitChat/"
cp -r /Applications/bitchat/bitchat/Identity "$BASE_DIR/Services/BitChat/"

echo "✅ BitChat library files copied without any renaming"
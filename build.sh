#!/bin/bash

set -e  # Exit on any error

# Function to display usage
usage() {
    echo "Usage: $0 [android|ios]"
    echo ""
    echo "Creates obfuscated release builds for Flutter projects"
    echo "  android - Creates App Bundle (.aab) with debug info in /opt/out/android"
    echo "  ios     - Creates IPA with debug info in /opt/out/ipa"
    exit 1
}

# Function to check if debug directory was created
check_debug_dir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        echo "❌ Error: Debug info directory not created at $dir"
        echo "   Flutter should have created this directory automatically"
        exit 1
    fi
}

# Function to build Android release
build_android() {
    local debug_dir="/opt/out/android"
    
    echo "Building Android App Bundle with obfuscation..."
    flutter build appbundle \
        --release \
        --obfuscate \
        --split-debug-info="$debug_dir"
    
    # Check if debug directory was created by Flutter
    check_debug_dir "$debug_dir"
    
    # Get the actual build output path
    local build_path="build/app/outputs/bundle/release/app-release.aab"
    
    if [ -f "$build_path" ]; then
        echo "✅ Android App Bundle created successfully!"
        echo "📱 App Bundle location: $(pwd)/$build_path"
        echo "🔍 Debug info location: $debug_dir"
    else
        echo "❌ Error: App Bundle not found at expected location"
        exit 1
    fi
}

# Function to build iOS release
build_ios() {
    local debug_dir="/opt/out/ipa"
    
    echo "Building iOS IPA with obfuscation..."
    flutter build ipa \
        --release \
        --obfuscate \
        --split-debug-info="$debug_dir"
    
    # Check if debug directory was created by Flutter
    check_debug_dir "$debug_dir"
    
    # Get the actual build output path
    local build_path="build/ios/ipa"
    local ipa_file=$(find "$build_path" -name "*.ipa" | head -1)
    
    if [ -n "$ipa_file" ] && [ -f "$ipa_file" ]; then
        echo "✅ iOS IPA created successfully!"
        echo "📱 IPA location: $(pwd)/$ipa_file"
        echo "🔍 Debug info location: $debug_dir"
    else
        echo "❌ Error: IPA file not found in build/ios/ipa/"
        exit 1
    fi
}

# Main script logic
main() {
    # Check if Flutter is installed
    if ! command -v flutter &> /dev/null; then
        echo "❌ Error: Flutter is not installed or not in PATH"
        exit 1
    fi
    
    # Check if we're in a Flutter project directory
    if [ ! -f "pubspec.yaml" ]; then
        echo "❌ Error: Not in a Flutter project directory (pubspec.yaml not found)"
        exit 1
    fi
    
    # Validate input parameter
    if [ $# -ne 1 ]; then
        echo "❌ Error: Platform parameter required"
        usage
    fi
    
    local platform="$1"
    
    case "$platform" in
        "android")
            echo "🚀 Starting Android release build..."
            build_android
            ;;
        "ios")
            echo "🚀 Starting iOS release build..."
            # Check if we're on macOS for iOS builds
            if [[ "$OSTYPE" != "darwin"* ]]; then
                echo "❌ Error: iOS builds require macOS"
                exit 1
            fi
            build_ios
            ;;
        *)
            echo "❌ Error: Invalid platform '$platform'"
            usage
            ;;
    esac
    
    echo ""
    echo "🎉 Release build completed successfully!"
}

# Run main function with all arguments
main "$@"
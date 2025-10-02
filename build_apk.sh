#!/bin/bash

# Build APK with optimizations
echo "🔨 Building Taqwa APK (split per ABI for smaller size)..."
flutter build apk --split-per-abi --no-tree-shake-icons

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ APK built successfully!"
    echo ""
    echo "📦 Build outputs:"
    echo "   - ARM 32-bit: build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk (~18MB)"
    echo "   - ARM 64-bit: build/app/outputs/flutter-apk/app-arm64-v8a-release.apk (~20MB)"
    echo "   - x86 64-bit:  build/app/outputs/flutter-apk/app-x86_64-release.apk (~21MB)"
    echo ""
    echo "💡 Tip: Use app-arm64-v8a-release.apk for modern devices (most common)"
else
    echo "❌ Build failed!"
    exit 1
fi

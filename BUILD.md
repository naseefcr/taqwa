# Building Taqwa App

## Build APK

Due to dynamic icon handling in the app, you need to build with the `--no-tree-shake-icons` flag.

### ⭐ Option 1: Using the build script (Recommended - Smallest size)
```bash
./build_apk.sh
```
This builds **split APKs** optimized for different CPU architectures:
- ARM 32-bit: ~18MB (older devices)
- ARM 64-bit: ~20MB (modern devices - **recommended**)
- x86 64-bit: ~21MB (emulators)

### Option 2: Single APK (for all devices)
```bash
flutter build apk --no-tree-shake-icons
```
**Size:** ~55MB (includes all architectures)

### Option 3: Split APKs manually
```bash
flutter build apk --split-per-abi --no-tree-shake-icons
```

### Option 4: App Bundle (for Play Store - Best option)
```bash
flutter build appbundle --no-tree-shake-icons
```
**Size:** ~30MB (Play Store optimizes for each device automatically)

## Why --no-tree-shake-icons?

The app uses dynamic IconData instances loaded from Firestore to allow users to customize category icons. This requires disabling icon tree shaking during the build process.

## Output Locations

### Split APKs (Recommended):
- **ARM 32-bit:** `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` (~18MB)
- **ARM 64-bit:** `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (~20MB) ⭐
- **x86 64-bit:** `build/app/outputs/flutter-apk/app-x86_64-release.apk` (~21MB)

### Single APK:
- **Universal:** `build/app/outputs/flutter-apk/app-release.apk` (~55MB)

### App Bundle:
- **Bundle:** `build/app/outputs/bundle/release/app-release.aab` (~30MB)

## Which build should I use?

| Build Type | Size | Use Case |
|------------|------|----------|
| **Split APK (arm64-v8a)** | ~20MB | ⭐ Most modern Android devices (2017+) |
| **Split APK (armeabi-v7a)** | ~18MB | Older Android devices (before 2017) |
| **Single APK** | ~55MB | Testing on multiple devices |
| **App Bundle** | ~30MB | 🎯 Google Play Store (best option) |

## Recommended Distribution Strategy

1. **For Play Store:** Use App Bundle (`flutter build appbundle --no-tree-shake-icons`)
2. **For Direct Install:** Use Split APK arm64-v8a (~20MB) - works on 99% of modern devices
3. **For Testing:** Use Single APK (~55MB) - works on all devices

## Build Configuration

The `flutter_build.yaml` file is configured to disable icon tree shaking by default.

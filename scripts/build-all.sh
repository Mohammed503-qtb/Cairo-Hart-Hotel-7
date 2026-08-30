#!/usr/bin/env bash
# Build the Lumière Grand Hotel platform for all production targets.
# Usage: ./scripts/build-all.sh [web|android|ios|desktop|all]
set -euo pipefail

TARGET="${1:-all}"

echo "▶ Flutter version:"
flutter --version

flutter pub get

build_web() {
  echo "▶ Building Web (release)…"
  flutter build web --release --web-renderer canvaskit
  echo "✓ Web → build/web"
}

build_android() {
  echo "▶ Building Android APK (release)…"
  flutter build apk --release
  echo "▶ Building Android AAB (release)…"
  flutter build appbundle --release
  echo "✓ APK → build/app/outputs/flutter-apk/"
  echo "✓ AAB → build/app/outputs/flutter-bundle/"
}

build_ios() {
  echo "▶ Building iOS (release)…"
  if [[ "$(uname)" == "Darwin" ]]; then
    flutter build ipa --release || flutter build ios --release --no-codesign
    echo "✓ IPA → build/ios/ipa/"
  else
    echo "ℹ iOS builds require macOS — skipping."
  fi
}

build_desktop() {
  case "$(uname -s)" in
    Linux*)
      echo "▶ Building Linux (release)…"
      flutter build linux --release
      echo "✓ Linux → build/linux/x64/release/bundle/"
      ;;
    Darwin)
      echo "▶ Building macOS (release)…"
      flutter build macos --release
      echo "✓ macOS → build/macos/Build/Products/Release/"
      ;;
    MINGW*|MSYS*|CYGWIN*)
      echo "▶ Building Windows (release)…"
      flutter build windows --release
      echo "✓ Windows → build/windows/x64/runner/Release/"
      ;;
  esac
}

case "$TARGET" in
  web) build_web ;;
  android) build_android ;;
  ios) build_ios ;;
  desktop) build_desktop ;;
  all)
    build_web
    build_android
    build_ios
    build_desktop
    ;;
  *)
    echo "Unknown target: $TARGET"
    echo "Usage: $0 [web|android|ios|desktop|all]"
    exit 1
    ;;
esac

echo "✅ Done."

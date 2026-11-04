#!/usr/bin/env bash
# One-time setup (needs Flutter + Android SDK on your Ubuntu machine).
set -e
cd "$(dirname "$0")"
if [ ! -d android ]; then
  tmp=$(mktemp -d)
  flutter create --org com.happiness --project-name kasuku --platforms android "$tmp/kasuku"
  cp -r "$tmp/kasuku/android" ./android
  cp "$tmp/kasuku/analysis_options.yaml" . 2>/dev/null || true
fi
python3 tool/patch_android.py
flutter pub get
echo "--- analyze (send me anything red) ---"
flutter analyze || true
echo "--- unit tests ---"
flutter test || true
echo
echo "Run the Core Lab on your phone:  flutter run --release"

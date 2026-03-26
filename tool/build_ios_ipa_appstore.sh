#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "==> Flutter clean build ios"
flutter pub get
flutter build ipa --release --export-options-plist=ios/ExportOptions-AppStore.plist

echo "==> IPA generee:"
ls -lh "$ROOT_DIR/build/ios/ipa/Runner.ipa"

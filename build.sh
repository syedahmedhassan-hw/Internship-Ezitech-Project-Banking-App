#!/bin/bash
set -e

echo "=== Installing Flutter SDK ==="
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable flutter
fi

export PATH="$PATH:$(pwd)/flutter/bin"

echo "=== Flutter Version ==="
flutter --version

echo "=== Building Flutter Web ==="
flutter config --no-analytics
flutter build web --release

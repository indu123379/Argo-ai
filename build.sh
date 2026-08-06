#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status

# 1. Setup Flutter
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 flutter
fi

# PREPEND to PATH to override Netlify's default flutter
export PATH="`pwd`/flutter/bin:$PATH"

# 2. Configure
flutter config --enable-web
flutter doctor

# 3. Build contents
echo "GROQ_API_KEY=${GROQ_API_KEY}" > .env
flutter pub get

# Build with explicit renderer
flutter build web --release --web-renderer html

# 4. Final check
if [ -d "build/web" ]; then
  echo "Build successful! Files generated in build/web"
  ls -la build/web
else
  echo "Error: build/web directory not found!"
  exit 1
fi

#!/usr/bin/env bash
set -e
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build appbundle --release
echo "Release bundle at build/app/outputs/bundle/release/app-release.aab"

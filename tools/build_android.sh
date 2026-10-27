#!/bin/bash
# Builds a debug APK of the game: build/NitroUnderground.apk
# Needs: GODOT (path to the Godot 4.7 editor binary) with Android export templates installed,
# an Android SDK path set in the editor settings, and a debug keystore.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
mkdir -p build
"$GODOT" --headless --import
"$GODOT" --headless --export-debug "Android" build/NitroUnderground.apk
echo "APK: build/NitroUnderground.apk"

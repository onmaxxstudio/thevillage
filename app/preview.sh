#!/usr/bin/env bash
set -euo pipefail

PREVIEW_PORT="${PREVIEW_PORT:-4173}"

cd "$(dirname "$0")"

echo "Building Ask the Village web preview..."
flutter pub get
flutter build web

echo "Serving preview on http://0.0.0.0:${PREVIEW_PORT}"
echo "Keep this terminal open while previewing."
exec python3 -m http.server "${PREVIEW_PORT}" --bind 0.0.0.0 --directory build/web

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "[1/3] Generate project"
xcodegen generate

echo "[2/3] Run unit tests"
xcodebuild \
  -project "$ROOT_DIR/FlightFinder.xcodeproj" \
  -scheme FlightFinder \
  -destination 'platform=macOS' \
  -derivedDataPath "$ROOT_DIR/.derivedData" \
  test

echo "[3/3] Optional browser smoke test"
if command -v node >/dev/null 2>&1; then
  if node -e "import('playwright').then(() => process.exit(0)).catch(() => process.exit(1));" >/dev/null 2>&1; then
    node "$ROOT_DIR/scripts/provider_smoke_playwright.mjs" \
      --china-mode \
      --timeout-ms 15000 \
      --out "$ROOT_DIR/docs/provider_smoke_latest.json"
    echo "Playwright smoke test saved at docs/provider_smoke_latest.json"
  else
    echo "Playwright not installed in Node environment; skipping smoke test."
  fi
else
  echo "Node not installed; skipping smoke test."
fi

echo "Validation complete."

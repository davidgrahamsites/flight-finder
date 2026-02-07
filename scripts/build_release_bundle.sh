#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$ROOT_DIR/build/release"
DERIVED_DATA="$ROOT_DIR/.derivedData-release"
ARCHIVE_PATH="$BUILD_ROOT/FlightFinder.xcarchive"
APP_NAME="FlightFinder.app"

CLEAN=false
CUSTOM_VERSION=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --clean)
      CLEAN=true
      shift
      ;;
    --version)
      CUSTOM_VERSION="${2:-}"
      if [[ -z "$CUSTOM_VERSION" ]]; then
        echo "--version requires a value" >&2
        exit 1
      fi
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      echo "Usage: $0 [--clean] [--version <version>]" >&2
      exit 1
      ;;
  esac
done

marketing_version="$(awk '/MARKETING_VERSION:/ {print $2; exit}' "$ROOT_DIR/project.yml")"
build_number="$(awk '/CURRENT_PROJECT_VERSION:/ {print $2; exit}' "$ROOT_DIR/project.yml")"
version="${CUSTOM_VERSION:-$marketing_version}"

if [[ "$CLEAN" == true ]]; then
  rm -rf "$BUILD_ROOT" "$DERIVED_DATA"
fi

mkdir -p "$BUILD_ROOT"

echo "[1/5] Generate Xcode project"
(
  cd "$ROOT_DIR"
  xcodegen generate
)

echo "[2/5] Run release archive build (unsigned)"
xcodebuild \
  -project "$ROOT_DIR/FlightFinder.xcodeproj" \
  -scheme FlightFinder \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -archivePath "$ARCHIVE_PATH" \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM="" \
  archive

APP_SOURCE="$ARCHIVE_PATH/Products/Applications/$APP_NAME"
if [[ ! -d "$APP_SOURCE" ]]; then
  echo "Archive did not produce $APP_NAME at expected path: $APP_SOURCE" >&2
  exit 2
fi

APP_OUTPUT="$BUILD_ROOT/$APP_NAME"
rm -rf "$APP_OUTPUT"
cp -R "$APP_SOURCE" "$APP_OUTPUT"

artifact_basename="FlightFinder-macos-v${version}-b${build_number}-unsigned"
zip_path="$BUILD_ROOT/${artifact_basename}.zip"
checksum_path="$BUILD_ROOT/${artifact_basename}.sha256"

echo "[3/5] Create zip artifact"
(
  cd "$BUILD_ROOT"
  rm -f "$zip_path"
  ditto -c -k --sequesterRsrc --keepParent "$APP_NAME" "$zip_path"
)

echo "[4/5] Generate checksum"
(
  cd "$BUILD_ROOT"
  shasum -a 256 "$(basename "$zip_path")" > "$(basename "$checksum_path")"
)

echo "[5/5] Release artifact summary"
printf 'Version: %s\n' "$version"
printf 'Build: %s\n' "$build_number"
printf 'Archive: %s\n' "$ARCHIVE_PATH"
printf 'App: %s\n' "$APP_OUTPUT"
printf 'Zip: %s\n' "$zip_path"
printf 'SHA256: %s\n' "$checksum_path"


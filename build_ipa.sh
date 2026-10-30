#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

PROJECT="ChessChild.xcodeproj"
SCHEME="ChessChild"
CONFIGURATION="Release"
BUILD_DIR="$ROOT_DIR/build"
APP_PATH="$BUILD_DIR/Build/Products/Release-iphoneos/ChessChild.app"
IPA_DIR="$BUILD_DIR/ipa"
IPA_PATH="$IPA_DIR/ChessChild-unsigned.ipa"

UPLOAD=false
if [[ "${1:-}" == "--upload" && $# -eq 1 ]]; then
    UPLOAD=true
elif [[ $# -ne 0 ]]; then
    echo "Usage: $0 [--upload]" >&2
    exit 2
fi

for tool in xcodebuild zip; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Missing required tool: $tool" >&2
        exit 1
    fi
done

echo "[1/3] Checking Xcode project..."
if [[ ! -f "$PROJECT/project.pbxproj" ]]; then
    echo "Xcode project was not found: $PROJECT/project.pbxproj" >&2
    exit 1
fi

echo "[2/3] Building unsigned iOS app..."
xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -sdk iphoneos \
    -derivedDataPath "$BUILD_DIR" \
    CODE_SIGNING_ALLOWED=NO \
    build

if [[ ! -d "$APP_PATH" ]]; then
    echo "Build succeeded but app was not found: $APP_PATH" >&2
    exit 1
fi

echo "[3/3] Packaging IPA..."
mkdir -p "$IPA_DIR"
STAGING_DIR="$(mktemp -d)"
trap 'rm -rf -- "$STAGING_DIR"' EXIT
mkdir -p "$STAGING_DIR/Payload"
cp -R "$APP_PATH" "$STAGING_DIR/Payload/"
(
    cd "$STAGING_DIR"
    zip -qry ChessChild-unsigned.ipa Payload
)
mv -f "$STAGING_DIR/ChessChild-unsigned.ipa" "$IPA_PATH"

if [[ ! -s "$IPA_PATH" ]]; then
    echo "IPA was not created: $IPA_PATH" >&2
    exit 1
fi

echo "IPA created: $IPA_PATH"

if [[ "$UPLOAD" == true ]]; then
    SERVER_USER="${CHESSCHILD_SERVER_USER:-root}"
    SERVER_HOST="${CHESSCHILD_SERVER_HOST:-192.168.11.224}"
    SERVER_PATH="${CHESSCHILD_SERVER_PATH:-/home/smartnet/}"

    if ! command -v scp >/dev/null 2>&1; then
        echo "Upload requested but scp is not installed." >&2
        exit 1
    fi

    echo "Uploading to $SERVER_USER@$SERVER_HOST:$SERVER_PATH"
    scp "$IPA_PATH" "$SERVER_USER@$SERVER_HOST:$SERVER_PATH/"
    echo "Upload completed."
fi

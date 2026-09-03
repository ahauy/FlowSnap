#!/bin/bash
set -euo pipefail

# ==============================================================================
# FlowSnap — DMG Packaging Script
# Builds FlowSnap in Release mode and packages it into a distributable .dmg
# Author: Vũ Tuấn Hậu
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build"
DERIVED_DATA="${BUILD_DIR}/DerivedData"
STAGING_DIR="${BUILD_DIR}/dmg_staging"

APP_NAME="FlowSnap"
SCHEME_NAME="FlowSnap"
PROJECT_FILE="${PROJECT_ROOT}/FlowSnap.xcodeproj"

# Read version if available
VERSION="1.3.0"
if [ -f "${PROJECT_ROOT}/version.json" ]; then
    VERSION=$(grep '"version"' "${PROJECT_ROOT}/version.json" | head -n 1 | awk -F '"' '{print $4}')
fi

DMG_NAME="${APP_NAME}-${VERSION}.dmg"
DMG_PATH="${BUILD_DIR}/${DMG_NAME}"
VOL_NAME="${APP_NAME}"

echo "========================================================"
echo "🚀 Building & Packaging ${APP_NAME} v${VERSION} into DMG"
echo "========================================================"

# Step 1: Ensure Xcode project exists
if [ ! -d "${PROJECT_FILE}" ]; then
    echo "⚠️  ${PROJECT_FILE} not found. Running xcodegen..."
    if command -v xcodegen &> /dev/null; then
        (cd "${PROJECT_ROOT}" && xcodegen generate)
    else
        echo "❌ Error: Xcode project missing and xcodegen is not installed."
        exit 1
    fi
fi

# Step 2: Clean previous build artifacts
rm -rf "${STAGING_DIR}"
mkdir -p "${STAGING_DIR}"
mkdir -p "${BUILD_DIR}"

# Step 3: Build FlowSnap in Release configuration
echo "🔨 Compiling ${SCHEME_NAME} (Release)..."
xcodebuild \
    -project "${PROJECT_FILE}" \
    -scheme "${SCHEME_NAME}" \
    -configuration Release \
    -destination 'platform=macOS' \
    -derivedDataPath "${DERIVED_DATA}" \
    build | grep -E "(error:|BUILD FAILED|BUILD SUCCEEDED)" || true

APP_PATH="${DERIVED_DATA}/Build/Products/Release/${APP_NAME}.app"

if [ ! -d "${APP_PATH}" ]; then
    echo "❌ Error: ${APP_PATH} was not found after build."
    exit 1
fi

echo "✅ App successfully built at: ${APP_PATH}"

# Step 4: Prepare DMG staging area
echo "📦 Staging application..."
cp -R "${APP_PATH}" "${STAGING_DIR}/${APP_NAME}.app"

# Create symlink to /Applications for drag-and-drop install
ln -s /Applications "${STAGING_DIR}/Applications"

# Step 5: Create DMG using hdiutil
echo "💿 Creating compressed DMG image..."
rm -f "${DMG_PATH}"

hdiutil create \
    -volname "${VOL_NAME}" \
    -srcfolder "${STAGING_DIR}" \
    -ov \
    -format UDZO \
    "${DMG_PATH}"

# Step 6: Cleanup staging
rm -rf "${STAGING_DIR}"

# Step 7: Print result
if [ -f "${DMG_PATH}" ]; then
    FILE_SIZE=$(du -h "${DMG_PATH}" | cut -f1)
    echo "========================================================"
    echo "🎉 SUCCESS: Created ${DMG_NAME} (${FILE_SIZE})"
    echo "📍 Path: ${DMG_PATH}"
    echo "👉 You can open and test it with:"
    echo "   open \"${DMG_PATH}\""
    echo "========================================================"
else
    echo "❌ Error: Failed to generate DMG."
    exit 1
fi

#!/bin/bash
set -euo pipefail

# ==============================================================================
# FlowSnap 🪟⚡ — Automated One-Line macOS Installer
#
# Usage:
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ahauy/FlowSnap/main/scripts/install.sh)"
#
# What this script does:
#   1. Checks macOS compatibility (macOS 14.0 Sonoma or later)
#   2. Fetches the latest FlowSnap release DMG from GitHub
#   3. Mounts the DMG and installs FlowSnap.app into /Applications
#   4. Removes Gatekeeper quarantine attribute
#   5. Guides the user to grant macOS Accessibility permissions
# ==============================================================================

REPO="ahauy/FlowSnap"
APP_NAME="FlowSnap"
TARGET_DIR="/Applications"
APP_PATH="${TARGET_DIR}/${APP_NAME}.app"

# Terminal Colors
BOLD="\033[1m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

echo -e "${BOLD}${BLUE}"
echo "========================================================"
echo "          FlowSnap 🪟⚡ — macOS Installer"
echo "        Your Mac. Your Layout. Your Flow."
echo "========================================================"
echo -e "${RESET}"

# Step 1: Verify macOS
OS_TYPE="$(uname -s)"
if [ "${OS_TYPE}" != "Darwin" ]; then
    echo -e "${RED}❌ Error: FlowSnap is exclusively designed for macOS.${RESET}"
    exit 1
fi

MACOS_VERSION="$(sw_vers -productVersion)"
MACOS_MAJOR="$(echo "${MACOS_VERSION}" | cut -d. -f1)"

if [ "${MACOS_MAJOR}" -lt 14 ]; then
    echo -e "${RED}❌ Error: FlowSnap requires macOS 14.0 (Sonoma) or later.${RESET}"
    echo -e "   Current macOS version detected: ${MACOS_VERSION}"
    exit 1
fi

echo -e "✅ Detected macOS: ${BOLD}${MACOS_VERSION}${RESET} ($(uname -m))"

# Step 2: Determine Download URL (Latest GitHub Release)
echo -e "🔍 Resolving latest release for ${BOLD}${REPO}${RESET}..."

LATEST_RELEASE_JSON=$(curl -sSL "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null || true)
DOWNLOAD_URL=""

if [ -n "${LATEST_RELEASE_JSON}" ]; then
    DOWNLOAD_URL=$(echo "${LATEST_RELEASE_JSON}" | grep "browser_download_url.*\.dmg" | head -n 1 | cut -d '"' -f 4 || true)
fi

# Fallback to direct latest release asset name if API response is empty/rate-limited
if [ -z "${DOWNLOAD_URL}" ]; then
    DOWNLOAD_URL="https://github.com/${REPO}/releases/latest/download/FlowSnap.dmg"
fi

TEMP_DIR="$(mktemp -d -t flowsnap-install-XXXXXX)"
TEMP_DMG="${TEMP_DIR}/FlowSnap.dmg"
MOUNT_DIR="${TEMP_DIR}/mount"

cleanup() {
    if [ -d "${MOUNT_DIR}" ]; then
        hdiutil detach "${MOUNT_DIR}" -quiet 2>/dev/null || true
    fi
    rm -rf "${TEMP_DIR}"
}
trap cleanup EXIT INT TERM

echo -e "⬇️  Downloading FlowSnap from: ${BLUE}${DOWNLOAD_URL}${RESET}"
if ! curl -fSL --progress-bar "${DOWNLOAD_URL}" -o "${TEMP_DMG}"; then
    echo -e "${YELLOW}⚠️  Could not download pre-built release binary from GitHub Releases.${RESET}"
    echo -e "   If this release is not yet published on GitHub, you can build from source:"
    echo -e "   ${BOLD}git clone https://github.com/${REPO}.git && cd FlowSnap && ./scripts/build-dmg.sh${RESET}"
    exit 1
fi

# Step 3: Mount DMG
echo -e "💿 Mounting DMG image..."
mkdir -p "${MOUNT_DIR}"
hdiutil attach "${TEMP_DMG}" -mountpoint "${MOUNT_DIR}" -nobrowse -quiet

SOURCE_APP="${MOUNT_DIR}/${APP_NAME}.app"
if [ ! -d "${SOURCE_APP}" ]; then
    # Try finding any .app inside mount
    FOUND_APP=$(find "${MOUNT_DIR}" -maxdepth 2 -name "*.app" | head -n 1)
    if [ -n "${FOUND_APP}" ]; then
        SOURCE_APP="${FOUND_APP}"
    else
        echo -e "${RED}❌ Error: ${APP_NAME}.app not found in mounted DMG.${RESET}"
        exit 1
    fi
fi

# Step 4: Install to /Applications
echo -e "📦 Installing ${BOLD}${APP_NAME}.app${RESET} to ${TARGET_DIR}..."

# Close existing instance if running
if pgrep -x "${APP_NAME}" >/dev/null 2>&1; then
    echo -e "⚠️  Closing currently running ${APP_NAME}..."
    killall "${APP_NAME}" 2>/dev/null || true
    sleep 1
fi

if [ -w "${TARGET_DIR}" ]; then
    rm -rf "${APP_PATH}"
    cp -R "${SOURCE_APP}" "${TARGET_DIR}/"
else
    echo -e "🔒 Administrator privileges required to write to ${TARGET_DIR}:"
    sudo rm -rf "${APP_PATH}"
    sudo cp -R "${SOURCE_APP}" "${TARGET_DIR}/"
fi

# Step 5: Remove Quarantine Attribute (Gatekeeper)
echo -e "🛡️  Clearing Gatekeeper quarantine attribute..."
xattr -cr "${APP_PATH}" 2>/dev/null || true

# Step 6: Unmount DMG
hdiutil detach "${MOUNT_DIR}" -quiet

echo -e "${GREEN}${BOLD}🎉 Installation Complete!${RESET}"
echo ""
echo -e "${BOLD}Next Steps:${RESET}"
echo -e "1. ${BOLD}Launch FlowSnap:${RESET} FlowSnap is located in ${BLUE}/Applications/FlowSnap.app${RESET}"
echo -e "2. ${BOLD}Grant Accessibility Permission:${RESET}"
echo -e "   FlowSnap requires Accessibility access to snap and resize windows."
echo -e "   Go to: ${BOLD}System Settings → Privacy & Security → Accessibility${RESET} and toggle ${GREEN}FlowSnap ON${RESET}."
echo ""

# Optional: Prompt to launch app immediately
if [ -t 0 ]; then
    read -r -p "🚀 Do you want to launch FlowSnap right now? [Y/n] " response
    case "$response" in
        [nN][oO]|[nN])
            echo "You can open FlowSnap anytime from Spotlight or /Applications."
            ;;
        *)
            echo "Launching FlowSnap..."
            open "${APP_PATH}"
            ;;
    esac
else
    # Non-interactive shell (piped curl)
    echo "Launching FlowSnap..."
    open "${APP_PATH}" 2>/dev/null || true
fi

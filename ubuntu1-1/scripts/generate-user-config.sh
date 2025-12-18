#!/bin/bash
# Generate machine-specific user configuration for Home Manager
# This script detects user/system info and generates user-config.nix
# Returns: Nix system identifier (e.g., "x86_64-linux") on stdout

set -e
set -u

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Detect user information
CURRENT_USER="${USER:-$(whoami)}"
HOME_DIR="${HOME:-/home/${CURRENT_USER}}"

# Detect system information
ARCH=$(uname -m)
HOSTNAME=$(hostname)
KERNEL=$(uname -r)

# Detect OS information
if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    OS_INFO="${PRETTY_NAME:-Unknown OS}"
else
    OS_INFO="Unknown OS"
fi

# Validate required values
if [ -z "${CURRENT_USER}" ]; then
    echo -e "${RED}ERROR: Could not detect username${NC}" >&2
    exit 1
fi

if [ -z "${HOME_DIR}" ]; then
    echo -e "${RED}ERROR: Could not detect home directory${NC}" >&2
    exit 1
fi

# Map architecture to Nix system identifier
case "${ARCH}" in
    x86_64)
        NIX_SYSTEM="x86_64-linux"
        ;;
    aarch64|arm64)
        NIX_SYSTEM="aarch64-linux"
        ;;
    *)
        echo -e "${RED}ERROR: Unsupported architecture: ${ARCH}${NC}" >&2
        echo "Supported architectures: x86_64, aarch64, arm64" >&2
        exit 1
        ;;
esac

# Determine file paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="${SCRIPT_DIR}/../home-manager/user-config.nix.template"
USER_CONFIG_FILE="${SCRIPT_DIR}/../home-manager/user-config.nix"

# Validate template file exists
if [ ! -f "${TEMPLATE_FILE}" ]; then
    echo -e "${RED}ERROR: Template file not found!${NC}" >&2
    echo -e "${RED}Expected location: ${TEMPLATE_FILE}${NC}" >&2
    echo "" >&2
    echo "The template file is required to generate user-config.nix." >&2
    echo "This file should be tracked in Git. If it's missing:" >&2
    echo "  1. Check if you have the latest version from Git" >&2
    echo "  2. Run: git pull origin main" >&2
    echo "  3. Verify: ls -la ${TEMPLATE_FILE}" >&2
    echo "" >&2
    echo "If the problem persists, the repository may be corrupted." >&2
    exit 1
fi

# Generate user-config.nix from template using sed
sed -e "s|@USERNAME@|${CURRENT_USER}|g" \
    -e "s|@HOME_DIRECTORY@|${HOME_DIR}|g" \
    -e "s|@HOSTNAME@|${HOSTNAME}|g" \
    -e "s|@NIX_SYSTEM@|${NIX_SYSTEM}|g" \
    -e "s|@ARCH@|${ARCH}|g" \
    -e "s|@OS_INFO@|${OS_INFO}|g" \
    -e "s|@KERNEL@|${KERNEL}|g" \
    -e "s|@GENERATION_DATE@|$(date -u +"%Y-%m-%d %H:%M:%S UTC")|g" \
    "${TEMPLATE_FILE}" > "${USER_CONFIG_FILE}"

# Make Git aware of the file without staging it
# This allows Nix flakes to see the file while keeping it gitignored
if git rev-parse --git-dir >/dev/null 2>&1; then
    # We're in a git repository
    git add --intent-to-add "${USER_CONFIG_FILE}" 2>/dev/null || true
fi

# Verify file was created successfully
if [ ! -f "${USER_CONFIG_FILE}" ]; then
    echo -e "${RED}ERROR: Failed to generate ${USER_CONFIG_FILE}${NC}" >&2
    exit 1
fi

# Output Nix system identifier for Makefile/scripts to capture
echo "${NIX_SYSTEM}"

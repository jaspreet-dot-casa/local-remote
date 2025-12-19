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

# Helper function to escape strings for safe use in sed replacement
# Escapes: backslashes, ampersands, pipe (our delimiter), and newlines
escape_sed() {
    local input="$1"
    # Escape backslashes first (must be first!)
    input="${input//\\/\\\\}"
    # Escape ampersands (sed replacement metacharacter)
    input="${input//&/\\&}"
    # Escape pipes (our chosen delimiter)
    input="${input//|/\\|}"
    # Convert literal newlines to escaped form
    input="${input//$'\n'/\\n}"
    echo "${input}"
}

# Detect user information
CURRENT_USER="${USER:-$(whoami)}"
HOME_DIR="${HOME:-/home/${CURRENT_USER}}"

# Detect system information
ARCH=$(uname -m)
HOSTNAME=$(hostname)
KERNEL=$(uname -r)

# Detect or prompt for Git configuration
# Try environment variables first, fall back to defaults if not set
if [ -n "${GIT_USER_NAME:-}" ] && [ -n "${GIT_USER_EMAIL:-}" ]; then
    # Environment variables provided
    GIT_NAME="${GIT_USER_NAME}"
    GIT_EMAIL="${GIT_USER_EMAIL}"
else
    # Use defaults (can be overridden with environment variables)
    GIT_NAME="${GIT_USER_NAME:-Jaspreet Singh}"
    GIT_EMAIL="${GIT_USER_EMAIL:-6873201+tagpro@users.noreply.github.com}"
fi

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

# Escape all variables for safe sed substitution
SAFE_USER=$(escape_sed "${CURRENT_USER}")
SAFE_HOME=$(escape_sed "${HOME_DIR}")
SAFE_GIT_NAME=$(escape_sed "${GIT_NAME}")
SAFE_GIT_EMAIL=$(escape_sed "${GIT_EMAIL}")
SAFE_HOSTNAME=$(escape_sed "${HOSTNAME}")
SAFE_NIX_SYSTEM=$(escape_sed "${NIX_SYSTEM}")
SAFE_ARCH=$(escape_sed "${ARCH}")
SAFE_OS_INFO=$(escape_sed "${OS_INFO}")
SAFE_KERNEL=$(escape_sed "${KERNEL}")
SAFE_DATE=$(escape_sed "$(date -u +"%Y-%m-%d %H:%M:%S UTC")")

# Generate user-config.nix from template using sed with escaped variables
sed -e "s|@USERNAME@|${SAFE_USER}|g" \
    -e "s|@HOME_DIRECTORY@|${SAFE_HOME}|g" \
    -e "s|@GIT_USER_NAME@|${SAFE_GIT_NAME}|g" \
    -e "s|@GIT_USER_EMAIL@|${SAFE_GIT_EMAIL}|g" \
    -e "s|@HOSTNAME@|${SAFE_HOSTNAME}|g" \
    -e "s|@NIX_SYSTEM@|${SAFE_NIX_SYSTEM}|g" \
    -e "s|@ARCH@|${SAFE_ARCH}|g" \
    -e "s|@OS_INFO@|${SAFE_OS_INFO}|g" \
    -e "s|@KERNEL@|${SAFE_KERNEL}|g" \
    -e "s|@GENERATION_DATE@|${SAFE_DATE}|g" \
    "${TEMPLATE_FILE}" > "${USER_CONFIG_FILE}"

# Make Git aware of the file without staging it
# This allows Nix flakes to see the file while keeping it gitignored
if git rev-parse --git-dir >/dev/null 2>&1; then
    # We're in a git repository
    # Only add intent-to-add if file is untracked
    if ! git ls-files --error-unmatch "${USER_CONFIG_FILE}" >/dev/null 2>&1; then
        git add --intent-to-add "${USER_CONFIG_FILE}" 2>/dev/null || true
    fi
fi

# Verify file was created successfully
if [ ! -f "${USER_CONFIG_FILE}" ]; then
    echo -e "${RED}ERROR: Failed to generate ${USER_CONFIG_FILE}${NC}" >&2
    exit 1
fi

# Output Nix system identifier for Makefile/scripts to capture
echo "${NIX_SYSTEM}"

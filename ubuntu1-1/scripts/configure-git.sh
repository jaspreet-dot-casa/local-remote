#!/bin/bash
set -e
set -u

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo_success() { echo -e "${GREEN}✓${NC} $1"; }
echo_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
echo_error() { echo -e "${RED}✗${NC} $1"; }
echo_info() { echo -e "${YELLOW}➜${NC} $1"; }

# Fix git config file permissions if they exist and are not writable
GIT_CONFIG_DIR="${HOME}/.config/git"
GIT_CONFIG_FILE="${GIT_CONFIG_DIR}/config"
CURRENT_USER="${USER:-$(whoami)}"

if [ -d "${GIT_CONFIG_DIR}" ] && [ ! -w "${GIT_CONFIG_DIR}" ]; then
    echo_warning "Git config directory not writable, attempting to fix permissions..."
    # First try without sudo
    if chmod -R u+w "${GIT_CONFIG_DIR}" 2>/dev/null; then
        echo_success "Fixed permissions"
    else
        # If that fails, try with sudo (likely owned by root)
        echo_info "Attempting to fix ownership (may require sudo password)..."
        if sudo chown -R "${CURRENT_USER}:${CURRENT_USER}" "${GIT_CONFIG_DIR}" 2>/dev/null; then
            chmod -R u+w "${GIT_CONFIG_DIR}"
            echo_success "Fixed ownership and permissions"
        else
            echo_error "Could not fix git config permissions"
            echo_info "Please run: sudo chown -R ${CURRENT_USER}:${CURRENT_USER} ${GIT_CONFIG_DIR}"
            exit 1
        fi
    fi
fi

if [ -f "${GIT_CONFIG_FILE}" ] && [ ! -w "${GIT_CONFIG_FILE}" ]; then
    echo_warning "Git config file not writable, attempting to fix permissions..."
    # First try without sudo
    if chmod u+w "${GIT_CONFIG_FILE}" 2>/dev/null; then
        echo_success "Fixed file permissions"
    else
        # If that fails, try with sudo
        echo_info "Attempting to fix file ownership (may require sudo password)..."
        if sudo chown "${CURRENT_USER}:${CURRENT_USER}" "${GIT_CONFIG_FILE}" 2>/dev/null; then
            chmod u+w "${GIT_CONFIG_FILE}"
            echo_success "Fixed file ownership and permissions"
        else
            echo_error "Could not fix git config file permissions"
            echo_info "Please run: sudo chown ${CURRENT_USER}:${CURRENT_USER} ${GIT_CONFIG_FILE}"
            exit 1
        fi
    fi
fi

# Check if git config is already set
CURRENT_NAME=$(git config --global user.name 2>/dev/null || true)
CURRENT_EMAIL=$(git config --global user.email 2>/dev/null || true)

# Detect CI environment (GitHub Actions, GitLab CI, Jenkins, etc.)
if [ -n "${CI:-}" ] || [ -n "${GITHUB_ACTIONS:-}" ] || [ -n "${GITLAB_CI:-}" ]; then
    echo_info "CI environment detected, skipping interactive Git configuration"
    if [ -n "${CURRENT_NAME}" ] && [ -n "${CURRENT_EMAIL}" ]; then
        echo_success "Git already configured: ${CURRENT_NAME} <${CURRENT_EMAIL}>"
    else
        echo_warning "Git not configured in CI environment"
        echo_info "To configure, run these commands before 'make install':"
        echo_info "  git config --global user.name 'Your Name'"
        echo_info "  git config --global user.email 'your@email.com'"
    fi
    exit 0
fi

# Interactive mode for local usage
if [ -n "${CURRENT_NAME}" ] && [ -n "${CURRENT_EMAIL}" ]; then
    echo_success "Git already configured:"
    echo "  Name:  ${CURRENT_NAME}"
    echo "  Email: ${CURRENT_EMAIL}"
    echo ""
    read -p "Do you want to reconfigure? (y/N): " -r RECONFIGURE
    if [[ ! ${RECONFIGURE} =~ ^[Yy]$ ]]; then
        echo_info "Keeping existing git configuration"
        exit 0
    fi
fi

# Prompt for git configuration
echo ""
echo "Please enter your Git configuration:"
read -p "Git Name (e.g., John Doe): " -r GIT_NAME
read -p "Git Email (e.g., john@example.com): " -r GIT_EMAIL

# Validate input
if [ -z "${GIT_NAME}" ] || [ -z "${GIT_EMAIL}" ]; then
    echo_warning "Git name or email not provided"
    echo "Git configuration skipped. You can run this script again later."
    exit 0
fi

# Set git config
git config --global user.name "${GIT_NAME}"
git config --global user.email "${GIT_EMAIL}"

echo_success "Git configured: ${GIT_NAME} <${GIT_EMAIL}>"

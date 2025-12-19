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

# Fix git config file permissions and ownership issues
GIT_CONFIG_DIR="${HOME}/.config/git"
GIT_CONFIG_FILE="${GIT_CONFIG_DIR}/config"
CURRENT_USER="${USER:-$(whoami)}"

# Ensure ~/.config exists and is owned by the current user
if [ -d "${HOME}/.config" ] && [ ! -w "${HOME}/.config" ]; then
    echo_warning "${HOME}/.config directory not writable, fixing ownership..."
    sudo chown -R "${CURRENT_USER}:${CURRENT_USER}" "${HOME}/.config"
fi

# Fix git config directory if it exists
if [ -d "${GIT_CONFIG_DIR}" ]; then
    # Check ownership first
    DIR_OWNER=$(stat -c '%U' "${GIT_CONFIG_DIR}" 2>/dev/null || stat -f '%Su' "${GIT_CONFIG_DIR}" 2>/dev/null || echo "unknown")
    if [ "${DIR_OWNER}" != "${CURRENT_USER}" ]; then
        echo_warning "Git config directory owned by ${DIR_OWNER}, fixing..."
        sudo chown -R "${CURRENT_USER}:${CURRENT_USER}" "${GIT_CONFIG_DIR}"
        chmod -R u+w "${GIT_CONFIG_DIR}"
        echo_success "Fixed git config directory ownership"
    elif [ ! -w "${GIT_CONFIG_DIR}" ]; then
        echo_warning "Git config directory not writable, fixing permissions..."
        chmod -R u+w "${GIT_CONFIG_DIR}"
        echo_success "Fixed git config directory permissions"
    fi
fi

# Fix git config file if it exists
if [ -f "${GIT_CONFIG_FILE}" ]; then
    # Check ownership first
    FILE_OWNER=$(stat -c '%U' "${GIT_CONFIG_FILE}" 2>/dev/null || stat -f '%Su' "${GIT_CONFIG_FILE}" 2>/dev/null || echo "unknown")
    if [ "${FILE_OWNER}" != "${CURRENT_USER}" ]; then
        echo_warning "Git config file owned by ${FILE_OWNER}, fixing..."
        sudo chown "${CURRENT_USER}:${CURRENT_USER}" "${GIT_CONFIG_FILE}"
        chmod u+w "${GIT_CONFIG_FILE}"
        echo_success "Fixed git config file ownership"
    elif [ ! -w "${GIT_CONFIG_FILE}" ]; then
        echo_warning "Git config file not writable, fixing permissions..."
        chmod u+w "${GIT_CONFIG_FILE}"
        echo_success "Fixed git config file permissions"
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

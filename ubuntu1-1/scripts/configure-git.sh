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

# Check if git config is already set
CURRENT_NAME=$(git config --global user.name 2>/dev/null || true)
CURRENT_EMAIL=$(git config --global user.email 2>/dev/null || true)

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

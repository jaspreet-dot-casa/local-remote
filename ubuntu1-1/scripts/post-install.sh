#!/bin/bash
set -e
set -u

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo_success() { echo -e "${GREEN}✓${NC} $1"; }
echo_info() { echo -e "${YELLOW}➜${NC} $1"; }

# Find zsh installed by Home Manager
ZSH_PATH="${HOME}/.nix-profile/bin/zsh"

if [ ! -f "${ZSH_PATH}" ]; then
    echo "Error: zsh not found at ${ZSH_PATH}"
    echo "Please run 'make install' first"
    exit 1
fi

# Add zsh to valid shells if not present
if ! grep -q "${ZSH_PATH}" /etc/shells; then
    echo_info "Adding ${ZSH_PATH} to /etc/shells..."
    echo "${ZSH_PATH}" | sudo tee -a /etc/shells
fi

# Change default shell
if [ "${SHELL}" != "${ZSH_PATH}" ]; then
    echo_info "Changing default shell to zsh..."
    chsh -s "${ZSH_PATH}"
    echo_success "Default shell changed to zsh"
else
    echo_success "Default shell is already zsh"
fi

echo ""
echo "════════════════════════════════════════════"
echo_success "Shell configuration complete!"
echo "════════════════════════════════════════════"
echo ""
echo "Please log out and back in for changes to take effect:"
echo "  • Docker group membership"
echo "  • Zsh as default shell"
echo "  • All environment variables"
echo ""

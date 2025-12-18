#!/bin/bash
set -e  # Exit on error
set -u  # Exit on undefined variable

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_success() { echo -e "${GREEN}✓${NC} $1"; }
echo_error() { echo -e "${RED}✗${NC} $1"; }
echo_info() { echo -e "${YELLOW}➜${NC} $1"; }

echo "════════════════════════════════════════════"
echo "  Remote Ubuntu Server Setup with Nix"
echo "════════════════════════════════════════════"
echo ""

# 1. Check prerequisites
echo_info "Checking prerequisites..."

# Check if running on Ubuntu
if [ ! -f /etc/os-release ]; then
    echo_error "Cannot detect OS. This script is for Ubuntu."
    exit 1
fi

# shellcheck disable=SC1091 source=/etc/os-release
. /etc/os-release
# shellcheck disable=SC2154
if [ "${ID}" != "ubuntu" ]; then
    # shellcheck disable=SC2154
    echo_error "This script is designed for Ubuntu. Detected: ${ID}"
    exit 1
fi
# shellcheck disable=SC2154
echo_success "Running on Ubuntu ${VERSION_ID}"

# Check sudo access
if ! sudo -v; then
    echo_error "This script requires sudo access"
    exit 1
fi
echo_success "Sudo access confirmed"

# Check curl is installed
if ! command -v curl &> /dev/null; then
    echo_info "Installing curl..."
    sudo apt-get update
    sudo apt-get install -y curl
fi
echo_success "curl is available"

# 2. Install Nix if not already installed
echo ""
echo_info "Checking Nix installation..."
if command -v nix &> /dev/null; then
    echo_success "Nix already installed, skipping..."
else
    # Security Note: This command pipes curl output directly to sh for installation.
    # HTTPS/TLS provides protection against MITM attacks for the official nixos.org source.
    # The --proto '=https' --tlsv1.2 flags enforce HTTPS and minimum TLS 1.2.
    # For additional security, you can manually download, inspect, and run the installer.
    echo_info "Installing Nix (multi-user)..."
    sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon --yes
    echo_success "Nix installed successfully"
fi

# Source Nix for current session
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
    # shellcheck source=/dev/null
    . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi

# Start Nix daemon if not running (for containers without systemd)
if ! pgrep -x nix-daemon > /dev/null; then
    if [ ! -d /run/systemd/system ]; then
        echo_info "Starting Nix daemon (no systemd detected)..."
        sudo /nix/var/nix/profiles/default/bin/nix-daemon &
        # Wait a moment for daemon to start
        sleep 2
        echo_success "Nix daemon started"
    fi
fi

# 3. Enable Nix flakes
echo ""
echo_info "Enabling Nix flakes..."
mkdir -p ~/.config/nix
if grep -q "experimental-features" ~/.config/nix/nix.conf 2>/dev/null; then
    echo_success "Flakes already enabled"
else
    cat >> ~/.config/nix/nix.conf << EOF
experimental-features = nix-command flakes
EOF
    echo_success "Flakes enabled"
fi

# 4. Install Docker via official repository
echo ""
echo_info "Checking Docker installation..."
if command -v docker &> /dev/null; then
    echo_success "Docker already installed, skipping..."
else
    echo_info "Installing Docker (official repository)..."
    
    # Remove old versions
    sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Setup repository
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Add repository
    # shellcheck disable=SC1091,SC2154
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker Engine
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    echo_success "Docker installed successfully"
fi

# 5. Add user to docker group
echo ""
echo_info "Configuring Docker permissions..."
CURRENT_USER="${USER:-$(whoami)}"
if groups "${CURRENT_USER}" | grep -q docker; then
    echo_success "User already in docker group"
else
    sudo usermod -aG docker "${CURRENT_USER}"
    echo_success "User added to docker group"
fi

# 6. Install Home Manager
echo ""
echo_info "Checking Home Manager installation..."
if command -v home-manager &> /dev/null; then
    echo_success "Home Manager already installed"
else
    echo_info "Installing Home Manager..."
    # Detect architecture and user for flake configuration
    ARCH=$(uname -m)
    CURRENT_USER="${USER:-$(whoami)}"
    
    # Select appropriate configuration based on architecture and user
    if [ "${CURRENT_USER}" = "testuser" ]; then
        # Docker test environment
        if [ "${ARCH}" = "aarch64" ]; then
            FLAKE_CONFIG="testuser"
        else
            FLAKE_CONFIG="testuser-x86"
        fi
    else
        # Production/normal environment
        if [ "${ARCH}" = "aarch64" ]; then
            FLAKE_CONFIG="ubuntu-aarch64"
        else
            FLAKE_CONFIG="ubuntu"
        fi
    fi
    
    echo_info "Detected: arch=${ARCH}, user=${CURRENT_USER}, using config=${FLAKE_CONFIG}"
    nix run home-manager/release-24.05 -- switch --flake ./home-manager#${FLAKE_CONFIG}
    echo_success "Home Manager installed successfully"
fi

# 7. Configure Git
echo ""
echo_info "Configuring Git..."

# Check if git config is already set
CURRENT_NAME=$(git config --global user.name 2>/dev/null || true)
CURRENT_EMAIL=$(git config --global user.email 2>/dev/null || true)

# Detect CI environment (GitHub Actions, GitLab CI, Jenkins, etc.)
if [ -n "${CI:-}" ] || [ -n "${GITHUB_ACTIONS:-}" ] || [ -n "${GITLAB_CI:-}" ]; then
    echo_info "CI environment detected, skipping interactive Git configuration"
    if [ -n "${CURRENT_NAME}" ] && [ -n "${CURRENT_EMAIL}" ]; then
        echo_success "Git already configured: ${CURRENT_NAME} <${CURRENT_EMAIL}>"
    else
        echo_info "Git not configured. Configure it before running 'make install'"
        echo_info "Run: git config --global user.name 'Your Name'"
        echo_info "Run: git config --global user.email 'your@email.com'"
    fi
else
    # Interactive mode for local usage
    if [ -n "${CURRENT_NAME}" ] && [ -n "${CURRENT_EMAIL}" ]; then
        echo_success "Git already configured:"
        echo "  Name:  ${CURRENT_NAME}"
        echo "  Email: ${CURRENT_EMAIL}"
        echo ""
        read -p "Do you want to reconfigure? (y/N): " -r RECONFIGURE
        if [[ ! ${RECONFIGURE} =~ ^[Yy]$ ]]; then
            echo_info "Keeping existing git configuration"
        else
            CURRENT_NAME=""
            CURRENT_EMAIL=""
        fi
    fi

    if [ -z "${CURRENT_NAME}" ] || [ -z "${CURRENT_EMAIL}" ]; then
        echo ""
        echo "Please enter your Git configuration:"
        read -p "Git Name (e.g., John Doe): " -r GIT_NAME
        read -p "Git Email (e.g., john@example.com): " -r GIT_EMAIL
        
        if [ -n "${GIT_NAME}" ] && [ -n "${GIT_EMAIL}" ]; then
            git config --global user.name "${GIT_NAME}"
            git config --global user.email "${GIT_EMAIL}"
            echo_success "Git configured: ${GIT_NAME} <${GIT_EMAIL}>"
        else
            echo_info "Git configuration skipped (you can configure it later with 'make install')"
        fi
    fi
fi

# Done!
echo ""
echo "════════════════════════════════════════════"
echo_success "Setup completed successfully!"
echo "════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "  1. Run: make install    (installs zsh, oh-my-zsh, all packages)"
echo "  2. Run: make zsh        (changes default shell to zsh)"
echo "  3. Log out and back in  (for docker group + shell change)"
echo "  4. Run: make verify     (verify everything works)"
echo ""

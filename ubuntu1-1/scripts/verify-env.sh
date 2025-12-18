#!/usr/bin/env bash
set -e
set -u

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo_success() { echo -e "${GREEN}✓${NC} $1"; }
echo_error() { echo -e "${RED}✗${NC} $1"; }
echo_info() { echo -e "${YELLOW}➜${NC} $1"; }
echo_header() { echo -e "\n${BLUE}=== $1 ===${NC}"; }

ERRORS=0

check_command() {
    local cmd=$1
    local expected_path=$2
    local actual_path
    
    if command -v "${cmd}" &> /dev/null; then
        actual_path=$(which "${cmd}")
        if [[ -n "${expected_path}" && "${actual_path}" != *"${expected_path}"* ]]; then
            echo_error "${cmd} found at ${actual_path} (expected in ${expected_path})"
            ((ERRORS++))
        else
            echo_success "${cmd}: ${actual_path}"
        fi
    else
        echo_error "${cmd} not found"
        ((ERRORS++))
    fi
}

echo "════════════════════════════════════════════"
echo "  Environment Verification"
echo "════════════════════════════════════════════"

# 1. Check Nix installation
echo_header "Nix Installation"
check_command "nix" "/nix"

if nix --version &> /dev/null; then
    echo_success "Nix version: $(nix --version)"
else
    echo_error "Cannot run nix --version"
    ((ERRORS++))
fi

# 2. Check Home Manager
echo_header "Home Manager"
check_command "home-manager" ".nix-profile"

# 3. Check PATH priority (Nix should come before /usr/bin)
echo_header "PATH Priority"
if [[ "${PATH}" == *".nix-profile/bin"* ]]; then
    echo_success "Nix profile in PATH"
    
    # Check if Nix comes before /usr/bin
    nix_pos=$(echo "${PATH}" | grep -bo ".nix-profile/bin" | cut -d: -f1)
    usr_pos=$(echo "${PATH}" | grep -bo "/usr/bin" | cut -d: -f1)
    
    if [[ ${nix_pos} -lt ${usr_pos} ]]; then
        echo_success "Nix paths have priority over system paths"
    else
        echo_error "System paths come before Nix paths (priority issue)"
        ((ERRORS++))
    fi
else
    echo_error "Nix profile not in PATH"
    ((ERRORS++))
fi

# 4. Check shell
echo_header "Shell Configuration"
if [[ "${SHELL}" == *"zsh"* ]]; then
    echo_success "Default shell: ${SHELL}"
else
    echo_error "Default shell is not zsh: ${SHELL}"
    ((ERRORS++))
fi

if [[ -n "${ZSH}" ]]; then
    echo_success "Oh-My-Zsh detected: ${ZSH}"
else
    echo_error "Oh-My-Zsh not detected"
    ((ERRORS++))
fi

# 5. Check core tools (should be from Nix)
echo_header "Core Tools (Nix-managed)"
check_command "git" ".nix-profile"
check_command "gh" ".nix-profile"
check_command "lazygit" ".nix-profile"
check_command "nvim" ".nix-profile"
check_command "tmux" ".nix-profile"
check_command "zellij" ".nix-profile"
check_command "tree" ".nix-profile"
check_command "fzf" ".nix-profile"
check_command "zoxide" ".nix-profile"
check_command "rg" ".nix-profile"
check_command "fd" ".nix-profile"
check_command "bat" ".nix-profile"
check_command "jq" ".nix-profile"
check_command "btop" ".nix-profile"
check_command "nmap" ".nix-profile"
check_command "delta" ".nix-profile"
check_command "starship" ".nix-profile"

# 6. Check Docker
echo_header "Docker"
check_command "docker" ""
check_command "lazydocker" ".nix-profile"

if docker --version &> /dev/null; then
    echo_success "Docker version: $(docker --version)"
else
    echo_error "Cannot run docker --version"
    ((ERRORS++))
fi

# Check docker group
if groups | grep -q docker; then
    echo_success "User is in docker group"
else
    echo_error "User NOT in docker group (log out/in required)"
    ((ERRORS++))
fi

# Check docker daemon
if docker ps &> /dev/null 2>&1; then
    echo_success "Docker daemon is running"
else
    echo_error "Cannot connect to Docker daemon (may need to log out/in)"
    ((ERRORS++))
fi

# 7. Check environment variables
echo_header "Environment Variables"

if [[ -n "${NIX_PROFILES}" ]]; then
    echo_success "NIX_PROFILES is set"
else
    echo_error "NIX_PROFILES not set"
    ((ERRORS++))
fi

if [[ -n "${HOME}" ]]; then
    echo_success "HOME: ${HOME}"
else
    echo_error "HOME not set"
    ((ERRORS++))
fi

# 8. Check zsh integrations
echo_header "Zsh Integrations"

if command -v zoxide &> /dev/null && zoxide --version &> /dev/null; then
    echo_success "Zoxide integration working"
else
    echo_error "Zoxide not working properly"
    ((ERRORS++))
fi

if command -v starship &> /dev/null && starship --version &> /dev/null; then
    echo_success "Starship integration working"
else
    echo_error "Starship not working properly"
    ((ERRORS++))
fi

# 9. Check git configuration
echo_header "Git Configuration"

if git config --get core.pager | grep -q delta; then
    echo_success "Git pager set to delta"
else
    echo_error "Git pager not set to delta"
    ((ERRORS++))
fi

if git config --get init.defaultBranch | grep -q main; then
    echo_success "Git default branch: main"
else
    echo_error "Git default branch not set to main"
    ((ERRORS++))
fi

# 10. Check Git configuration
echo_header "Git Configuration"

GIT_NAME=$(git config --global user.name 2>/dev/null || true)
GIT_EMAIL=$(git config --global user.email 2>/dev/null || true)

if [ -n "${GIT_NAME}" ] && [ -n "${GIT_EMAIL}" ]; then
    echo_success "Git user.name: ${GIT_NAME}"
    echo_success "Git user.email: ${GIT_EMAIL}"
else
    echo_warning "Git user not configured"
    echo_info "Run scripts/configure-git.sh or 'make install' to configure git"
    if [ -z "${GIT_NAME}" ]; then
        echo_error "Git user.name not set"
        ((ERROR_COUNT++))
    fi
    if [ -z "${GIT_EMAIL}" ]; then
        echo_error "Git user.email not set"
        ((ERROR_COUNT++))
    fi
fi

# Summary
echo ""
echo "════════════════════════════════════════════"
if [[ ${ERRORS} -eq 0 ]]; then
    echo_success "All checks passed! Environment is properly configured."
    echo "════════════════════════════════════════════"
    exit 0
else
    echo_error "Found ${ERRORS} issue(s). Please review the errors above."
    echo "════════════════════════════════════════════"
    exit 1
fi

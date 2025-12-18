#!/bin/bash
set -e
set -u

echo "🐳 Running verification inside Docker container..."
echo ""

# Step 1: Run setup
echo "Step 1: Running setup..."
make setup

# Step 2: Configure Git for testing
echo ""
echo "Step 2: Configuring Git..."
git config --global user.name "Docker Test User"
git config --global user.email "docker-test@example.com"

# Step 3: Source Nix and run install
echo ""
echo "Step 3: Installing packages via Home Manager..."
# shellcheck source=/dev/null
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
make install

# Step 4: Verify tools are installed
echo ""
echo "Step 4: Verifying installed tools..."
export PATH=${HOME}/.nix-profile/bin:${PATH}

# Check a subset of critical tools
tools=(
    "git"
    "gh"
    "lazygit"
    "docker"
    "nvim"
    "tmux"
    "zellij"
    "fzf"
    "zoxide"
    "rg"
    "fd"
    "bat"
    "jq"
    "delta"
    "starship"
)

echo "Checking installed tools:"
for tool in "${tools[@]}"; do
    if command -v "${tool}" &> /dev/null; then
        version=$("${tool}" --version 2>&1 | head -1 || echo "version unknown")
        echo "  ✓ ${tool}: ${version}"
    else
        echo "  ✗ ${tool}: NOT FOUND"
        exit 1
    fi
done

# Step 5: Verify git configuration
echo ""
echo "Step 5: Verifying git configuration..."
git_name=$(git config --global user.name)
git_email=$(git config --global user.email)

if [ "${git_name}" = "Docker Test User" ] && [ "${git_email}" = "docker-test@example.com" ]; then
    echo "  ✓ Git configured correctly: ${git_name} <${git_email}>"
else
    echo "  ✗ Git configuration mismatch"
    echo "    Expected: Docker Test User <docker-test@example.com>"
    echo "    Got: ${git_name} <${git_email}>"
    exit 1
fi

# Step 6: Verify git delta integration
echo ""
echo "Step 6: Verifying git delta integration..."
pager=$(git config --global core.pager)
if [ "${pager}" = "delta" ]; then
    echo "  ✓ Git pager set to delta"
else
    echo "  ✗ Git pager not set to delta: ${pager}"
    exit 1
fi

# Step 7: Verify Nix environment
echo ""
echo "Step 7: Verifying Nix environment..."
nix --version
home-manager --version
echo "  ✓ Nix and Home Manager are working"

echo ""
echo "════════════════════════════════════════════"
echo "✅ All Docker tests passed successfully!"
echo "════════════════════════════════════════════"

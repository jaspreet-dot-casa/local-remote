#!/bin/bash
set -e
set -u

# Ensure USER is set (required in Docker containers)
export USER=${USER:-$(whoami)}

echo "🐳 Running verification inside Docker container..."
echo ""

# Step 1: Run setup
echo "Step 1: Running setup..."
make setup

# Step 2: Source Nix and run install
echo ""
echo "Step 2: Installing packages via Home Manager..."
# shellcheck source=/dev/null
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
make install

# Step 3: Verify tools are installed
echo ""
echo "Step 3: Verifying installed tools..."
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

# Step 4: Verify git configuration (managed by Home Manager)
echo ""
echo "Step 4: Verifying git configuration..."
git_name=$(git config --global user.name)
git_email=$(git config --global user.email)

# Git config is managed by Home Manager via user-config.nix
# Default values: Jaspreet Singh / 6873201+tagpro@users.noreply.github.com
if [ -n "${git_name}" ] && [ -n "${git_email}" ]; then
    echo "  ✓ Git configured: ${git_name} <${git_email}>"
else
    echo "  ✗ Git configuration missing"
    echo "    Got: name='${git_name}' email='${git_email}'"
    exit 1
fi

# Step 5: Verify git delta integration
echo ""
echo "Step 5: Verifying git delta integration..."
pager=$(git config --global core.pager)
if [ "${pager}" = "delta" ]; then
    echo "  ✓ Git pager set to delta"
else
    echo "  ✗ Git pager not set to delta: ${pager}"
    exit 1
fi

# Step 6: Verify Nix environment
echo ""
echo "Step 6: Verifying Nix environment..."
nix --version
home-manager --version
echo "  ✓ Nix and Home Manager are working"

echo ""
echo "════════════════════════════════════════════"
echo "✅ All Docker tests passed successfully!"
echo "════════════════════════════════════════════"

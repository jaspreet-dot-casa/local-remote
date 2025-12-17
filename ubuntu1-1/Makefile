.PHONY: setup install zsh verify help test-docker test-syntax shellcheck nix-check

help:
	@echo "Available targets:"
	@echo ""
	@echo "Setup & Installation:"
	@echo "  make setup         - First-time setup (Nix, Docker, Home Manager, .env)"
	@echo "  make install       - Install/update packages via Home Manager"
	@echo "  make zsh           - Change default shell to zsh (run after install)"
	@echo "  make verify        - Verify installation on current system"
	@echo ""
	@echo "Testing & Validation:"
	@echo "  make test-docker   - Run full integration test in Docker (requires Docker)"
	@echo "  make test-syntax   - Check bash/zsh syntax of all scripts"
	@echo "  make shellcheck    - Run shellcheck linter on all scripts (requires shellcheck)"
	@echo "  make nix-check     - Validate Nix flake configuration (requires Nix)"

setup:
	@echo "Running setup script..."
	@bash scripts/setup.sh

install:
	@echo "Installing packages via Home Manager..."
	@home-manager switch --flake ./home-manager#ubuntu
	@echo ""
	@echo "Configuring git from .env..."
	@bash scripts/configure-git.sh

zsh:
	@echo "Changing default shell to zsh..."
	@bash scripts/post-install.sh

verify:
	@echo "Verifying installation..."
	@zsh scripts/verify-env.sh

# Testing targets
test-docker:
	@echo "Running Docker-based integration test..."
	@bash scripts/test-docker.sh

test-syntax:
	@echo "Checking script syntax..."
	@echo "Checking bash scripts..."
	@bash -n scripts/setup.sh && echo "  ✓ setup.sh"
	@bash -n scripts/configure-git.sh && echo "  ✓ configure-git.sh"
	@bash -n scripts/post-install.sh && echo "  ✓ post-install.sh"
	@bash -n scripts/test-docker.sh && echo "  ✓ test-docker.sh"
	@bash -n scripts/test-in-docker.sh && echo "  ✓ test-in-docker.sh"
	@echo "Checking zsh scripts..."
	@zsh -n scripts/verify-env.sh && echo "  ✓ verify-env.sh"
	@echo ""
	@echo "✓ All scripts have valid syntax"

shellcheck:
	@echo "Running shellcheck on all scripts..."
	@if ! command -v shellcheck &> /dev/null; then \
		echo "Error: shellcheck is not installed"; \
		echo "Install with: brew install shellcheck (macOS) or apt-get install shellcheck (Ubuntu)"; \
		exit 1; \
	fi
	@shellcheck scripts/*.sh
	@echo "✓ All scripts passed shellcheck"

nix-check:
	@echo "Checking Nix flake configuration..."
	@if ! command -v nix &> /dev/null; then \
		echo "Error: nix is not installed"; \
		echo "This check requires Nix to be installed"; \
		exit 1; \
	fi
	@cd home-manager && nix flake check
	@echo "✓ Nix flake configuration is valid"

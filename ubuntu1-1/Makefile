.PHONY: gen-user-config setup install install-nix-pkgs post-install zsh verify help test-docker test-syntax shellcheck nix-check

# Get the directory where this Makefile resides
ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# Generate user-specific Nix configuration
gen-user-config:
	@bash $(ROOT)scripts/generate-user-config.sh > /dev/null

help:
	@echo "Available targets:"
	@echo ""
	@echo "Setup & Installation:"
	@echo "  make gen-user-config   - Generate user-specific Nix configuration"
	@echo "  make setup             - First-time setup (Nix, Docker, Home Manager, Git config)"
	@echo "  make install           - Full installation (packages + post-install) - MAIN TARGET"
	@echo "  make install-nix-pkgs  - Install/update packages via Home Manager only"
	@echo "  make post-install      - Run post-install configuration only (shell, Tailscale)"
	@echo "  make zsh               - Alias for post-install (backward compatibility)"
	@echo "  make verify            - Verify installation on current system"
	@echo ""
	@echo "Testing & Validation:"
	@echo "  make test-docker   - Run full integration test in Docker (requires Docker)"
	@echo "  make test-syntax   - Check bash/zsh syntax of all scripts"
	@echo "  make shellcheck    - Run shellcheck linter on all scripts (requires shellcheck)"
	@echo "  make nix-check     - Validate Nix flake configuration (requires Nix)"

setup:
	@echo "Running setup script..."
	@bash $(ROOT)scripts/setup.sh

# Install Nix packages only (no system changes)
install-nix-pkgs: gen-user-config
	@echo "Installing packages via Home Manager..."
	@FLAKE_CONFIG=$$(bash $(ROOT)scripts/generate-user-config.sh); \
	ARCH=$$(uname -m); \
	CURRENT_USER=$${USER:-$$(whoami)}; \
	echo "Detected: arch=$$ARCH, user=$$CURRENT_USER, config=$$FLAKE_CONFIG"; \
	home-manager switch --flake $(ROOT)home-manager#$$FLAKE_CONFIG

# Run post-install configuration (system-level setup)
post-install:
	@echo "Running post-install configuration..."
	@bash $(ROOT)scripts/post-install.sh $(ARGS)

# Full installation: packages + post-install (MAIN TARGET)
install: install-nix-pkgs post-install
	@echo ""
	@echo "✓ Full installation complete"

# Backward compatibility
zsh: post-install

verify:
	@echo "Verifying installation..."
	@bash $(ROOT)scripts/verify-env.sh

# Testing targets
test-docker:
	@echo "Running Docker-based integration test..."
	@bash $(ROOT)scripts/test-docker.sh

test-syntax:
	@echo "Checking script syntax..."
	@echo "Checking bash scripts..."
	@bash -n $(ROOT)scripts/setup.sh && echo "  ✓ setup.sh"
	@bash -n $(ROOT)scripts/generate-user-config.sh && echo "  ✓ generate-user-config.sh"
	@bash -n $(ROOT)scripts/post-install.sh && echo "  ✓ post-install.sh"
	@bash -n $(ROOT)scripts/test-docker.sh && echo "  ✓ test-docker.sh"
	@bash -n $(ROOT)scripts/test-in-docker.sh && echo "  ✓ test-in-docker.sh"
	@bash -n $(ROOT)scripts/verify-env.sh && echo "  ✓ verify-env.sh"
	@bash -n $(ROOT)home-manager/scripts/tailscale/post-install.sh && echo "  ✓ tailscale/post-install.sh"
	@echo ""
	@echo "✓ All scripts have valid syntax"

shellcheck:
	@echo "Running shellcheck on all scripts..."
	@shellcheck $(ROOT)scripts/*.sh && echo "✓ All scripts passed shellcheck" || \
		(echo "Error: shellcheck failed or is not installed"; \
		 echo "Install with: brew install shellcheck (macOS) or apt-get install shellcheck (Ubuntu)"; \
		 exit 1)

nix-check: gen-user-config
	@echo "Checking Nix flake configuration..."
	@cd $(ROOT)home-manager && nix --extra-experimental-features 'nix-command flakes' flake check && \
		echo "✓ Nix flake configuration is valid" || \
		(echo "Error: nix flake check failed or nix is not installed"; \
		 echo "This check requires Nix to be installed"; \
		 exit 1)

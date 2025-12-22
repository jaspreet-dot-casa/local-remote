.PHONY: gen-user-config setup install install-nix-pkgs post-install zsh verify help test-docker test-syntax shellcheck nix-check update update-dry verify-cloud test-multipass test-multipass-keep test-multipass-clean

# Get the directory where this Makefile resides
ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# Generate user-specific Nix configuration
gen-user-config:
	@bash $(ROOT)scripts/generate-user-config.sh > /dev/null

help:
	@echo "Available targets:"
	@echo ""
	@echo "Setup & Installation (Nix-based):"
	@echo "  make gen-user-config   - Generate user-specific Nix configuration"
	@echo "  make setup             - First-time setup (Nix, Docker, Home Manager, Git config)"
	@echo "  make install           - Full installation (packages + post-install) - MAIN TARGET"
	@echo "  make install-nix-pkgs  - Install/update packages via Home Manager only"
	@echo "  make post-install      - Run post-install configuration only (shell, Tailscale)"
	@echo "  make zsh               - Alias for post-install (backward compatibility)"
	@echo "  make verify            - Verify installation on current system"
	@echo ""
	@echo "Cloud-Init (alternative to Nix):"
	@echo "  make update            - Update all packages idempotently (cloud-init systems)"
	@echo "  make update-dry        - Preview changes without applying (dry-run mode)"
	@echo "  make verify-cloud      - Verify cloud-init installation"
	@echo ""
	@echo "Testing & Validation:"
	@echo "  make test-docker         - Run full integration test in Docker (requires Docker)"
	@echo "  make test-multipass      - Run cloud-init test in Multipass VM (requires Multipass)"
	@echo "  make test-multipass-keep - Run test but keep VM for debugging"
	@echo "  make test-multipass-clean- Clean up leftover test VMs"
	@echo "  make test-syntax         - Check bash/zsh syntax of all scripts"
	@echo "  make shellcheck          - Run shellcheck linter on all scripts (requires shellcheck)"
	@echo "  make nix-check           - Validate Nix flake configuration (requires Nix)"

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
	@echo "Checking shared scripts..."
	@for f in $(ROOT)scripts/shared/*.sh; do bash -n "$$f" && echo "  ✓ shared/$$(basename $$f)"; done
	@echo "Checking library scripts..."
	@for f in $(ROOT)scripts/lib/*.sh; do bash -n "$$f" && echo "  ✓ lib/$$(basename $$f)"; done
	@echo "Checking package scripts..."
	@for f in $(ROOT)scripts/packages/*.sh; do bash -n "$$f" && echo "  ✓ packages/$$(basename $$f)"; done
	@echo "Checking cloud-init scripts..."
	@for f in $(ROOT)scripts/cloud-init/*.sh; do bash -n "$$f" && echo "  ✓ cloud-init/$$(basename $$f)"; done
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

# ============================================================================
# Cloud-Init Targets (alternative to Nix-based installation)
# ============================================================================

# Update all packages idempotently (for cloud-init systems)
update:
	@if [ -f $(ROOT)scripts/cloud-init/update-all.sh ]; then \
		bash $(ROOT)scripts/cloud-init/update-all.sh; \
	else \
		echo "Cloud-init scripts not yet implemented"; \
		echo "Run 'make install' for Nix-based installation"; \
	fi

# Dry-run mode - preview changes without applying
update-dry:
	@if [ -f $(ROOT)scripts/cloud-init/update-all.sh ]; then \
		DRY_RUN=true bash $(ROOT)scripts/cloud-init/update-all.sh; \
	else \
		echo "Cloud-init scripts not yet implemented"; \
	fi

# Verify cloud-init installation
verify-cloud:
	@if [ -f $(ROOT)scripts/cloud-init/update-all.sh ]; then \
		bash $(ROOT)scripts/cloud-init/update-all.sh --verify-only; \
	else \
		echo "Cloud-init scripts not yet implemented"; \
	fi

# ============================================================================
# Multipass VM Testing
# ============================================================================

# Run full cloud-init test in Multipass VM
test-multipass:
	@echo "Running cloud-init integration test in Multipass VM..."
	@bash $(ROOT)tests/multipass/run-test.sh

# Run test but keep VM for debugging
test-multipass-keep:
	@echo "Running cloud-init test (keeping VM for debugging)..."
	@bash $(ROOT)tests/multipass/run-test.sh --keep

# Clean up any leftover test VMs
test-multipass-clean:
	@echo "Cleaning up test VMs..."
	@multipass list --format csv 2>/dev/null | grep cloud-init-test | cut -d',' -f1 | xargs -I {} multipass delete {} 2>/dev/null || true
	@multipass purge 2>/dev/null || true
	@echo "Cleanup complete"

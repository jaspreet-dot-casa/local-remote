# Remote Ubuntu Server Configuration

Declarative configuration for remote Ubuntu server using Nix and Home Manager.

## Features

- 🎯 **Fully declarative** - All packages and configurations in version control
- 🔄 **Reproducible** - Same setup on any Ubuntu machine
- 📦 **Nix-managed packages** - git, gh, lazygit, docker tools, zellij, tmux, neovim, and more
- 🐚 **Modern shell** - Zsh + Oh-My-Zsh + Starship prompt
- 🛠️ **Developer tools** - ripgrep, fd, bat, fzf, zoxide, delta, btop, and more
- 🔐 **Tailscale VPN + SSH** - Secure remote access with built-in 2FA and exit node support

## Prerequisites

- Ubuntu 22.04 or 24.04 (remote server) - **24.04 recommended**
- Sudo access
- SSH access configured

## Initial Setup

### 1. Install git (temporary, will be replaced by Nix version)

```bash
sudo apt update
sudo apt install -y git
```

### 2. Clone this repository

```bash
git clone <your-repo-url> ~/ubuntu1-1
cd ~/ubuntu1-1
```

### 3. Run setup (first time only)

This installs Nix, Docker, and Home Manager:

```bash
make setup
```

Git configuration is managed declaratively via Home Manager (see "Git configuration customization" below).

### 4. Install packages and configure system

This installs all tools via Home Manager and runs post-install configuration (shell + Tailscale):

```bash
make install
```

This will:
- Install all Nix packages (git, docker tools, zsh, neovim, etc.)
- Configure zsh as default shell
- Set up Tailscale VPN and SSH (interactive)

**Automation flag:** To skip confirmation prompts (useful for automation):
```bash
make install  # Will prompt for Tailscale auth
# OR
make post-install ARGS="-y"  # Skip confirmations (after packages installed)
```

### 5. Log out and back in

For docker group and shell changes to take effect:

```bash
exit
# SSH back in
```

### 6. Configure Tailscale (post-installation)

After installation, configure Tailscale in the admin console:

1. **Enable SSH access** (required for Tailscale SSH):
   - Go to https://login.tailscale.com/admin/acls
   - Add SSH ACL rules (see "Tailscale SSH Configuration" section below)

2. **Enable exit node** (optional):
   - Go to https://login.tailscale.com/admin/machines
   - Click your machine → Edit route settings
   - Enable "Use as exit node"

See the "Network Services - Tailscale" section below for detailed configuration.

### 7. Verify installation

```bash
make verify
```

You should see all green checkmarks ✓

## Daily Usage

### Updating Packages

1. Edit `home-manager/home.nix` to add/remove packages or change configurations
2. Commit changes: `git commit -am "Add new package"`
3. Push: `git push`
4. On remote server:
   ```bash
   git pull
   make install
   ```

### Adding a New Package

Edit `home-manager/home.nix`:

```nix
home.packages = with pkgs; [
  # ... existing packages
  htop  # Add new package
];
```

Then run:

```bash
make install
```

### Customizing Zsh

For machine-specific customizations, create `~/.zshrc.local`:

```bash
# Machine-specific aliases, functions, etc.
export CUSTOM_VAR="value"
alias myalias="command"
```

This file is sourced automatically and not managed by Home Manager.

### Customizing Configurations

- **Git**: Edit `home-manager/home.nix` → `programs.git`
- **Zsh**: Edit `home-manager/home.nix` → `programs.zsh`
- **Tmux**: Edit `home-manager/home.nix` → `programs.tmux`
- **Neovim**: Edit `home-manager/home.nix` → `programs.neovim`
- **Zellij**: Edit `home-manager/home.nix` → `xdg.configFile."zellij/config.kdl"`
- **Tailscale**: Edit `home-manager/config/tailscale.conf`

After editing, run:
- `make install` for package/config changes
- `make post-install` for Tailscale configuration changes

### Machine-Specific Configuration

Home Manager uses a template-based approach for machine-specific configuration:

#### Files:

1. **`home-manager/user-config.nix.template`** (TRACKED in Git)
   - Template with placeholders like `@USERNAME@`, `@HOME_DIRECTORY@`
   - This file is committed to version control
   - Edit this file to add new configuration options

2. **`home-manager/user-config.nix`** (TRACKED with defaults, auto-generated)
   - Generated from template with real values
   - Contains your actual username, home directory, git config, and system info
   - Committed with default values (tagpro user, Jaspreet Singh git config)
   - Regenerated automatically before each `make install`

#### How it works:

1. Template contains placeholders: `@USERNAME@`, `@HOME_DIRECTORY@`, `@GIT_USER_NAME@`, `@GIT_USER_EMAIL@`
2. Script detects your system info (username, home dir, architecture, etc.)
3. Script uses git defaults or environment variables for git config
4. Script uses `sed` to replace placeholders with real values
5. Generated file is used by Home Manager (tracked but with real values)

#### Manual regeneration:

```bash
make gen-user-config
```

#### Why this approach?

- ✅ Same configuration works for any user (ubuntu, tagpro, etc.)
- ✅ Machine-specific values never committed to Git
- ✅ Template is tracked, making Nix flakes happy
- ✅ Clear separation between template and generated config

#### Important:

- **DO edit:** `user-config.nix.template` (to add new options)
- **DON'T edit:** `user-config.nix` (auto-generated, changes overwritten)
- **DON'T commit:** local changes to `user-config.nix` (contains your machine-specific values)


## Installed Tools

### Version Control
- **git** - Version control
- **gh** - GitHub CLI
- **lazygit** - Terminal UI for git
- **delta** - Better git diffs

### Docker
- **docker** - Container platform (daemon via apt)
- **docker-compose** - Multi-container orchestration
- **lazydocker** - Terminal UI for docker

### Terminal
- **zsh** - Modern shell
- **oh-my-zsh** - Zsh framework
- **starship** - Cross-shell prompt
- **zellij** - Terminal multiplexer
- **tmux** - Terminal multiplexer

### Editor
- **neovim** - Modern vim

### CLI Utilities
- **fzf** - Fuzzy finder
- **zoxide** - Smarter cd
- **ripgrep (rg)** - Fast grep alternative
- **fd** - Fast find alternative
- **bat** - Cat with syntax highlighting
- **tree** - Directory tree view
- **jq** - JSON processor
- **btop** - System monitor
- **nmap** - Network scanner
- **dig/nslookup** - DNS utilities
- **htpasswd** - Password file utility

### Network & Remote Access
- **tailscale** - VPN mesh network with SSH support and exit node capability

## Network Services

### Tailscale VPN + SSH

This setup includes **Tailscale SSH only** - no traditional OpenSSH server is installed or configured.

#### Features

- ✅ **Tailscale SSH with built-in 2FA** - Uses identity provider MFA via "check mode"
- ✅ **Exit node advertising** - Route traffic through this server
- ✅ **No SSH key management** - WireGuard authentication
- ✅ **Centralized access control** - Manage via Tailscale ACLs
- ✅ **Automatic setup** - Post-install script handles everything
- ✅ **Declarative configuration** - Settings in `home-manager/config/tailscale.conf`

#### Quick Start

Tailscale is automatically set up during `make install`. To reconfigure:

```bash
make post-install  # Interactive
make post-install ARGS="-y"  # Non-interactive
```

#### Configuration

Edit `home-manager/config/tailscale.conf`:

```bash
# Enable Tailscale SSH (replaces traditional OpenSSH)
TAILSCALE_SSH_ENABLED=true

# Advertise as exit node
TAILSCALE_ADVERTISE_EXIT_NODE=true

# SSH Check Mode (2FA via identity provider)
TAILSCALE_SSH_CHECK_MODE=true

# Check period for re-authentication
TAILSCALE_SSH_CHECK_PERIOD="12h"

# Additional flags (space-separated)
TAILSCALE_ADDITIONAL_FLAGS=""
```

After editing, run:
```bash
make post-install
```

#### Tailscale SSH Configuration

**Tailscale SSH requires ACL configuration in the admin console.**

1. Go to https://login.tailscale.com/admin/acls

2. Add SSH rules to your ACL policy:

```json
{
  "ssh": [
    {
      "action": "check",
      "src": ["autogroup:member"],
      "dst": ["autogroup:self"],
      "users": ["autogroup:nonroot", "root"],
      "checkPeriod": "12h"
    }
  ]
}
```

**What this does:**
- `"action": "check"` - Enables 2FA via identity provider
- `"src": ["autogroup:member"]` - All Tailscale users
- `"dst": ["autogroup:self"]` - Can SSH to their own devices
- `"users": ["autogroup:nonroot", "root"]` - Can become any non-root user or root
- `"checkPeriod": "12h"` - Re-authenticate every 12 hours

3. Save the ACL policy

4. SSH to your server from another Tailscale device:

```bash
# From another machine on your Tailscale network
ssh username@machine-name
# Or using Tailscale IP
ssh username@100.x.y.z
```

**Benefits of check mode (2FA):**
- Requires MFA via your identity provider (Google, GitHub, etc.)
- Configurable check period (5m, 1h, 12h, always)
- No additional TOTP apps needed
- Centrally managed, easy to revoke access

#### Exit Node Setup

Your server advertises as an exit node but needs approval.

1. Go to https://login.tailscale.com/admin/machines

2. Find your machine in the list

3. Click on the machine → **Edit route settings**

4. Enable **"Use as exit node"**

5. From another Tailscale device, route traffic through this server:

```bash
tailscale up --exit-node=machine-name
# Or using Tailscale IP
tailscale up --exit-node=100.x.y.z
```

6. Verify exit node is active:

```bash
tailscale status
curl ifconfig.me  # Should show your server's public IP
```

#### Useful Commands

```bash
# Check Tailscale status
tailscale status

# Show Tailscale IPs
tailscale ip

# Ping another Tailscale machine
tailscale ping machine-name

# SSH to another Tailscale machine
ssh username@machine-name

# Enable exit node on client
tailscale up --exit-node=server-name

# Disable exit node on client
tailscale up --exit-node=
```

#### Why Tailscale SSH Only?

**Advantages:**
- ✅ Built-in 2FA via check mode
- ✅ No SSH key management
- ✅ Centralized access control (Tailscale ACLs)
- ✅ WireGuard encryption + SSH protocol
- ✅ Automatic key rotation
- ✅ Session recording available
- ✅ Simpler architecture (one SSH solution)

**Trade-offs:**
- ⚠️ Only works from Tailscale network
- ⚠️ Requires Tailscale ACL configuration

**Important:** If you need traditional SSH access, you'll need to install and configure `openssh-server` separately. This setup intentionally does not include it.

## Template Placeholders

When editing `home-manager/user-config.nix.template`, you can use these placeholders:

| Placeholder | Replaced With | Example |
|-------------|---------------|---------|
| `@USERNAME@` | Current username | `tagpro` |
| `@HOME_DIRECTORY@` | Home directory path | `/home/tagpro` |
| `@GIT_USER_NAME@` | Git user name | `Jaspreet Singh` |
| `@GIT_USER_EMAIL@` | Git user email | `6873201+tagpro@users.noreply.github.com` |
| `@HOSTNAME@` | Machine hostname | `ubuntu-server-01` |
| `@NIX_SYSTEM@` | Nix system identifier | `x86_64-linux` |
| `@ARCH@` | CPU architecture | `x86_64` |
| `@OS_INFO@` | OS pretty name | `Ubuntu 24.04 LTS` |
| `@KERNEL@` | Kernel version | `6.8.0-45-generic` |
| `@GENERATION_DATE@` | Generation timestamp | `2025-12-19 10:00:00 UTC` |

The generation script automatically replaces these when creating `user-config.nix`.

## Make Targets

### Setup & Installation
- `make help` - Show all available targets
- `make setup` - First-time setup (Nix, Docker, Home Manager)
- `make install` - **Full installation: packages + post-install (MAIN TARGET)**
- `make install-nix-pkgs` - Install/update packages via Home Manager only
- `make post-install` - Run post-install configuration (shell + Tailscale, supports `ARGS="-y"`)
- `make zsh` - Alias for post-install (backward compatibility)
- `make verify` - Verify installation on current system

### Testing & Validation
- `make test-docker` - Run full integration test in Docker (requires Docker)
- `make test-syntax` - Check bash/zsh syntax of all scripts
- `make shellcheck` - Run shellcheck linter on all scripts (requires shellcheck)
- `make nix-check` - Validate Nix flake configuration (requires Nix)

## Git Configuration

Git is configured declaratively through Home Manager via `user-config.nix`:

1. **Default values** are set in the committed `user-config.nix` file
2. **Machine-specific values** are generated from `user-config.nix.template`
3. **Override via environment variables** (optional):
   ```bash
   GIT_USER_NAME="Your Name" GIT_USER_EMAIL="you@example.com" make setup
   ```

The generation script uses these defaults if environment variables are not set:
- **Name:** Jaspreet Singh
- **Email:** 6873201+tagpro@users.noreply.github.com

Your Git configuration is managed by Home Manager in `~/.config/git/config` (symlink to Nix store).

**Important:** Because Home Manager creates read-only symlinks to the Nix store, you **cannot** use imperative commands like:
```bash
git config --global user.name "..."  # ❌ This will fail with "Permission denied"
```

Instead, configure Git by:
1. Setting environment variables before `make install` (temporary)
2. Editing `user-config.nix.template` (permanent)

This is the Nix/Home Manager way - declarative, reproducible, and version-controlled.

## Testing

### Local Testing with Docker

Test the entire setup in a clean Ubuntu 24.04 container without affecting your system:

```bash
make test-docker
```

This will:
- Build a Docker container with Ubuntu 24.04
- Run the complete setup workflow
- Verify all tools are installed correctly
- Takes 10-15 minutes on first run

### Syntax Validation

Check all scripts for syntax errors:

```bash
make test-syntax
```

### Linting with ShellCheck

Run shellcheck on all bash scripts (requires shellcheck to be installed):

```bash
make shellcheck
```

Install shellcheck:
- **macOS**: `brew install shellcheck`
- **Ubuntu**: `sudo apt-get install shellcheck`

### Nix Flake Validation

Validate the Nix flake configuration (requires Nix to be installed):

```bash
make nix-check
```

### Pre-commit Hook

The repository includes a pre-commit hook that automatically runs `nix flake check` when committing changes to `ubuntu1-1/` files.

**Setup** (one-time):
The pre-commit hook is already installed in `.git/hooks/pre-commit` and will run automatically on commits.

**Behavior:**
- Runs only when `ubuntu1-1/` files are being committed
- Requires Nix to be installed (skips with warning if not available)
- Validates the Nix flake configuration before allowing the commit
- Can be bypassed with: `git commit --no-verify` (not recommended)

**Benefits:**
- Catches Nix configuration errors before they reach CI
- Ensures all commits maintain valid Nix flake configuration
- Faster feedback loop for developers

### Continuous Integration

The repository includes a GitHub Actions workflow (located at `../.github/workflows/verify-ubuntu1-1.yml`) that automatically:
- Checks bash syntax on all scripts
- Runs shellcheck linting on all scripts

**Note:** Nix flake validation runs as a pre-commit hook locally, not in CI, for faster feedback.

**Full integration testing** (Docker-based setup, tool verification, and Nix/Home Manager tests) can be run locally using `make test-docker` but is not currently included in CI to reduce runtime and complexity. To add these to CI, you can:
1. Uncomment or add a `docker-integration-test` job to the workflow
2. Add steps to build the Docker test image and run the container
3. See `scripts/test-docker.sh` and `Dockerfile.test` for the local implementation

The workflow runs automatically on:
- Every push to `main` or `develop` branches that modifies files in `ubuntu1-1/`
- Every pull request that modifies files in `ubuntu1-1/`
- Manual trigger via GitHub Actions UI

The workflow uses `defaults.run.working-directory: ubuntu1-1` to run all commands in this directory.

## Troubleshooting

### "home-manager: command not found" after setup

Run:
```bash
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

Or log out and back in.

### Docker permission denied

Make sure you're in the docker group and have logged out/in:

```bash
groups  # Should show 'docker'
```

If not, run `make zsh` again and log out/in.

### Nix packages not taking priority over system packages

Check PATH:
```bash
echo $PATH  # Should have .nix-profile/bin before /usr/bin
```

Run `make verify` to diagnose.

### Changes not applying after `make install`

Try:
```bash
home-manager switch --flake ./home-manager#ubuntu --refresh
```

### Git configuration customization

Git is configured via Home Manager in `user-config.nix`. To customize:

**Option 1: Environment variables (one-time)**
```bash
GIT_USER_NAME="Your Name" GIT_USER_EMAIL="you@email.com" make install
```

**Option 2: Edit the template (permanent)**
```bash
# Edit user-config.nix.template to change defaults
vim home-manager/user-config.nix.template
# Then regenerate
make gen-user-config
make install
```

### Tailscale not authenticating

If Tailscale setup fails or you need to re-authenticate:

```bash
# Check daemon status
sudo systemctl status tailscaled

# Check logs
sudo journalctl -u tailscaled -n 50

# Re-run setup
make post-install

# Or manually authenticate
sudo tailscale up --ssh --advertise-exit-node
```

### Tailscale SSH not working

1. **Verify Tailscale connection:**
   ```bash
   tailscale status  # Should show connected
   ```

2. **Check ACLs are configured:**
   - Go to https://login.tailscale.com/admin/acls
   - Ensure SSH rules are present (see "Tailscale SSH Configuration" above)

3. **Verify SSH is enabled:**
   ```bash
   tailscale status | grep "SSH enabled"
   ```

4. **Try direct SSH:**
   ```bash
   # Get Tailscale IP
   tailscale ip -4
   
   # SSH from another Tailscale device
   ssh username@<tailscale-ip>
   ```

5. **Check Tailscale SSH logs:**
   ```bash
   sudo journalctl -u tailscaled | grep -i ssh
   ```

### Exit node not available

1. **Verify exit node is advertised:**
   ```bash
   tailscale status  # Look for "Exit node" line
   ```

2. **Enable in admin console:**
   - Go to https://login.tailscale.com/admin/machines
   - Click your machine
   - Edit route settings
   - Enable "Use as exit node"

3. **Re-advertise if needed:**
   ```bash
   sudo tailscale up --ssh --advertise-exit-node
   ```

## File Structure

```
ubuntu1-1/
├── home-manager/
│   ├── flake.nix                        # Nix flake configuration
│   ├── home.nix                         # Home Manager configuration
│   ├── config/
│   │   └── tailscale.conf              # Tailscale configuration
│   └── scripts/
│       └── tailscale/
│           └── post-install.sh         # Tailscale setup script
├── scripts/
│   ├── setup.sh                         # Setup script
│   ├── generate-user-config.sh          # Generate user config from template
│   ├── post-install.sh                  # Post-install orchestrator (shell + Tailscale)
│   ├── verify-env.sh                    # Verification script
│   ├── test-docker.sh                   # Docker test runner
│   └── test-in-docker.sh                # Container tests
├── .dockerignore                        # Docker build exclusions
├── .shellcheckrc                        # ShellCheck configuration
├── Dockerfile.test                      # Docker test container
├── Makefile                             # Automation targets
└── README.md                            # This file

GitHub Actions workflow (in parent repo):
../.github/workflows/verify-ubuntu1-1.yml
```

## Resources

- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Package Search](https://search.nixos.org/packages)
- [Home Manager Options](https://nix-community.github.io/home-manager/options.html)
- [Starship Configuration](https://starship.rs/config/)

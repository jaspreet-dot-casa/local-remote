# Remote Ubuntu Server Configuration

Declarative configuration for remote Ubuntu server using Nix and Home Manager.

## Features

- 🎯 **Fully declarative** - All packages and configurations in version control
- 🔄 **Reproducible** - Same setup on any Ubuntu machine
- 📦 **Nix-managed packages** - git, gh, lazygit, docker tools, zellij, tmux, neovim, and more
- 🐚 **Modern shell** - Zsh + Oh-My-Zsh + Starship prompt
- 🛠️ **Developer tools** - ripgrep, fd, bat, fzf, zoxide, delta, btop, and more

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

This installs Nix, Docker, Home Manager, and prompts for Git configuration:

```bash
make setup
```

During setup, you'll be prompted to configure your Git identity (name and email).

### 4. Install packages

This installs zsh, oh-my-zsh, and all tools via Home Manager. If Git wasn't configured during setup, you'll be prompted again:

```bash
make install
```

### 5. Change default shell

To use zsh:

```bash
make zsh
```

### 6. Log out and back in

For docker group and shell changes to take effect:

```bash
exit
# SSH back in
```

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

After editing, run `make install` to apply changes.

### Machine-Specific Configuration

Home Manager uses a template-based approach for machine-specific configuration:

#### Files:

1. **`home-manager/user-config.nix.template`** (TRACKED in Git)
   - Template with placeholders like `@USERNAME@`, `@HOME_DIRECTORY@`
   - This file is committed to version control
   - Edit this file to add new configuration options

2. **`home-manager/user-config.nix`** (GITIGNORED, auto-generated)
   - Generated from template with real values
   - Contains your actual username, home directory, and system info
   - Never committed (machine-specific)
   - Regenerated automatically before each `make install`

#### How it works:

1. Template contains placeholders: `@USERNAME@`, `@HOME_DIRECTORY@`
2. Script detects your system info (username, home dir, architecture, etc.)
3. Script uses `sed` to replace placeholders with real values
4. Generated file is used by Home Manager but never committed

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
- **DON'T commit:** `user-config.nix` (already gitignored)


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

## Template Placeholders

When editing `home-manager/user-config.nix.template`, you can use these placeholders:

| Placeholder | Replaced With | Example |
|-------------|---------------|---------|
| `@USERNAME@` | Current username | `tagpro` |
| `@HOME_DIRECTORY@` | Home directory path | `/home/tagpro` |
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
- `make install` - Install/update packages via Home Manager
- `make zsh` - Change default shell to zsh
- `make verify` - Verify installation on current system

### Testing & Validation
- `make test-docker` - Run full integration test in Docker (requires Docker)
- `make test-syntax` - Check bash/zsh syntax of all scripts
- `make shellcheck` - Run shellcheck linter on all scripts (requires shellcheck)
- `make nix-check` - Validate Nix flake configuration (requires Nix)

## Git Configuration

Git user name and email are configured interactively during setup:

1. During `make setup`, you'll be prompted for your Git name and email
2. If you skip it or want to reconfigure later, run:
   ```bash
   ./scripts/configure-git.sh
   ```
   or
   ```bash
   make install  # Will prompt if not already configured
   ```

Your Git configuration is stored in `~/.gitconfig` (global).

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

### Git configuration not set

To configure or reconfigure Git:
```bash
./scripts/configure-git.sh
```

## File Structure

```
ubuntu1-1/
├── home-manager/
│   ├── flake.nix              # Nix flake configuration
│   ├── home.nix               # Home Manager configuration
│   └── config/                # Tool configurations
├── scripts/
│   ├── setup.sh               # Setup script
│   ├── configure-git.sh       # Git configuration (interactive)
│   ├── post-install.sh        # Shell change script
│   ├── verify-env.sh          # Verification script
│   ├── test-docker.sh         # Docker test runner
│   └── test-in-docker.sh      # Container tests
├── .dockerignore              # Docker build exclusions
├── .shellcheckrc              # ShellCheck configuration
├── Dockerfile.test            # Docker test container
├── Makefile                   # Automation targets
└── README.md                  # This file

GitHub Actions workflow (in parent repo):
../.github/workflows/verify-ubuntu1-1.yml
```

## Resources

- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Package Search](https://search.nixos.org/packages)
- [Home Manager Options](https://nix-community.github.io/home-manager/options.html)
- [Starship Configuration](https://starship.rs/config/)

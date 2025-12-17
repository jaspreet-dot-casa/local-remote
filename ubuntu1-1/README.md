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

This installs Nix, Docker, Home Manager, and creates .env:

```bash
make setup
```

### 4. Configure your git identity

Edit `.env` and fill in your details:

```bash
vim .env
```

```bash
# .env
GIT_NAME=John Doe
GIT_EMAIL=john@example.com
```

### 5. Install packages

This installs zsh, oh-my-zsh, and all tools via Home Manager:

```bash
make install
```

### 6. Change default shell to zsh

```bash
make zsh
```

### 7. Log out and back in

For docker group and shell changes to take effect:

```bash
exit
# SSH back in
```

### 8. Verify installation

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

Git user name and email are configured via the `.env` file:

1. Edit `.env`:
   ```bash
   GIT_NAME=Your Name
   GIT_EMAIL=your@email.com
   ```

2. Apply changes:
   ```bash
   make install
   ```

The `.env` file is gitignored to keep your credentials private. Use `.env.example` as a template.

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

### Continuous Integration

The repository includes a GitHub Actions workflow (located at `../.github/workflows/verify-ubuntu1-1.yml`) that automatically:
- Run shellcheck on all scripts
- Validate Nix flake configuration
- Test full setup on Ubuntu 24.04 (Blacksmith runner)
- Verify all tools installation
- Test idempotency (re-running scripts)

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

### .env changes not applying

After editing `.env`:
```bash
make install  # Re-runs configure-git.sh
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
│   ├── configure-git.sh       # Git configuration from .env
│   ├── post-install.sh        # Shell change script
│   ├── verify-env.sh          # Verification script
│   ├── test-docker.sh         # Docker test runner
│   └── test-in-docker.sh      # Container tests
├── .env.example               # Template for .env
├── .env                       # Your git config (gitignored)
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

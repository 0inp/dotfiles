# Dotfiles Project Configuration

## Project Overview

This is a dotfiles repository that manages configuration files for various development tools using GNU Stow. The repository contains configurations for:

- **Shell**: Zsh with custom plugins and settings
- **Editor**: Neovim with Lua configuration
- **Version Control**: Git and LazyGit
- **Terminal**: TMUX with plugins
- **Package Management**: Homebrew, Mise (runtime manager)
- **Window Management**: Aerospace
- **Database Tools**: PGCLI, LiteCLI
- **Workspace Management**: Worktrunk
- **System Tools**: Htop, Ghostty

## Project Structure

```
.
├── aerospace/          # Window management configuration
├── brew/              # Homebrew packages and casks
├── git/               # Git configuration
├── gnupg/             # GPG setup
├── htop/              # System monitor configuration
├── mise/              # Runtime manager configuration
├── nvim/              # Neovim editor configuration
├── pgcli/             # PostgreSQL CLI configuration
├── python/            # Python setup
├── tmux/              # Terminal multiplexer configuration
├── zsh/               # Zsh shell configuration
├── worktrunk/         # Workspace manager configuration
├── scripts/           # Installation and update scripts
├── resources/         # Additional resources and macOS settings
└── README.md          # Project documentation
```

## Key Configuration Files

- **Zsh**: `zsh/.config/zsh/*.zsh` (functions, aliases, environment variables)
- **Neovim**: `nvim/.config/nvim/init.lua` and Lua modules
- **Git**: `git/.gitconfig` and `git/.config/lazygit.yaml`
- **TMUX**: `tmux/.config/tmux/tmux.conf` with plugins
- **Homebrew**: `brew/.config/brewfile/Brewfile`
- **Mise**: `mise/.config/mise/config.toml`
- **Worktrunk**: `worktrunk/.config/worktrunk/config.toml`

## Build and Installation

The project uses GNU Stow for managing dotfiles:

```bash
# Install dependencies
brew install git stow

# Clone and install
git clone https://github.com/0inp/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x ./scripts/install.sh
./scripts/install.sh

# Update
git pull
stow -R */
```

## Development Workflow

1. **Installation**: Run `./scripts/install.sh` for full setup
2. **Updates**: Run `./scripts/update.sh` to update all components
3. **Stow Management**: Use `stow -R */` to reapply all configurations
4. **Tool-specific Updates**: Individual tools can be updated via their respective package managers

## Code Conventions

- Configuration files follow tool-specific conventions
- Shell scripts use Bash with standard conventions
- Neovim uses Lua for modern configuration
- YAML/TOML/JSON files follow standard formatting
- Comments are used to explain non-obvious configurations

## Testing

The project is tested through:
- Manual verification of tool functionality
- Shell script execution testing
- Configuration file syntax validation
- Stow symlink verification

## Special Notes

- macOS-specific configurations and settings
- Uses Homebrew for package management
- Mise for runtime version management
- Worktrunk for workspace organization
- Comprehensive macOS defaults configuration in `resources/macos_settings.sh`
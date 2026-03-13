# Dotfiles Project

This project contains my personal dotfiles for configuring my development
environment.

## Structure

- Configuration files are organized into directories, with each directory
  corresponding to a specific tool (e.g., `nvim`, `zsh`, `git`, `tmux`).
- The `stow` command is used to create symlinks from this repository to the home
  directory. For example, `stow nvim` would symlink the contents of the `nvim`
  directory to `~/.config/nvim`.
- **OpenAgents Framework**: Located in `opencode/.opencode/` (stowed to `~/.opencode`)

## Branching Strategy

- The `main` branch contains the configuration for my personal MacBook.
- Other branches are used for different machines, such as work laptops. This
  allows for machine-specific configurations while sharing the common base.

## Role for OpenAgents

When working in this repository, your role is to help me manage my dotfiles.
This includes:

- Adding new configurations for tools.
- Modifying existing configurations.
- Helping me with `stow` commands.
- Keeping the configurations clean and organized.
- Assisting with branch management for different machine setups.
- Managing the OpenAgents framework updates.

## Current Tools Configured

- **Shell**: zsh (with custom aliases and plugins)
- **Editor**: nvim (Neovim with Lua configuration)
- **Terminal Multiplexer**: tmux (with plugins like resurrect, continuum)
- **Window Management**: aerospace (tiling window manager)
- **Package Management**: brew (Homebrew), mise (runtime manager)
- **Version Control**: git (with custom aliases)
- **Database Tools**: pgcli (PostgreSQL CLI)
- **Development**: python environment setup
- **Productivity**: worktrunk (workspace management)
- **System Tools**: htop (monitoring), gnupg (encryption)
- **AI Framework**: OpenAgents Control (in `opencode/.opencode/`)

## Common Tasks

### Adding a new tool configuration:
1. Create directory structure: `mkdir -p toolname/.config/toolname`
2. Add configuration files
3. Update Brewfile if needed: `brew/.config/brewfile/Brewfile`
4. Create symlink: `stow toolname`

### Updating existing configuration:
1. Edit files in the appropriate directory
2. Test in new terminal session
3. Reapply if needed: `stow -R toolname`

### Updating OpenAgents Framework:
```bash
# Manual update
curl -fsSL https://raw.githubusercontent.com/darrenhinde/OpenAgentsControl/main/update.sh | bash

# Or use the update script
scripts/update_opencode.sh
```

### Troubleshooting stow issues:
```bash
# Check for conflicts
stow -n toolname

# Remove and reapply
stow -D toolname && stow toolname
```

## Update Workflow

The comprehensive update script (`scripts/update.sh`) handles:
1. Homebrew package updates
2. Dotfiles repository updates
3. OpenAgents framework updates
4. Stow configuration reapplication

Run it periodically to keep everything up to date.

## Installation

The main installation script is located at `scripts/install.sh`. Use it to set up your development environment:

```bash
chmod +x scripts/install.sh && ./scripts/install.sh
```

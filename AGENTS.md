# Dotfiles Project

This project contains my personal dotfiles for configuring my development
environment.

## Structure

- Configuration files are organized into directories, with each directory
  corresponding to a specific tool (e.g., `nvim`, `zsh`, `git`).
- The `stow` command is used to create symlinks from this repository to the home
  directory. For example, `stow nvim` would symlink the contents of the `nvim`
  directory to `~/.config/nvim`.

## Branching Strategy

- The `main` branch contains the configuration for my personal MacBook.
- Other branches are used for different machines, such as work laptops. This
  allows for machine-specific configurations while sharing the common base.

## Role for Opencode

When working in this repository, your role is to help me manage my dotfiles.
This includes:

- Adding new configurations for tools.
- Modifying existing configurations.
- Helping me with `stow` commands.
- Keeping the configurations clean and organized.
- Assisting with branch management for different machine setups.

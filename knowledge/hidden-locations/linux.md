# Hidden Data Locations: Linux

A comprehensive guide to where applications hide data on Linux systems.

## Overview

Linux follows the XDG Base Directory Specification for most modern apps, but legacy apps may use other locations.

## XDG Base Directories

### Standard Locations

| Variable | Default | Purpose |
|----------|---------|---------|
| `$XDG_CONFIG_HOME` | `~/.config` | Configuration files |
| `$XDG_DATA_HOME` | `~/.local/share` | Application data |
| `$XDG_CACHE_HOME` | `~/.cache` | Cache files |
| `$XDG_STATE_HOME` | `~/.local/state` | State data |

### System-Wide

| Location | Purpose |
|----------|---------|
| `/etc/<app>` | System configuration |
| `/var/lib/<app>` | Variable data |
| `/var/cache/<app>` | System cache |
| `/var/log/<app>` | Logs |
| `/opt/<app>` | Optional packages |

## User Data Locations

### ~/.config
```
~/.config/
├── <app>/              # App configuration
├── autostart/          # Startup applications
├── systemd/user/       # User services
└── mimeapps.list       # File associations
```

### ~/.local/share
```
~/.local/share/
├── <app>/              # App data
├── applications/       # .desktop files
├── icons/              # User icons
├── fonts/              # User fonts
└── Trash/              # Trash folder
```

### ~/.cache
```
~/.cache/
├── <app>/              # App cache
├── thumbnails/         # File thumbnails
├── fontconfig/         # Font cache
└── pip/                # Python package cache
```

## Legacy Dotfile Locations

Many apps still use home directory dotfiles:

| Location | App/Purpose |
|----------|-------------|
| `~/.bashrc`, `~/.bash_profile` | Bash |
| `~/.zshrc` | Zsh |
| `~/.vimrc`, `~/.vim/` | Vim |
| `~/.emacs.d/` | Emacs |
| `~/.gitconfig` | Git |
| `~/.ssh/` | SSH (DON'T DELETE) |
| `~/.gnupg/` | GPG (DON'T DELETE) |

## Development Tool Locations

### Node.js
```
~/.npm/                 # npm cache
~/.nvm/                 # Node Version Manager
~/.yarn/                # Yarn
~/.pnpm/                # pnpm
node_modules/           # Per-project (in projects)
```

### Python
```
~/.local/lib/python*/   # User packages
~/.cache/pip/           # pip cache
~/.virtualenvs/         # virtualenvwrapper
~/.pyenv/               # pyenv
~/.conda/               # Conda
~/anaconda3/            # Anaconda
~/miniconda3/           # Miniconda
```

### Rust
```
~/.cargo/               # Cargo home
~/.rustup/              # Rustup toolchains
```

### Java
```
~/.m2/                  # Maven
~/.gradle/              # Gradle
~/.sdkman/              # SDKMAN
```

### Go
```
~/go/                   # GOPATH (default)
~/.cache/go-build/      # Build cache
```

## Container/VM Locations

### Docker
```
~/.docker/              # Docker config
/var/lib/docker/        # Docker data (root)
```

### Podman
```
~/.local/share/containers/
~/.config/containers/
```

### Flatpak
```
~/.var/app/<app-id>/    # Flatpak app data
~/.local/share/flatpak/ # User flatpaks
/var/lib/flatpak/       # System flatpaks
```

### Snap
```
~/snap/<app>/           # Snap data
/var/snap/<app>/        # Snap common
```

## Persistence Mechanisms

### systemd User Services
```
~/.config/systemd/user/         # User services
~/.config/systemd/user/*.wants/ # Enabled services
```

To find orphaned services:
```bash
# List user services
systemctl --user list-units --type=service

# Check if service's app exists
systemctl --user status <service>
```

### Autostart
```
~/.config/autostart/    # XDG autostart
```

### Cron
```bash
crontab -l              # User crontab
```

## Package Manager Caches

### apt (Debian/Ubuntu)
```bash
sudo du -sh /var/cache/apt
sudo apt clean          # Clean cache
```

### dnf/yum (Fedora/RHEL)
```bash
sudo du -sh /var/cache/dnf
sudo dnf clean all
```

### pacman (Arch)
```bash
du -sh /var/cache/pacman/pkg
sudo pacman -Sc         # Clean old packages
```

## Cleanup Commands

### Clear User Caches
```bash
rm -rf ~/.cache/*
```

### Clear Specific App Data
```bash
rm -rf ~/.config/<app>
rm -rf ~/.local/share/<app>
rm -rf ~/.cache/<app>
```

### Clear npm/Node
```bash
npm cache clean --force
rm -rf ~/.npm/_cacache
rm -rf ~/.nvm/.cache
```

### Clear pip
```bash
pip cache purge
rm -rf ~/.cache/pip
```

### Clear Thumbnail Cache
```bash
rm -rf ~/.cache/thumbnails
```

## Safety Rules

1. **NEVER** delete `~/.ssh/`
2. **NEVER** delete `~/.gnupg/`
3. **NEVER** delete `/etc/` without knowing what you're doing
4. **BACKUP** before deleting `~/.config/` entries
5. **CHECK** if service is still needed before removing

# Skill: Orphan Hunter

A skill for finding application data that belongs to apps that are no longer installed.

## Trigger

Use this skill when the user asks to:
- Find leftover data
- Find orphaned files
- Clean up after uninstalled apps
- Find data without apps

## Detection Logic

### macOS

For each directory in Application Support, check if a corresponding app exists:

```bash
find_orphans_macos() {
  local orphans=()

  # Check Application Support
  for dir in ~/Library/Application\ Support/*/; do
    local name=$(basename "$dir")

    # Skip system directories
    [[ "$name" == "AddressBook" ]] && continue
    [[ "$name" == "com.apple."* ]] && continue
    [[ "$name" == "CloudDocs" ]] && continue

    # Check if app exists
    if ! ls /Applications/*"$name"* &>/dev/null && \
       ! ls /Applications/**/*"$name"* &>/dev/null && \
       ! ls /System/Applications/*"$name"* &>/dev/null; then
      orphans+=("$dir")
    fi
  done

  printf '%s\n' "${orphans[@]}"
}
```

### Common Orphan Patterns

These apps frequently leave orphans:

| App Pattern | Data Location | Common Size |
|-------------|---------------|-------------|
| JetBrains/* | ~/Library/Application Support/JetBrains | 1-5 GB |
| Discord | ~/Library/Application Support/discord | 200-500 MB |
| Slack | ~/Library/Application Support/Slack | 100-300 MB |
| Figma | ~/Library/Application Support/Figma | 100-200 MB |
| Spotify | ~/Library/Application Support/Spotify | 500 MB - 2 GB |
| Zoom | ~/Library/Application Support/zoom.us | 100-300 MB |
| VSCode | ~/Library/Application Support/Code | 500 MB - 2 GB |
| Chrome | ~/Library/Application Support/Google/Chrome | 1-5 GB |

### Hidden Orphans

Also check these hidden locations:

```bash
# Home directory dotfiles
for dotdir in ~/.[!.]*; do
  [[ -d "$dotdir" ]] || continue
  local name=$(basename "$dotdir" | sed 's/^\.//')

  # Check if related app exists
  case "$name" in
    npm|nvm|yarn|pnpm)  # Node.js tools - check if node exists
      command -v node &>/dev/null || echo "ORPHAN: $dotdir"
      ;;
    cargo|rustup)  # Rust tools
      command -v cargo &>/dev/null || echo "ORPHAN: $dotdir"
      ;;
    *)
      # Generic check
      ;;
  esac
done
```

## Container Orphans (macOS)

Sandboxed apps use Containers:

```bash
find_container_orphans() {
  for container in ~/Library/Containers/*/; do
    local bundle_id=$(basename "$container")

    # Try to find the app
    local app_path=$(mdfind "kMDItemCFBundleIdentifier == '$bundle_id'" 2>/dev/null | head -1)

    if [[ -z "$app_path" ]]; then
      echo "ORPHAN: $container"
    fi
  done
}
```

## Group Container Orphans

```bash
find_group_container_orphans() {
  for gc in ~/Library/Group\ Containers/*/; do
    local group_id=$(basename "$gc")

    # Extract app identifier (usually after the team ID)
    local app_part=$(echo "$group_id" | sed 's/^[A-Z0-9]*\.//')

    # Check if any app with this identifier exists
    if ! mdfind "kMDItemCFBundleIdentifier == '*$app_part*'" &>/dev/null; then
      echo "ORPHAN: $gc"
    fi
  done
}
```

## Output Format

Present orphans as:

| Status | Location | Size | Last Modified | Action |
|--------|----------|------|---------------|--------|
| ORPHAN | ~/Library/Application Support/Discord | 259 MB | 30 days ago | Safe to remove |
| LIKELY | ~/.antigravity | 1.4 GB | 7 days ago | Verify first |

## Confidence Levels

- **CONFIRMED**: App definitely doesn't exist
- **LIKELY**: Strong indication app was removed
- **UNCERTAIN**: Might be shared data or system component

## Safety Rules

1. Never auto-delete - always confirm with user
2. Skip anything with "apple" or "com.apple" in the name
3. Skip system directories (AddressBook, CloudDocs, etc.)
4. Show last modified date to help user decide
5. Warn if data is recent (< 7 days)

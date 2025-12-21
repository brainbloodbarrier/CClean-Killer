# /report - System Health Report Generator

Generate a comprehensive system storage and health report.

## Usage

```
/report              # Generate full report
/report --markdown   # Output as markdown file
/report --json       # Output as JSON
```

## Instructions

When the user runs /report, generate a comprehensive analysis:

### 1. System Information

```bash
# macOS
sw_vers
system_profiler SPHardwareDataType | grep -E "Model|Memory|Chip"

# Linux
cat /etc/os-release
free -h
```

### 2. Disk Overview

```bash
# macOS
diskutil list
df -h /

# APFS container info (macOS)
diskutil apfs list
```

### 3. Storage Breakdown

Generate a complete breakdown:

```
=== STORAGE REPORT ===
Generated: 2024-12-21 12:00:00

DISK OVERVIEW
Total:     228 GB
Used:      120 GB (52%)
Available: 108 GB (48%)

TOP DIRECTORIES
1. ~/Library                    20 GB
2. ~/Documents                  15 GB
3. /Applications                12 GB
4. ~/.docker                     8 GB
5. ~/Downloads                   5 GB
```

### 4. Application Analysis

List all installed applications with their data footprint:

| App | App Size | Data Size | Total |
|-----|----------|-----------|-------|
| Docker | 2.1 GB | 15 GB | 17.1 GB |
| Xcode | 4.9 GB | 500 MB | 5.4 GB |
| VS Code | 659 MB | 1.2 GB | 1.9 GB |

### 5. Parasite Status

List all LaunchAgents/Daemons with status:

| Agent | Status | App Exists |
|-------|--------|------------|
| com.docker.vmnetd | Active | Yes |
| com.adobe.GC.Invoker | Parasite | Telemetry |

### 6. Orphan Detection

List orphaned data directories:

| Location | Size | Last Modified |
|----------|------|---------------|
| ~/Library/Application Support/Discord | 259 MB | 30 days ago |

### 7. Recommendations

```
=== RECOMMENDATIONS ===

HIGH PRIORITY (> 1 GB recoverable)
1. Docker unused images: 5 GB
   Command: docker image prune -a

2. Orphaned Discord data: 259 MB
   Command: rm -rf ~/Library/Application\ Support/discord

MEDIUM PRIORITY (100 MB - 1 GB)
3. npm cache: 500 MB
   Command: npm cache clean --force

PARASITES TO REMOVE
4. com.adobe.GC.Invoker (telemetry)
   Command: /parasites --kill
```

### 8. Output Formats

#### Markdown (--markdown)
Save to `~/.cclean-killer/reports/report-YYYYMMDD.md`

#### JSON (--json)
```json
{
  "generated": "2024-12-21T12:00:00Z",
  "disk": {
    "total": 228000000000,
    "used": 120000000000,
    "available": 108000000000
  },
  "recommendations": [
    {
      "priority": "high",
      "description": "Docker unused images",
      "size": 5000000000,
      "command": "docker image prune -a"
    }
  ]
}
```

## Report Sections

1. **Executive Summary** - One-line status
2. **Disk Overview** - Total, used, available
3. **Top Consumers** - Biggest directories
4. **Application Audit** - Apps + their data
5. **Parasites** - Zombie processes
6. **Orphans** - Leftover data
7. **Recommendations** - Prioritized actions
8. **Historical Comparison** - If previous reports exist

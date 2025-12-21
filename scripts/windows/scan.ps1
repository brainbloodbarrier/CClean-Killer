# CClean-Killer - Windows System Scanner
# Analyzes disk usage and identifies cleanup opportunities

Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║     CClean-Killer - Windows Scanner      ║" -ForegroundColor Blue
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""

# Disk Overview
Write-Host "📊 Disk Overview" -ForegroundColor Green
Write-Host "────────────────────────────────────────────"
Get-PSDrive -PSProvider FileSystem | Format-Table Name, @{N='Used (GB)';E={[math]::Round($_.Used/1GB,2)}}, @{N='Free (GB)';E={[math]::Round($_.Free/1GB,2)}}, @{N='Total (GB)';E={[math]::Round(($_.Used+$_.Free)/1GB,2)}}
Write-Host ""

# Function to get folder size
function Get-FolderSize {
    param([string]$Path)
    if (Test-Path $Path) {
        $size = (Get-ChildItem $Path -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        return [math]::Round($size / 1MB, 2)
    }
    return 0
}

# AppData Roaming
Write-Host "📁 AppData\Roaming - Top 15" -ForegroundColor Green
Write-Host "────────────────────────────────────────────"
Get-ChildItem "$env:APPDATA" -Directory -ErrorAction SilentlyContinue |
    ForEach-Object {
        [PSCustomObject]@{
            Name = $_.Name
            SizeMB = Get-FolderSize $_.FullName
        }
    } | Sort-Object SizeMB -Descending | Select-Object -First 15 | Format-Table -AutoSize
Write-Host ""

# AppData Local
Write-Host "📁 AppData\Local - Top 15" -ForegroundColor Green
Write-Host "────────────────────────────────────────────"
Get-ChildItem "$env:LOCALAPPDATA" -Directory -ErrorAction SilentlyContinue |
    ForEach-Object {
        [PSCustomObject]@{
            Name = $_.Name
            SizeMB = Get-FolderSize $_.FullName
        }
    } | Sort-Object SizeMB -Descending | Select-Object -First 15 | Format-Table -AutoSize
Write-Host ""

# Temp folder
Write-Host "🗑️  Temp Folder" -ForegroundColor Green
Write-Host "────────────────────────────────────────────"
$tempSize = Get-FolderSize $env:TEMP
Write-Host "Temp size: $tempSize MB"
Write-Host ""

# Developer tools
Write-Host "🛠️  Developer Tools" -ForegroundColor Green
Write-Host "────────────────────────────────────────────"

$devPaths = @{
    "npm cache" = "$env:APPDATA\npm-cache"
    "npm global" = "$env:APPDATA\npm"
    "Yarn" = "$env:LOCALAPPDATA\Yarn"
    "pip cache" = "$env:LOCALAPPDATA\pip\cache"
    "Cargo" = "$env:USERPROFILE\.cargo"
    "Rustup" = "$env:USERPROFILE\.rustup"
    "Maven" = "$env:USERPROFILE\.m2"
    "Gradle" = "$env:USERPROFILE\.gradle"
    "NuGet" = "$env:LOCALAPPDATA\NuGet"
}

foreach ($tool in $devPaths.GetEnumerator()) {
    if (Test-Path $tool.Value) {
        $size = Get-FolderSize $tool.Value
        Write-Host "$($tool.Key): $size MB"
    }
}
Write-Host ""

# Windows Update Cache
Write-Host "📦 Windows Caches" -ForegroundColor Green
Write-Host "────────────────────────────────────────────"

$cachePaths = @{
    "Windows Update" = "C:\Windows\SoftwareDistribution\Download"
    "Windows Installer" = "C:\Windows\Installer"
    "Prefetch" = "C:\Windows\Prefetch"
    "Windows Temp" = "C:\Windows\Temp"
    "Package Cache" = "C:\ProgramData\Package Cache"
}

foreach ($cache in $cachePaths.GetEnumerator()) {
    if (Test-Path $cache.Value) {
        $size = Get-FolderSize $cache.Value
        Write-Host "$($cache.Key): $size MB"
    }
}
Write-Host ""

# Docker (if installed)
if (Get-Command docker -ErrorAction SilentlyContinue) {
    Write-Host "🐳 Docker" -ForegroundColor Green
    Write-Host "────────────────────────────────────────────"
    try {
        docker system df
    } catch {
        Write-Host "Docker not running"
    }
    Write-Host ""
}

# Registry orphans check
Write-Host "📋 Potential Registry Orphans" -ForegroundColor Green
Write-Host "────────────────────────────────────────────"
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue |
    Where-Object { $_.InstallLocation -and !(Test-Path $_.InstallLocation -ErrorAction SilentlyContinue) } |
    Select-Object DisplayName, InstallLocation |
    Format-Table -AutoSize
Write-Host ""

# Summary
Write-Host "════════════════════════════════════════════" -ForegroundColor Blue
Write-Host "            Quick Actions                    " -ForegroundColor Blue
Write-Host "════════════════════════════════════════════" -ForegroundColor Blue
Write-Host ""
Write-Host "  .\clean.ps1 --caches    - Clean temp and caches"
Write-Host "  .\clean.ps1 --dev       - Clean dev tool caches"
Write-Host "  .\clean.ps1 --all       - Full cleanup"
Write-Host ""

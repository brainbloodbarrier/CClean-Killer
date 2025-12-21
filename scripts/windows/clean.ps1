# CClean-Killer - Windows Cleanup Script
# Safely removes caches and temporary files

param(
    [switch]$DryRun,
    [switch]$Caches,
    [switch]$Dev,
    [switch]$All
)

Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║    CClean-Killer - Windows Cleanup       ║" -ForegroundColor Blue
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""

if ($DryRun) {
    Write-Host "⚠️  DRY RUN MODE - No files will be deleted" -ForegroundColor Yellow
    Write-Host ""
}

# Default to all if nothing specified
if (-not $Caches -and -not $Dev) {
    $All = $true
}

if ($All) {
    $Caches = $true
    $Dev = $true
}

$totalFreed = 0

function Get-FolderSizeKB {
    param([string]$Path)
    if (Test-Path $Path) {
        $size = (Get-ChildItem $Path -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        return [math]::Round($size / 1KB, 0)
    }
    return 0
}

function Format-Size {
    param([long]$KB)
    if ($KB -gt 1048576) {
        return "$([math]::Round($KB/1048576, 2)) GB"
    } elseif ($KB -gt 1024) {
        return "$([math]::Round($KB/1024, 2)) MB"
    } else {
        return "$KB KB"
    }
}

function Safe-Remove {
    param(
        [string]$Path,
        [string]$Description
    )

    if (Test-Path $Path) {
        $sizeKB = Get-FolderSizeKB $Path
        $sizeFormatted = Format-Size $sizeKB

        if ($DryRun) {
            Write-Host "Would remove: $Description ($sizeFormatted)" -ForegroundColor Yellow
        } else {
            Write-Host "Removing: $Description ($sizeFormatted)" -ForegroundColor Green
            Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
            $script:totalFreed += $sizeKB
        }
    }
}

# ============================================
# CACHES
# ============================================
if ($Caches) {
    Write-Host "🗑️  Cleaning Caches..." -ForegroundColor Green
    Write-Host "────────────────────────────────────────────"

    # User temp
    Safe-Remove "$env:TEMP\*" "User temp files"

    # Clear actual temp folder contents
    if (-not $DryRun) {
        Get-ChildItem $env:TEMP -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Windows temp (requires admin)
    if ([Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains 'S-1-5-32-544') {
        Safe-Remove "C:\Windows\Temp\*" "Windows temp files"
    } else {
        Write-Host "Skipping Windows temp (requires admin)" -ForegroundColor Yellow
    }

    # Prefetch (requires admin)
    if ([Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains 'S-1-5-32-544') {
        Safe-Remove "C:\Windows\Prefetch\*" "Prefetch cache"
    }

    # Thumbnail cache
    Safe-Remove "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" "Thumbnail cache"

    Write-Host ""
}

# ============================================
# DEV TOOLS
# ============================================
if ($Dev) {
    Write-Host "🛠️  Cleaning Developer Caches..." -ForegroundColor Green
    Write-Host "────────────────────────────────────────────"

    # npm cache
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        if ($DryRun) {
            Write-Host "Would run: npm cache clean --force" -ForegroundColor Yellow
        } else {
            Write-Host "Running: npm cache clean --force"
            npm cache clean --force 2>$null
        }
    }
    Safe-Remove "$env:APPDATA\npm-cache" "npm cache folder"

    # Yarn cache
    Safe-Remove "$env:LOCALAPPDATA\Yarn\Cache" "Yarn cache"

    # pip cache
    if (Get-Command pip -ErrorAction SilentlyContinue) {
        if ($DryRun) {
            Write-Host "Would run: pip cache purge" -ForegroundColor Yellow
        } else {
            Write-Host "Running: pip cache purge"
            pip cache purge 2>$null
        }
    }
    Safe-Remove "$env:LOCALAPPDATA\pip\cache" "pip cache"

    # Cargo registry cache
    Safe-Remove "$env:USERPROFILE\.cargo\registry\cache" "Cargo registry cache"

    # Gradle caches
    Safe-Remove "$env:USERPROFILE\.gradle\caches" "Gradle caches"

    # NuGet cache
    if (Get-Command nuget -ErrorAction SilentlyContinue) {
        if ($DryRun) {
            Write-Host "Would run: nuget locals all -clear" -ForegroundColor Yellow
        } else {
            Write-Host "Running: nuget locals all -clear"
            nuget locals all -clear 2>$null
        }
    }

    Write-Host ""
}

# ============================================
# SUMMARY
# ============================================
Write-Host "════════════════════════════════════════════" -ForegroundColor Blue
if ($DryRun) {
    Write-Host "Dry run complete. No files were deleted." -ForegroundColor Blue
} else {
    Write-Host "Cleanup complete!" -ForegroundColor Blue
    Write-Host "Total freed: $(Format-Size $totalFreed)" -ForegroundColor Blue
}
Write-Host "════════════════════════════════════════════" -ForegroundColor Blue

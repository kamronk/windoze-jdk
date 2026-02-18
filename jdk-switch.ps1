<#
.SYNOPSIS
    Install and switch between Java 8, 17, and 21 (Adoptium Temurin).

.PARAMETER Version
    JDK version to activate: 8, 17, or 21

.PARAMETER Install
    Install the JDK if not already present (requires admin for winget)

.EXAMPLE
    .\jdk-switch.ps1 21              # Switch to JDK 21 (must already be installed)
    .\jdk-switch.ps1 21 -Install     # Install JDK 21 if missing, then switch
    .\jdk-switch.ps1 8 -Install      # Install JDK 8 if missing, then switch
#>

param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateSet("8", "17", "21")]
    [string]$Version,

    [switch]$Install
)

$ErrorActionPreference = "Stop"

# Winget package IDs for each version
$packages = @{
    "8"  = "EclipseAdoptium.Temurin.8.JDK"
    "17" = "EclipseAdoptium.Temurin.17.JDK"
    "21" = "EclipseAdoptium.Temurin.21.JDK"
}

# Install directory patterns (Adoptium default install paths)
$searchPatterns = @{
    "8"  = "jdk-8*"
    "17" = "jdk-17*"
    "21" = "jdk-21*"
}

$adoptiumRoot = "C:\Program Files\Eclipse Adoptium"

function Find-JdkHome {
    param([string]$Ver)
    if (-not (Test-Path $adoptiumRoot)) { return $null }
    $match = Get-ChildItem $adoptiumRoot -Directory -Filter $searchPatterns[$Ver] |
             Sort-Object Name |
             Select-Object -Last 1
    if ($match) { return $match.FullName }
    return $null
}

function Remove-OldJavaPaths {
    param([string]$PathValue)
    # Remove any existing Adoptium JDK bin entries from PATH
    $parts = $PathValue -split ";" | Where-Object {
        $_ -ne "" -and $_ -notmatch "Eclipse Adoptium\\jdk-.*\\bin"
    }
    return ($parts -join ";")
}

# --- Check if already installed ---

$jdkHome = Find-JdkHome $Version

if (-not $jdkHome) {
    if ($Install) {
        Write-Host "Installing Adoptium Temurin JDK $Version..." -ForegroundColor Cyan
        $pkg = $packages[$Version]
        & winget install $pkg --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) {
            Write-Host "winget install failed. Try running as Administrator." -ForegroundColor Red
            exit 1
        }
        $jdkHome = Find-JdkHome $Version
        if (-not $jdkHome) {
            Write-Host "Installation succeeded but JDK not found at expected path." -ForegroundColor Red
            Write-Host "Check: $adoptiumRoot" -ForegroundColor Yellow
            exit 1
        }
        Write-Host "Installed to: $jdkHome" -ForegroundColor Green
    }
    else {
        Write-Host "JDK $Version is not installed." -ForegroundColor Red
        Write-Host "Run with -Install flag:  .\jdk-switch.ps1 $Version -Install" -ForegroundColor Yellow
        exit 1
    }
}
else {
    Write-Host "Found JDK $Version at: $jdkHome" -ForegroundColor Green
}

# --- Update JAVA_HOME and PATH (User scope, persists across sessions) ---

$jdkBin = "$jdkHome\bin"

# Update persistent (User) environment
$userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
$cleanPath = Remove-OldJavaPaths $userPath
$newPath = "$jdkBin;$cleanPath"

[Environment]::SetEnvironmentVariable("JAVA_HOME", $jdkHome, "User")
[Environment]::SetEnvironmentVariable("PATH", $newPath, "User")

# Update current session
$env:JAVA_HOME = $jdkHome
$env:PATH = "$jdkBin;" + (Remove-OldJavaPaths $env:PATH)

# --- Verify ---

Write-Host ""
Write-Host "JAVA_HOME = $jdkHome" -ForegroundColor White
$javaOut = & "$jdkBin\java" -version 2>&1 | Select-Object -First 1
Write-Host "Active:     $javaOut" -ForegroundColor White
Write-Host ""
Write-Host "Switched to JDK $Version. New terminals will use this version." -ForegroundColor Green

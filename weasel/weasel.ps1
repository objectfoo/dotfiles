<#
.SYNOPSIS
    A script to manage WSL2 distributions and snapshots.
.DESCRIPTION
    Allows you to backup, restore, create new, and delete WSL2 instances.
.PARAMETER Action
    The operation to perform: Backup, Restore, New, or Delete.
.PARAMETER Distro
    The name of the WSL target distribution.
.PARAMETER FilePath
    The path to the .tar archive (Required for Backup and Restore).
.PARAMETER InstallPath
    The directory to deploy the instance (Required for Restore and New).
.EXAMPLE
    .\wsl-manager.ps1 -Action Backup -Distro Ubuntu -FilePath C:\Backups\ubuntu-snap.tar
.EXAMPLE
    .\wsl-manager.ps1 -Action Restore -Distro Ubuntu-Dev -FilePath C:\Backups\ubuntu-snap.tar -InstallPath C:\WSL\Ubuntu-Dev
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory = $true, HelpMessage = "Action to perform.")]
  [ValidateSet("Backup", "Restore", "New", "Delete")]
  [string]$Action,

  [Parameter(Mandatory = $true, HelpMessage = "Name of the WSL distribution.")]
  [string]$Distro,

  [Parameter(Mandatory = $false, HelpMessage = "Path to the .tar archive file.")]
  [string]$FilePath,

  [Parameter(Mandatory = $false, HelpMessage = "Installation folder for the distro.")]
  [string]$InstallPath
)

# Visual header helper
function Show-Header([string]$Title) {
  Write-Host "`n[ WSL MANAGER ] === $Title ===" -ForegroundColor Cyan
}

# --- BACKUP ACTION ---
if ($Action -eq "Backup") {
  if (-not $FilePath) { throw "Error: -FilePath is required for backups." }
  Show-Header "Backing up '$Distro'"
    
  Write-Host "Stopping WSL to safely capture state..." -ForegroundColor Gray
  wsl --shutdown
    
  Write-Host "Exporting to $FilePath (this may take a few minutes)..." -ForegroundColor Yellow
  wsl --export $Distro $FilePath
    
  if ($LASTEXITCODE -eq 0) { Write-Host "Success: Backup created successfully." -ForegroundColor Green }
}

# --- RESTORE ACTION ---
if ($Action -eq "Restore") {
  if (-not $FilePath -or -not $InstallPath) { throw "Error: -FilePath and -InstallPath are required for restore." }
  Show-Header "Restoring '$Distro'"
    
  if (-not (Test-Path $InstallPath)) { New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null }
    
  Write-Host "Importing archive from $FilePath..." -ForegroundColor Yellow
  wsl --import $Distro $InstallPath $FilePath --version 2
    
  if ($LASTEXITCODE -eq 0) { Write-Host "Success: Distribution '$Distro' restored." -ForegroundColor Green }
}

# --- NEW ACTION ---
if ($Action -eq "New") {
  Show-Header "Creating New Instance"
  Write-Host "Fetching online distribution marketplace list..." -ForegroundColor Gray
  wsl --list --online
    
  $Choice = Read-Host "`nEnter the exact name from the list above to download and install (e.g., Ubuntu-22.04)"
  if ($Choice) {
    Write-Host "Installing $Choice as '$Distro'..." -ForegroundColor Yellow
    wsl --install --distribution $Choice --name $Distro
  }
}

# --- DELETE ACTION ---
if ($Action -eq "Delete") {
  Show-Header "Deleting '$Distro'"
  Write-Host "WARNING: This permanently deletes all files inside this distribution!" -ForegroundColor Red
  $Confirm = Read-Host "Type 'YES' to confirm destruction of $Distro"
    
  if ($Confirm -eq "YES") {
    Write-Host "Unregistering $Distro..." -ForegroundColor Yellow
    wsl --unregister $Distro
    Write-Host "Success: Instance removed." -ForegroundColor Green
  }
  else {
    Write-Host "Aborted. No changes made." -ForegroundColor Gray
  }
}
Write-Host ""

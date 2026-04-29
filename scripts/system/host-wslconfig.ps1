[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$dotfilesDir = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$source = Join-Path $dotfilesDir 'wsl\config\.wslconfig'
$target = Join-Path $HOME '.wslconfig'

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host "[ OK ] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
    throw "Managed source file not found: $source"
}

$resolvedSource = (Resolve-Path -LiteralPath $source).Path

if (Test-Path -LiteralPath $target) {
    $sourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $source).Hash
    $targetHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $target).Hash

    if ($sourceHash -eq $targetHash) {
        Write-Info "File already up to date: $target"
        exit 0
    }

    if (-not $Force) {
        Write-Warn "Target file exists and differs. Re-run with -Force to replace: $target"
        exit 0
    }

    if ($PSCmdlet.ShouldProcess($target, 'Replace existing file')) {
        Remove-Item -LiteralPath $target -Force
        Write-Info "Removed existing file: $target"
    }
}

if ($PSCmdlet.ShouldProcess($target, "Copy managed .wslconfig from $resolvedSource")) {
    Copy-Item -LiteralPath $source -Destination $target -Force
    Write-Ok "Copied managed .wslconfig to: $target"
}

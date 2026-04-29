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

function Get-LinkTargetPath {
    param([System.IO.FileSystemInfo]$Item)

    if (-not ($Item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        return $null
    }

    $targetValue = $Item.Target
    if ($null -eq $targetValue) {
        return $null
    }

    if ($targetValue -is [array]) {
        $targetValue = $targetValue[0]
    }

    if ([string]::IsNullOrWhiteSpace($targetValue)) {
        return $null
    }

    $candidate = [string]$targetValue
    if (-not [System.IO.Path]::IsPathRooted($candidate)) {
        $candidate = Join-Path $Item.DirectoryName $candidate
    }

    try {
        return (Resolve-Path -LiteralPath $candidate).Path
    }
    catch {
        return $candidate
    }
}

if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
    throw "Managed source file not found: $source"
}

$resolvedSource = (Resolve-Path -LiteralPath $source).Path

if (Test-Path -LiteralPath $target) {
    $targetItem = Get-Item -LiteralPath $target -Force
    $existingLinkTarget = Get-LinkTargetPath -Item $targetItem

    if ($null -ne $existingLinkTarget) {
        if ($existingLinkTarget -eq $resolvedSource) {
            Write-Info "Link already correct: $target -> $resolvedSource"
            exit 0
        }

        if (-not $Force) {
            Write-Warn "Target is a different link. Re-run with -Force to replace: $target"
            exit 0
        }

        if ($PSCmdlet.ShouldProcess($target, 'Replace existing link')) {
            Remove-Item -LiteralPath $target -Force
            Write-Info "Removed existing link: $target"
        }
    }
    else {
        $sameContent = (Get-FileHash -Algorithm SHA256 -LiteralPath $source).Hash -eq (Get-FileHash -Algorithm SHA256 -LiteralPath $target).Hash
        if ($sameContent) {
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
}

if ($PSCmdlet.ShouldProcess($target, "Install managed .wslconfig from $resolvedSource")) {
    try {
        New-Item -ItemType SymbolicLink -Path $target -Target $resolvedSource -ErrorAction Stop | Out-Null
        Write-Ok "Linked: $target -> $resolvedSource"
        exit 0
    }
    catch {
        Write-Warn "Symlink creation failed; falling back to copy. $($_.Exception.Message)"
        Copy-Item -LiteralPath $source -Destination $target -Force
        Write-Ok "Copied managed .wslconfig to: $target"
    }
}

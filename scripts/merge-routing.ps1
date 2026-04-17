# scripts/merge-routing.ps1 — PowerShell-native idempotent routing-file merger.
#
# Status: v3.5.0 — closes the "Windows non-Cursor users need WSL2 for Python"
#         gap identified in the v3.4 review.
#
# Usage:
#   .\scripts\merge-routing.ps1 -Target "$HOME\.claude\CLAUDE.md" -Block "path\to\CLAUDE.md"
#   .\scripts\merge-routing.ps1 -Target "$HOME\.gemini\GEMINI.md" -Block "path\to\GEMINI.md"
#   .\scripts\merge-routing.ps1 -Target "path\to\AGENTS.md"       -Block "hermes\AGENTS.md" -DryRun
#
# Parameters:
#   -Target  : path to the platform routing file to update (created if missing)
#   -Block   : path to the routing-block file to splice in
#   -Marker  : start/end marker pair used to bound the managed block
#              (default: "# >>> skill-writer >>>" / "# <<< skill-writer <<<")
#   -DryRun  : preview; print the resulting file to stdout, do not write
#
# Semantics (matches the Python merger in the platform install.sh scripts):
#   1. If Target does not exist, create it with just the marked block.
#   2. If Target exists and contains the markers, REPLACE the block between
#      them with the new content.
#   3. If Target exists but lacks markers, APPEND the marked block to the end.
#   4. Re-running the script is idempotent (step 2 kicks in on subsequent runs).
#
# Exit codes:
#   0  success
#   1  input file errors (missing -Block, permission denied)
#   2  merge conflict (shouldn't happen; safeguard for corrupt markers)

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Target,

    [Parameter(Mandatory=$true)]
    [string]$Block,

    [string]$StartMarker = "# >>> skill-writer >>>",
    [string]$EndMarker   = "# <<< skill-writer <<<",

    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Write-Info    { param($m) Write-Host "  $m" }
function Write-Success { param($m) Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Warn    { param($m) Write-Warning "  $m" }
function Write-Err     { param($m) Write-Host "  [ERR] $m" -ForegroundColor Red }

if (-not (Test-Path -Path $Block -PathType Leaf)) {
    Write-Err "block file not found: $Block"
    exit 1
}

$blockContent = Get-Content -Path $Block -Raw -Encoding UTF8
$managedBlock = @"
$StartMarker

$blockContent

$EndMarker
"@

if (-not (Test-Path -Path $Target -PathType Leaf)) {
    Write-Info "target does not exist; will create: $Target"
    $newContent = $managedBlock.TrimEnd() + "`r`n"

    if ($DryRun) {
        Write-Info "[dry-run] would write $($newContent.Length) bytes to $Target"
        Write-Output $newContent
        exit 0
    }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Target) | Out-Null
    Set-Content -Path $Target -Value $newContent -Encoding UTF8 -NoNewline
    Write-Success "created $Target"
    exit 0
}

$existing = Get-Content -Path $Target -Raw -Encoding UTF8

$startIdx = $existing.IndexOf($StartMarker)
$endIdx   = $existing.IndexOf($EndMarker)

if ($startIdx -ge 0 -and $endIdx -gt $startIdx) {
    # REPLACE existing block
    $before = $existing.Substring(0, $startIdx)
    $afterStart = $endIdx + $EndMarker.Length
    $after  = $existing.Substring($afterStart)
    $newContent = ($before.TrimEnd() + "`r`n`r`n" + $managedBlock.TrimEnd() + $after).TrimEnd() + "`r`n"
    $action = "replaced"
}
elseif ($startIdx -ge 0 -xor $endIdx -ge 0) {
    Write-Err "corrupt markers in $Target — one of $StartMarker / $EndMarker missing"
    exit 2
}
else {
    # APPEND block
    $newContent = ($existing.TrimEnd() + "`r`n`r`n" + $managedBlock.TrimEnd()).TrimEnd() + "`r`n"
    $action = "appended to"
}

if ($DryRun) {
    Write-Info "[dry-run] would have $action $Target"
    Write-Output $newContent
    exit 0
}

Set-Content -Path $Target -Value $newContent -Encoding UTF8 -NoNewline
Write-Success "$action $Target"

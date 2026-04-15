# install.ps1 — Install skill-writer to Cursor on Windows (PowerShell)
#
# Usage:
#   .\cursor\install.ps1              # install to project-level .cursor\rules\
#   .\cursor\install.ps1 -Global      # install to user-level %USERPROFILE%\.cursor\rules\
#   .\cursor\install.ps1 -DryRun      # preview only, no changes
#
# Requirements: PowerShell 5.1+ (pre-installed on Windows 10/11)
# Requires Cursor 0.43+ for -Global (user-level rules)
#
# NOTE: Python 3 is NOT required for Cursor installation.
#       The Cursor installer only copies files — no routing-file merge needed.
#
# Trigger phrases (use keyword phrases, NOT slash commands — Cursor intercepts /):
#   create a skill        lean eval        evaluate this skill
#   optimize this skill   graph view       share my skill

param(
    [switch]$Global,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

function Write-Info    { param($msg) Write-Host "  $msg" }
function Write-Success { param($msg) Write-Host "  v $msg" -ForegroundColor Green }
function Write-Warn    { param($msg) Write-Host "  ! $msg" -ForegroundColor Yellow }
function Write-Err     { param($msg) Write-Host "  x $msg" -ForegroundColor Red }

if ($DryRun) { Write-Info "[DRY RUN] No files will be written." }

# Determine install root
if ($Global) {
    $CursorHome = Join-Path $env:USERPROFILE ".cursor"
    Write-Info "Installing to user-level $CursorHome\rules\ (requires Cursor 0.43+)"
} else {
    $CursorHome = Join-Path (Get-Location) ".cursor"
    Write-Info "Installing to project-level .cursor\rules\"
}

$RulesDir = Join-Path $CursorHome "rules"

# Create directories
$DirsToCreate = @($RulesDir,
    (Join-Path $CursorHome "refs"),
    (Join-Path $CursorHome "templates"),
    (Join-Path $CursorHome "eval"),
    (Join-Path $CursorHome "optimize"))

foreach ($dir in $DirsToCreate) {
    Write-Info "dir: $dir"
    if (-not $DryRun) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
}

# Copy skill rule file
$SkillSrc = Join-Path $ScriptDir "skill-writer.mdc"
$SkillDst = Join-Path $RulesDir "skill-writer.mdc"

if (Test-Path $SkillDst) {
    $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $BackupDst = "${SkillDst}.bak.${Timestamp}"
    Write-Info "Backed up existing rule file to $BackupDst"
    if (-not $DryRun) { Copy-Item $SkillDst $BackupDst }
}

if (-not $DryRun) { Copy-Item $SkillSrc $SkillDst }
Write-Success "skill-writer.mdc -> $SkillDst"

# Copy companion directories
foreach ($dir in @("refs", "templates", "eval", "optimize")) {
    $Src = Join-Path $ProjectRoot $dir
    $Dst = Join-Path $CursorHome $dir
    if (Test-Path $Src) {
        if (-not $DryRun) {
            Copy-Item -Recurse -Force "$Src\*" $Dst
        }
        Write-Success "$dir\ -> $Dst\"
    } else {
        Write-Warn "$dir\ not found at $Src -- skipped"
    }
}

Write-Host ""
Write-Success "skill-writer installed to Cursor"
Write-Host ""
Write-Info "Paths:"
Write-Info "  Rule:  $SkillDst"
Write-Info "  Refs:  $(Join-Path $CursorHome 'refs')\"
Write-Host ""
Write-Info "Next: Restart Cursor, then use keyword phrases (NOT slash commands):"
Write-Info "  'create a skill that ...'   (not /create)"
Write-Info "  'lean eval'                 (not /lean)"
Write-Info "  'evaluate this skill'       (not /eval)"
Write-Info "  'optimize this skill'       (not /opt)"
Write-Host ""
Write-Info "Windows path: $CursorHome"
Write-Info "Equivalent to: ~/.cursor (in WSL/macOS notation)"
Write-Host ""

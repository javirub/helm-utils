# Helm Schema Generator - Windows Installation Script
# This script adds the helmschema alias to your PowerShell profile

$ErrorActionPreference = "Stop"

# Get the directory where this script is located
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ScriptPath = Join-Path $ScriptDir "Generate-ValuesSchema.ps1"

# Check if script exists
if (-not (Test-Path $ScriptPath)) {
    Write-Host "✗ Error: Generate-ValuesSchema.ps1 not found in $ScriptDir" -ForegroundColor Red
    exit 1
}

# Ensure PowerShell profile exists
if (-not (Test-Path $PROFILE)) {
    Write-Host "Creating PowerShell profile at: $PROFILE" -ForegroundColor Cyan
    New-Item -Path $PROFILE -Type File -Force | Out-Null
}

# Check if alias already exists
$profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
if ($profileContent -match 'function helmschema') {
    Write-Host "⚠ helmschema function already exists in your profile" -ForegroundColor Yellow
    $choice = Read-Host "Do you want to update it? (Y/N)"
    if ($choice -ne 'Y' -and $choice -ne 'y') {
        Write-Host "Installation cancelled" -ForegroundColor Yellow
        exit 0
    }

    # Remove old function
    $profileContent = $profileContent -replace '(?s)# Helm Schema Generator.*?^}', ''
    $profileContent | Set-Content $PROFILE
}

# Add function to profile
$functionCode = @"

# Helm Schema Generator
function helmschema {
    param(
        [string]`$DefinitionsFile,
        [switch]`$Force
    )

    `$scriptPath = "$ScriptPath"

    if (`$DefinitionsFile) {
        & `$scriptPath -DefinitionsFile `$DefinitionsFile -Force:`$Force
    } else {
        & `$scriptPath -Force:`$Force
    }
}
"@

Add-Content -Path $PROFILE -Value $functionCode

Write-Host ""
Write-Host "✓ Installation completed!" -ForegroundColor Green
Write-Host ""
Write-Host "The 'helmschema' function has been added to your PowerShell profile" -ForegroundColor Cyan
Write-Host "Profile location: $PROFILE" -ForegroundColor Gray
Write-Host ""
Write-Host "Usage:" -ForegroundColor Yellow
Write-Host "  helmschema                    # Generate schema from values.yaml"
Write-Host "  helmschema definitions.json   # Generate with custom definitions"
Write-Host "  helmschema -Force             # Force overwrite without prompting"
Write-Host ""
Write-Host "To start using it now, run:" -ForegroundColor Cyan
Write-Host "  . `$PROFILE" -ForegroundColor White
Write-Host ""
Write-Host "Or restart your PowerShell session" -ForegroundColor Cyan

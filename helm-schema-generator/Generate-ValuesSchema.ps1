param(
    [string]$DefinitionsFile,
    [string]$ValuesFile = "values.yaml",
    [string]$OutputFile = "values.schema.json",
    [switch]$Force
)

$schemaFile = $OutputFile

# Check dependencies
function Test-Dependency {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

Write-Host "Checking dependencies..." -ForegroundColor Cyan
$missingDeps = @()

if (-not (Test-Dependency "yq")) { $missingDeps += "yq" }
if (-not (Test-Dependency "jq")) { $missingDeps += "jq" }
if (-not (Test-Dependency "python")) { $missingDeps += "python" }

if ($missingDeps.Count -gt 0) {
    Write-Host "✗ Missing dependencies: $($missingDeps -join ', ')" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install:" -ForegroundColor Yellow
    foreach ($dep in $missingDeps) {
        switch ($dep) {
            "yq" { Write-Host "  - yq: choco install yq (or from https://github.com/mikefarah/yq)" }
            "jq" { Write-Host "  - jq: choco install jq (or from https://stedolan.github.io/jq/)" }
            "python" { Write-Host "  - python: https://www.python.org/downloads/" }
        }
    }
    exit 1
}

# Check genson (requires Python)
try {
    $null = python -c "import genson" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ genson is not installed" -ForegroundColor Red
        Write-Host "Install with: pip install genson" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "✗ Error checking genson" -ForegroundColor Red
    exit 1
}

Write-Host "✓ All dependencies are installed" -ForegroundColor Green
Write-Host ""

# Check if values file exists
if (-not (Test-Path $ValuesFile)) {
    Write-Host "✗ Error: File not found: $ValuesFile" -ForegroundColor Red
    exit 1
}

# Check if output file already exists
if ((Test-Path $schemaFile) -and -not $Force) {
    Write-Host "⚠ File $schemaFile already exists" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  [R] Replace existing file"
    Write-Host "  [B] Create backup with timestamp"
    Write-Host "  [C] Cancel operation"
    Write-Host ""

    $choice = Read-Host "Choose an option (R/B/C)"

    switch ($choice.ToUpper()) {
        "R" {
            Write-Host "→ Replacing file..." -ForegroundColor Cyan
        }
        "B" {
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $backupName = "$schemaFile.$timestamp.bak"
            Copy-Item $schemaFile $backupName
            Write-Host "→ Backup created: $backupName" -ForegroundColor Cyan
        }
        "C" {
            Write-Host "✗ Operation cancelled" -ForegroundColor Red
            exit 0
        }
        default {
            Write-Host "✗ Invalid option. Operation cancelled" -ForegroundColor Red
            exit 1
        }
    }
} elseif ((Test-Path $schemaFile) -and $Force) {
    Write-Host "→ Force mode: Replacing existing file..." -ForegroundColor Cyan
}

# Generate basic schema from values.yaml
Write-Host "Generating schema from $ValuesFile..." -ForegroundColor Cyan
yq -o=json $ValuesFile |
python -m genson |
jq '. + {"$schema": "http://json-schema.org/draft-07/schema#"}' > $schemaFile

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Error generating schema" -ForegroundColor Red
    exit 1
}

# Add definitions if provided
if ($DefinitionsFile) {
    if (Test-Path $DefinitionsFile) {
        # Read generated schema
        $schema = Get-Content $schemaFile -Raw | ConvertFrom-Json

        # Read definitions file
        $defsContent = Get-Content $DefinitionsFile -Raw | ConvertFrom-Json

        # Add definitions
        if ($defsContent.definitions) {
            $schema | Add-Member -MemberType NoteProperty -Name "definitions" -Value $defsContent.definitions -Force
        }

        # Save result with sufficient depth to avoid truncation
        $schema | ConvertTo-Json -Depth 100 | Set-Content $schemaFile

        Write-Host "✓ Schema generated with definitions from $DefinitionsFile" -ForegroundColor Green
    } else {
        Write-Host "✗ Error: File not found: $DefinitionsFile" -ForegroundColor Red
    }
} else {
    Write-Host "✓ Schema generated" -ForegroundColor Green
}

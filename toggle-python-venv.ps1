# Toggle (Enter/Exit) Python Virtual Environment
# Usage: .\toggle-python-venv.ps1 [venv_name]

param(
    [string]$VenvName = ""
)

# Check if we're currently in a virtual environment
if ($env:VIRTUAL_ENV) {
    Write-Host "Currently in virtual environment: $env:VIRTUAL_ENV" -ForegroundColor Cyan
    $exitVenv = Read-Host "Do you want to deactivate it? (Y/n)"
    if ($exitVenv -eq "" -or $exitVenv -eq "y" -or $exitVenv -eq "Y") {
        Write-Host "Deactivating virtual environment..." -ForegroundColor Yellow
        deactivate
        Write-Host "Virtual environment deactivated." -ForegroundColor Green
        exit 0
    }
}

# Find all virtual environments in current directory
$venvs = @()
Get-ChildItem -Directory | Where-Object { 
    Test-Path (Join-Path $_.FullName "Scripts\activate.ps1") 
} | ForEach-Object {
    $venvs += $_.Name
}

# Handle no venvs found
if ($venvs.Count -eq 0) {
    Write-Host "No virtual environments found in current directory!" -ForegroundColor Red
    Write-Host "To create one, run: .\create-python-venv.ps1" -ForegroundColor Yellow
    exit 1
}

# If VenvName not provided and multiple venvs exist, let user select
if ([string]::IsNullOrEmpty($VenvName)) {
    if ($venvs.Count -eq 1) {
        $VenvName = $venvs[0]
        Write-Host "Found virtual environment: $VenvName" -ForegroundColor Green
    } else {
        Write-Host "Multiple virtual environments found:" -ForegroundColor Green
        for ($i = 0; $i -lt $venvs.Count; $i++) {
            Write-Host "  $($i + 1). $($venvs[$i])" -ForegroundColor Cyan
        }
        
        do {
            $selection = Read-Host "`nSelect virtual environment (1-$($venvs.Count))"
            $selectionInt = 0
            $validSelection = [int]::TryParse($selection, [ref]$selectionInt) -and 
                              $selectionInt -ge 1 -and 
                              $selectionInt -le $venvs.Count
        } while (-not $validSelection)
        
        $VenvName = $venvs[$selectionInt - 1]
    }
}

# Check if specified virtual environment exists
if (-not (Test-Path $VenvName)) {
    Write-Host "Virtual environment '$VenvName' not found!" -ForegroundColor Red
    if ($venvs.Count -gt 0) {
        Write-Host "Available virtual environments:" -ForegroundColor Yellow
        $venvs | ForEach-Object {
            Write-Host "  - $_" -ForegroundColor Cyan
        }
    }
    exit 1
}

# Check if activation script exists
$activateScript = Join-Path $VenvName "Scripts\activate.ps1"
if (-not (Test-Path $activateScript)) {
    Write-Host "Activation script not found at: $activateScript" -ForegroundColor Red
    Write-Host "This doesn't appear to be a valid Python virtual environment." -ForegroundColor Red
    exit 1
}

# Check current execution policy
$executionPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($executionPolicy -eq "Restricted") {
    Write-Host "PowerShell execution policy is restricted. Attempting to set it to RemoteSigned for current user..." -ForegroundColor Yellow
    try {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Write-Host "Execution policy updated successfully." -ForegroundColor Green
    } catch {
        Write-Host "Failed to update execution policy. You may need to run as Administrator." -ForegroundColor Red
        Write-Host "Alternatively, run: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor Yellow
        exit 1
    }
}

# Activate virtual environment
Write-Host "`nActivating virtual environment '$VenvName'..." -ForegroundColor Green
try {
    & $activateScript
    Write-Host "Virtual environment activated successfully!" -ForegroundColor Green
    
    # Get Python version info
    $pythonVersion = & python --version 2>&1
    Write-Host "Python version: $pythonVersion" -ForegroundColor Cyan
    Write-Host "Python path: $(python -c 'import sys; print(sys.executable)')" -ForegroundColor Cyan
    Write-Host "`nTo deactivate, run this script again or type: deactivate" -ForegroundColor Yellow
} catch {
    Write-Host "Failed to activate virtual environment: $_" -ForegroundColor Red
    exit 1
}

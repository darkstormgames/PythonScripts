# Create Python Virtual Environment with Version Selector
# Usage: .\create-python-venv.ps1 [venv_name]

param(
  [string]$VenvName = "venv"
)

# Function to discover Python installations
function Find-PythonInstallations {
  $pythonInstalls = @{}
  $index = 1

  # Define search patterns
  $searchPaths = @(
    "C:\Python*\python.exe",
    "C:\Python\Python*\python.exe",
    "C:\Program Files\Python*\python.exe",
    "C:\Program Files (x86)\Python*\python.exe",
    "C:\Program Files\Python\Python*\python.exe",
    "C:\Program Files (x86)\Python\Python*\python.exe"
  )

  # Search in predefined paths
  foreach ($pattern in $searchPaths) {
    $found = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue
    foreach ($python in $found) {
      if (Test-Path $python.FullName) {
        # Get version info
        $versionInfo = & $python.FullName --version 2>&1
        if ($versionInfo -match "Python (\d+\.\d+\.\d+)") {
          $version = $Matches[1]
          $majorMinor = $version -replace '(\d+\.\d+).*', '$1'
                    
          # Check if we already have this version
          $duplicate = $false
          foreach ($existing in $pythonInstalls.Values) {
            if ($existing.Version -eq $version -and $existing.Path -eq $python.FullName) {
              $duplicate = $true
              break
            }
          }
                    
          if (-not $duplicate) {
            $pythonInstalls[$index.ToString()] = @{
              "Path"         = $python.FullName
              "Version"      = "Python $version"
              "ShortVersion" = $majorMinor
            }
            $index++
          }
        }
      }
    }
  }
    
  # Search for Windows Store Python installations
  try {
    $appxPythons = Get-Command python*.exe -ErrorAction SilentlyContinue | 
    Where-Object { $_.Source -like "*WindowsApps*" }
        
    foreach ($appxPython in $appxPythons) {
      if (Test-Path $appxPython.Source) {
        $versionInfo = & $appxPython.Source --version 2>&1
        if ($versionInfo -match "Python (\d+\.\d+\.\d+)") {
          $version = $Matches[1]
          $majorMinor = $version -replace '(\d+\.\d+).*', '$1'
                    
          # Check if we already have this version
          $duplicate = $false
          foreach ($existing in $pythonInstalls.Values) {
            if ($existing.Version -eq "Python $version" -and $existing.Path -eq $appxPython.Source) {
              $duplicate = $true
              break
            }
          }
                    
          if (-not $duplicate) {
            $pythonInstalls[$index.ToString()] = @{
              "Path"         = $appxPython.Source
              "Version"      = "Python $version (Windows Store)"
              "ShortVersion" = $majorMinor
            }
            $index++
          }
        }
      }
    }
  }
  catch {
    # Silently continue if Windows Store search fails
  }
    
  # Sort by version number
  $sorted = @{}
  $sortedIndex = 1
  $sortedList = $pythonInstalls.Values | Sort-Object { [version]($_.ShortVersion + ".0") }
  foreach ($item in $sortedList) {
    $sorted[$sortedIndex.ToString()] = $item
    $sortedIndex++
  }
    
  return $sorted
}

# Discover Python installations
Write-Host "Searching for Python installations..." -ForegroundColor Yellow
$PythonPaths = Find-PythonInstallations

if ($PythonPaths.Count -eq 0) {
  Write-Host "No Python installations found!" -ForegroundColor Red
  exit 1
}

# Display available Python versions
Write-Host "`nAvailable Python versions:" -ForegroundColor Green
# Use ordered iteration to ensure proper display order
for ($i = 1; $i -le $PythonPaths.Count; $i++) {
  $key = $i.ToString()
  $python = $PythonPaths[$key]
  Write-Host "  $key. $($python.Version)" -ForegroundColor Cyan
  Write-Host "     Path: $($python.Path)" -ForegroundColor DarkGray
}

# Get user selection
do {
  $selection = Read-Host "`nSelect Python version (1-$($PythonPaths.Count))"
} while ($selection -notin $PythonPaths.Keys)

$selectedPython = $PythonPaths[$selection]

# Check if virtual environment already exists
if (Test-Path $VenvName) {
  Write-Host "Virtual environment '$VenvName' already exists!" -ForegroundColor Yellow
  $overwrite = Read-Host "Do you want to overwrite it? (y/N)"
  if ($overwrite -eq "y" -or $overwrite -eq "Y") {
    Remove-Item -Recurse -Force $VenvName
    Write-Host "Removed existing virtual environment." -ForegroundColor Yellow
  }
  else {
    Write-Host "Operation cancelled." -ForegroundColor Red
    exit 0
  }
}

# Create virtual environment
Write-Host "`nCreating virtual environment '$VenvName' with $($selectedPython.Version)..." -ForegroundColor Green
& $selectedPython.Path -m venv $VenvName

if ($LASTEXITCODE -eq 0) {
  Write-Host "Virtual environment '$VenvName' created successfully!" -ForegroundColor Green
  
  # Ask if user wants to activate the virtual environment
  $activate = Read-Host "`nDo you want to activate the virtual environment now? (Y/n)"
  if ($activate -eq "" -or $activate -eq "y" -or $activate -eq "Y") {
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
        Write-Host "To activate manually, run: .\enter-python-venv.ps1" -ForegroundColor Cyan
        exit 1
      }
    }

    # Activate virtual environment
    Write-Host "Activating virtual environment '$VenvName'..." -ForegroundColor Green
    try {
      & $activateScript
      Write-Host "Virtual environment activated successfully!" -ForegroundColor Green
      Write-Host "Python path: $(python -c 'import sys; print(sys.executable)')" -ForegroundColor Cyan
      Write-Host "To deactivate, type: deactivate" -ForegroundColor Yellow
    } catch {
      Write-Host "Failed to activate virtual environment: $_" -ForegroundColor Red
      Write-Host "To activate manually, run: .\enter-python-venv.ps1" -ForegroundColor Cyan
      exit 1
    }
  } else {
    Write-Host "To activate it later, run: .\enter-python-venv.ps1" -ForegroundColor Cyan
  }
}
else {
  Write-Host "Failed to create virtual environment!" -ForegroundColor Red
  exit 1
}

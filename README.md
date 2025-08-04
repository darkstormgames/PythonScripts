# Python Virtual Environment Management Scripts

A comprehensive collection of cross-platform scripts for creating and managing Python virtual environments with intelligent Python version selection.

## Overview

This repository contains scripts for Windows (Batch and PowerShell) and Unix-like systems (Linux/macOS) that simplify the process of:
- **Creating Python virtual environments** with automatic Python version discovery and selection
- **Toggling (activating/deactivating) virtual environments** with smart detection of existing environments

## Features

- 🔍 **Automatic Python Discovery**: Scans your system for all available Python installations
- 🎯 **Version Selection**: Choose from multiple Python versions installed on your system
- 🚀 **Smart Activation**: Automatically activate environments after creation
- 🔄 **Toggle Functionality**: Single command to enter or exit virtual environments
- 🛡️ **Virtual Environment Detection**: Automatically excludes existing virtual environments from Python discovery
- 📁 **Multiple Environment Support**: Manage multiple virtual environments in the same directory
- 🖥️ **Cross-Platform**: Works on Windows, Linux, and macOS

## Scripts Overview

### Creation Scripts
- **`create-python-venv.bat`** - Windows Batch script
- **`create-python-venv.ps1`** - Windows PowerShell script
- **`create-python-venv.sh`** - Linux/macOS Bash script

### Toggle Scripts
- **`toggle-python-venv.bat`** - Windows Batch script
- **`toggle-python-venv.ps1`** - Windows PowerShell script
- **`toggle-python-venv.sh`** - Linux/macOS Bash script

## Installation

1. Clone or download this repository
2. Make scripts executable (Linux/macOS only):
   ```bash
   chmod +x create-python-venv.sh toggle-python-venv.sh
   ```

## Usage

### Creating Virtual Environments

#### Windows (Command Prompt)
```batch
REM Create a virtual environment named 'venv' (default)
create-python-venv.bat

REM Create a virtual environment with a custom name
create-python-venv.bat myproject-env
```

#### Windows (PowerShell)
```powershell
# Create a virtual environment named 'venv' (default)
.\create-python-venv.ps1

# Create a virtual environment with a custom name
.\create-python-venv.ps1 -VenvName myproject-env

# If you encounter execution policy issues:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Linux/macOS
```bash
# Create a virtual environment named 'venv' (default)
./create-python-venv.sh

# Create a virtual environment with a custom name
./create-python-venv.sh myproject-env

# For automatic activation after creation:
source create-python-venv.sh myproject-env
```

### Toggling Virtual Environments

#### Windows (Command Prompt)
```batch
REM Activate/deactivate a virtual environment
toggle-python-venv.bat

REM Activate a specific virtual environment
toggle-python-venv.bat myproject-env
```

#### Windows (PowerShell)
```powershell
# Activate/deactivate a virtual environment
.\toggle-python-venv.ps1

# Activate a specific virtual environment
.\toggle-python-venv.ps1 -VenvName myproject-env
```

#### Linux/macOS
```bash
# Show activation instructions or deactivate if active
./toggle-python-venv.sh

# For automatic activation:
source toggle-python-venv.sh

# Activate a specific virtual environment
source toggle-python-venv.sh myproject-env
```

## Script Behavior

### Creation Scripts

1. **Python Discovery**:
   - Searches common installation paths
   - Checks PATH environment variable
   - Finds Python installations from package managers
   - Detects Windows Store Python (Windows)
   - Supports pyenv installations (Linux/macOS)

2. **Version Selection**:
   - Displays all found Python versions with their paths
   - Allows selection via numbered menu
   - Shows full version information (e.g., Python 3.12.0)

3. **Environment Creation**:
   - Creates virtual environment using selected Python version
   - Offers to overwrite existing environments
   - Optionally activates the environment immediately

### Toggle Scripts

1. **Environment Detection**:
   - Checks if currently in a virtual environment
   - Scans current directory for existing virtual environments
   - Validates environment structure

2. **Smart Selection**:
   - Auto-selects if only one environment exists
   - Provides numbered menu for multiple environments
   - Remembers your choice when specified

3. **Activation/Deactivation**:
   - Offers to deactivate if already in an environment
   - Activates selected environment with proper shell integration
   - Shows current Python version and path after activation

## Examples

### Example 1: Basic Python Project Setup
```bash
# Navigate to your project directory
cd /path/to/myproject

# Create a virtual environment with Python 3.12
./create-python-venv.sh project-env
# Select Python 3.12 from the menu

# Activate the environment
source toggle-python-venv.sh project-env

# Install dependencies
pip install -r requirements.txt

# Deactivate when done
deactivate
```

### Example 2: Multiple Environments in One Directory
```powershell
# Create environments for different Python versions
.\create-python-venv.ps1 -VenvName py39-env
# Select Python 3.9

.\create-python-venv.ps1 -VenvName py312-env
# Select Python 3.12

# Toggle between environments
.\toggle-python-venv.ps1
# Select from menu: 1) py39-env  2) py312-env
```

### Example 3: Quick Environment Toggle
```batch
REM First time - creates and activates
create-python-venv.bat

REM Later - quickly enter the environment
toggle-python-venv.bat

REM Exit the environment
toggle-python-venv.bat
```

## Platform-Specific Notes

### Windows

- **Execution Policy**: PowerShell scripts may require setting execution policy:
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```
- **Path Separators**: Scripts handle both forward and backward slashes
- **Windows Store Python**: Automatically detected and labeled

### Linux/macOS

- **Source vs Execute**: Use `source` for automatic activation:
  ```bash
  source create-python-venv.sh  # Activates immediately
  ./create-python-venv.sh       # Shows activation instructions
  ```
- **Shell Support**: Works with bash and zsh
- **Hidden Directories**: Toggle scripts also detect hidden virtual environments (e.g., `.venv`)

## Troubleshooting

### "No Python installations found"
- Ensure Python is installed and in your PATH
- Try running `python --version` or `python3 --version`
- Check installation guides for your platform

### "Cannot activate virtual environment"
- **Windows**: Check execution policy for PowerShell
- **Linux/macOS**: Use `source` instead of `./` for activation
- Ensure the virtual environment was created successfully

### "Script not found" or "Permission denied"
- **Windows**: Ensure you're in the correct directory
- **Linux/macOS**: Make scripts executable: `chmod +x *.sh`

### Virtual environment not detected by toggle script
- Ensure the environment has standard structure (`Scripts` or `bin` directory)
- Check for `pyvenv.cfg` file in the environment root
- Verify the environment was created with standard `venv` module

## Best Practices

1. **Naming Conventions**: Use descriptive names for your environments (e.g., `projectname-env`, `django-py39`)
2. **Python Versions**: Test your project with the specific Python version it will run on in production
3. **Requirements File**: Always maintain a `requirements.txt` file:
   ```bash
   pip freeze > requirements.txt
   ```
4. **Git Ignore**: Add virtual environments to `.gitignore`:
   ```
   venv/
   *-env/
   .venv/
   ```

## Advanced Usage

### Automation with Scripts

You can chain these scripts with your project setup:

```batch
REM Windows - setup.bat
@echo off
call create-python-venv.bat project-env
call project-env\Scripts\activate.bat
pip install -r requirements.txt
python setup.py develop
```

```bash
#!/bin/bash
# Linux/macOS - setup.sh
source create-python-venv.sh project-env
pip install -r requirements.txt
python setup.py develop
```

### Integration with IDEs

Most IDEs can detect virtual environments created by these scripts:
- **VS Code**: Select interpreter from `venv/Scripts/python.exe` or `venv/bin/python`
- **PyCharm**: Configure project interpreter to point to the virtual environment
- **Sublime Text**: Use virtualenv package to auto-detect environments

## Contributing

Feel free to submit issues, fork the repository, and create pull requests for any improvements.

## License

These scripts are provided as-is for educational and development purposes. Feel free to modify and distribute as needed.

---

**Quick Reference Card**

| Task | Windows (CMD) | Windows (PS) | Linux/macOS |
|------|--------------|--------------|-------------|
| Create venv | `create-python-venv.bat` | `.\create-python-venv.ps1` | `./create-python-venv.sh` |
| Create named | `create-python-venv.bat myenv` | `.\create-python-venv.ps1 -VenvName myenv` | `./create-python-venv.sh myenv` |
| Toggle venv | `toggle-python-venv.bat` | `.\toggle-python-venv.ps1` | `source toggle-python-venv.sh` |
| Deactivate | `deactivate` | `deactivate` | `deactivate` |

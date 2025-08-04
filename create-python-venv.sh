#!/bin/bash
# filepath: p:\Active\GFN_Python\create-python-venv.sh

# Create Python Virtual Environment with Version Selector
# Usage: ./create-python-venv.sh [venv_name]
#    or: source create-python-venv.sh [venv_name]

# Check if script is being sourced
SOURCED=0
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    SOURCED=1
fi

VENV_NAME="${1:-venv}"

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Searching for Python installations...${NC}"
echo

# Array to store Python installations
declare -A python_paths
declare -A python_versions
index=1

# Function to check if a path is a virtual environment
is_venv() {
    local path="$1"
    local dir=$(dirname "$path")
    
    # Check for pyvenv.cfg in parent directories
    [[ -f "$dir/pyvenv.cfg" ]] && return 0
    [[ -f "$dir/../pyvenv.cfg" ]] && return 0
    [[ -f "$dir/../../pyvenv.cfg" ]] && return 0
    
    # Check if path contains common venv directory names
    [[ "$path" =~ (venv|\.venv|env|virtualenv|\.virtualenvs) ]] && return 0
    
    return 1
}

# Function to add Python installation to our list
add_python() {
    local python_path="$1"
    
    # Skip if doesn't exist or is not executable
    [[ ! -x "$python_path" ]] && return
    
    # Skip if it's a virtual environment
    is_venv "$python_path" && return
    
    # Get version info
    local version_string
    version_string=$("$python_path" --version 2>&1)
    
    # Check if it's actually Python
    if [[ ! "$version_string" =~ Python\ [0-9]+\.[0-9]+\.[0-9]+ ]]; then
        return
    fi
    
    # Check if we already have this exact path
    for existing_path in "${python_paths[@]}"; do
        [[ "$existing_path" == "$python_path" ]] && return
    done
    
    # Add to our lists
    python_paths[$index]="$python_path"
    python_versions[$index]="$version_string"
    ((index++))
}

# Search in common system paths
for python_cmd in python3 python python3.{13,12,11,10,9,8,7} python2.7 python2; do
    # Check in PATH
    if command -v "$python_cmd" &> /dev/null; then
        python_path=$(command -v "$python_cmd")
        # Resolve symlinks
        python_path=$(readlink -f "$python_path" 2>/dev/null || echo "$python_path")
        add_python "$python_path"
    fi
done

# Search in common installation directories
search_dirs=(
    "/usr/bin"
    "/usr/local/bin"
    "/opt/python*/bin"
    "/opt/python/*/bin"
    "/usr/local/python*/bin"
    "$HOME/.pyenv/versions/*/bin"
    "$HOME/.local/bin"
    "$HOME/anaconda3/bin"
    "$HOME/miniconda3/bin"
    "/opt/anaconda3/bin"
    "/opt/miniconda3/bin"
    "/usr/local/opt/python*/bin"  # Homebrew on macOS
    "/opt/homebrew/opt/python*/bin"  # Homebrew on Apple Silicon
)

for dir_pattern in "${search_dirs[@]}"; do
    # Use find to search for python executables
    while IFS= read -r python_path; do
        add_python "$python_path"
    done < <(find $dir_pattern -maxdepth 1 -name "python*" -type f -executable 2>/dev/null || true)
done

# Check pyenv if installed
if command -v pyenv &> /dev/null; then
    while IFS= read -r version; do
        python_path="$HOME/.pyenv/versions/$version/bin/python"
        add_python "$python_path"
    done < <(pyenv versions --bare 2>/dev/null || true)
fi

# Check for Python from package managers
# Check apt-based systems
if command -v dpkg &> /dev/null; then
    while IFS= read -r package; do
        if [[ "$package" =~ python3\.[0-9]+ ]]; then
            python_cmd="${package%-*}"
            python_path="/usr/bin/$python_cmd"
            add_python "$python_path"
        fi
    done < <(dpkg -l | grep "^ii.*python3\.[0-9]" | awk '{print $2}' 2>/dev/null || true)
fi

if [[ ${#python_paths[@]} -eq 0 ]]; then
    echo -e "${RED}No Python installations found!${NC}"
    echo "Please install Python using your package manager:"
    echo "  Ubuntu/Debian: sudo apt install python3"
    echo "  Fedora/RHEL: sudo dnf install python3"
    echo "  Arch: sudo pacman -S python"
    echo "  macOS: brew install python3"
    exit 1
fi

# Sort by version number
sorted_indices=($(
    for i in "${!python_versions[@]}"; do
        echo "$i"
    done | sort -V -k2 -t' ' <(
        for i in "${!python_versions[@]}"; do
            echo "$i ${python_versions[$i]}"
        done
    ) | awk '{print $1}'
))

# Display available Python versions
echo -e "${GREEN}Available Python versions:${NC}"
echo
display_index=1
declare -A display_to_real
for i in "${sorted_indices[@]}"; do
    display_to_real[$display_index]=$i
    echo -e "  ${CYAN}$display_index.${NC} ${python_versions[$i]}"
    echo -e "     Path: ${python_paths[$i]}"
    echo
    ((display_index++))
done

# Get user selection
while true; do
    read -p "Select Python version (1-$((display_index-1))): " selection
    if [[ "$selection" =~ ^[0-9]+$ ]] && [[ -n "${display_to_real[$selection]}" ]]; then
        real_index="${display_to_real[$selection]}"
        selected_python="${python_paths[$real_index]}"
        selected_version="${python_versions[$real_index]}"
        break
    else
        echo -e "${RED}Invalid selection. Please try again.${NC}"
    fi
done

# Check if virtual environment already exists
if [[ -d "$VENV_NAME" ]]; then
    echo
    echo -e "${YELLOW}Virtual environment '$VENV_NAME' already exists!${NC}"
    read -p "Do you want to overwrite it? (y/N): " overwrite
    if [[ "$overwrite" =~ ^[Yy]$ ]]; then
        echo "Removing existing virtual environment..."
        rm -rf "$VENV_NAME"
    else
        echo "Operation cancelled."
        exit 0
    fi
fi

# Create virtual environment
echo
echo -e "${GREEN}Creating virtual environment '$VENV_NAME' with $selected_version...${NC}"
"$selected_python" -m venv "$VENV_NAME"

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}Virtual environment '$VENV_NAME' created successfully!${NC}"
    echo
    read -p "Do you want to activate the virtual environment now? (Y/n): " activate
    
    if [[ ! "$activate" =~ ^[Nn]$ ]]; then
        echo
        echo -e "${GREEN}Activating virtual environment '$VENV_NAME'...${NC}"
        
        # If script is sourced, we can activate directly
        if [[ $SOURCED -eq 1 ]]; then
            source "$VENV_NAME/bin/activate"
            echo -e "${GREEN}Virtual environment activated!${NC}"
            echo -e "Python path: ${CYAN}$(which python)${NC}"
            echo -e "To deactivate, type: ${CYAN}deactivate${NC}"
        else
            echo
            echo "To activate the virtual environment, run:"
            echo -e "${CYAN}source $VENV_NAME/bin/activate${NC}"
            echo
            echo -e "${YELLOW}Tip: Run this script with 'source' to auto-activate:${NC}"
            echo -e "${CYAN}source $(basename $0) $VENV_NAME${NC}"
            
            # If running in an interactive bash shell, offer to activate directly
            if [[ $- == *i* ]] && [[ -n "$BASH" ]]; then
                echo
                read -p "Would you like to activate it in a new shell? (Y/n): " new_shell
                if [[ ! "$new_shell" =~ ^[Nn]$ ]]; then
                    echo "Starting new shell with activated virtual environment..."
                    bash --rcfile <(echo ". ~/.bashrc; source $VENV_NAME/bin/activate")
                fi
            fi
        fi
    else
        echo
        echo "To activate it later, run:"
        echo -e "${CYAN}source $VENV_NAME/bin/activate${NC}"
    fi
else
    echo -e "${RED}Failed to create virtual environment!${NC}"
    exit 1
fi
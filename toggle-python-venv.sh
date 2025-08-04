#!/bin/bash
# filepath: p:\Active\GFN_Python\toggle-python-venv.sh

# Toggle (Enter/Exit) Python Virtual Environment
# Usage: ./toggle-python-venv.sh [venv_name]
#    or: source toggle-python-venv.sh [venv_name]

# Check if script is being sourced
SOURCED=0
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    SOURCED=1
fi

VENV_NAME="${1:-}"

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if we're currently in a virtual environment
if [[ -n "$VIRTUAL_ENV" ]]; then
    echo -e "${CYAN}Currently in virtual environment: $VIRTUAL_ENV${NC}"
    read -p "Do you want to deactivate it? (Y/n): " exit_venv
    
    if [[ ! "$exit_venv" =~ ^[Nn]$ ]]; then
        if [[ $SOURCED -eq 1 ]]; then
            deactivate
            echo -e "${GREEN}Virtual environment deactivated!${NC}"
            return 0 2>/dev/null || exit 0
        else
            echo -e "${YELLOW}To deactivate the virtual environment, run:${NC}"
            echo -e "${CYAN}deactivate${NC}"
            echo
            echo "Note: The deactivate command must be run in your current shell."
            echo "Copy and paste the command above to deactivate."
            exit 0
        fi
    fi
fi

# Find all virtual environments in current directory
declare -a venvs
declare -A venv_paths

index=1
for dir in */; do
    dir="${dir%/}"  # Remove trailing slash
    if [[ -f "$dir/bin/activate" ]] && [[ -f "$dir/pyvenv.cfg" ]]; then
        venvs+=("$dir")
        venv_paths[$index]="$dir"
        ((index++))
    fi
done

# Also check hidden directories
for dir in .*/; do
    dir="${dir%/}"  # Remove trailing slash
    # Skip . and ..
    [[ "$dir" == "." || "$dir" == ".." ]] && continue
    
    if [[ -f "$dir/bin/activate" ]] && [[ -f "$dir/pyvenv.cfg" ]]; then
        venvs+=("$dir")
        venv_paths[$index]="$dir"
        ((index++))
    fi
done

# Handle no venvs found
if [[ ${#venvs[@]} -eq 0 ]]; then
    echo -e "${RED}No virtual environments found in current directory!${NC}"
    echo -e "To create one, run: ${CYAN}./create-python-venv.sh${NC}"
    exit 1
fi

# If VENV_NAME not provided and venvs exist, let user select
if [[ -z "$VENV_NAME" ]]; then
    if [[ ${#venvs[@]} -eq 1 ]]; then
        VENV_NAME="${venvs[0]}"
        echo -e "${GREEN}Found virtual environment: $VENV_NAME${NC}"
    else
        echo -e "${GREEN}Multiple virtual environments found:${NC}"
        echo
        for i in "${!venv_paths[@]}"; do
            echo -e "  ${CYAN}$i.${NC} ${venv_paths[$i]}"
        done
        echo
        
        while true; do
            read -p "Select virtual environment (1-$((${#venv_paths[@]}))): " selection
            
            if [[ "$selection" =~ ^[0-9]+$ ]] && [[ -n "${venv_paths[$selection]}" ]]; then
                VENV_NAME="${venv_paths[$selection]}"
                break
            else
                echo -e "${RED}Invalid selection. Please try again.${NC}"
            fi
        done
    fi
fi

# Check if specified virtual environment exists
if [[ ! -d "$VENV_NAME" ]]; then
    echo -e "${RED}Virtual environment '$VENV_NAME' not found!${NC}"
    if [[ ${#venvs[@]} -gt 0 ]]; then
        echo -e "${YELLOW}Available virtual environments:${NC}"
        for venv in "${venvs[@]}"; do
            echo -e "  - ${CYAN}$venv${NC}"
        done
    fi
    exit 1
fi

# Check if activation script exists
if [[ ! -f "$VENV_NAME/bin/activate" ]]; then
    echo -e "${RED}Activation script not found at: $VENV_NAME/bin/activate${NC}"
    echo -e "${RED}This doesn't appear to be a valid Python virtual environment.${NC}"
    exit 1
fi

# Get Python version from the venv
if [[ -x "$VENV_NAME/bin/python" ]]; then
    python_version=$("$VENV_NAME/bin/python" --version 2>&1)
else
    python_version="Unknown"
fi

# Provide activation instructions
echo
if [[ $SOURCED -eq 1 ]]; then
    # We can activate directly when sourced
    source "$VENV_NAME/bin/activate"
    echo -e "${GREEN}Virtual environment '$VENV_NAME' activated!${NC}"
    echo -e "Python version: ${CYAN}$python_version${NC}"
    echo -e "Python path: ${CYAN}$(which python)${NC}"
    echo -e "To deactivate, type: ${CYAN}deactivate${NC}"
else
    echo -e "${GREEN}To activate virtual environment '$VENV_NAME', run:${NC}"
    echo -e "${CYAN}source $VENV_NAME/bin/activate${NC}"
    echo
    echo -e "Python version in venv: ${CYAN}$python_version${NC}"
    echo
    echo -e "${YELLOW}Tip: Run this script with 'source' to auto-activate:${NC}"
    echo -e "${CYAN}source $(basename $0) $VENV_NAME${NC}"
    
    # If running in an interactive bash shell, offer to open new shell
    if [[ $- == *i* ]] && [[ -n "$BASH" ]]; then
        echo
        read -p "Would you like to open a new shell with this environment activated? (Y/n): " new_shell
        if [[ ! "$new_shell" =~ ^[Nn]$ ]]; then
            echo -e "${GREEN}Starting new shell with activated virtual environment...${NC}"
            echo -e "To exit the virtual environment, type: ${CYAN}exit${NC} or ${CYAN}deactivate${NC}"
            bash --rcfile <(echo ". ~/.bashrc; source $VENV_NAME/bin/activate; echo -e '${GREEN}Virtual environment activated!${NC}'; echo -e 'Python path: ${CYAN}'\$(which python)'${NC}'")
        fi
    fi
fi

# For zsh users
if [[ -n "$ZSH_VERSION" ]]; then
    echo
    echo -e "${YELLOW}For zsh users:${NC}"
    echo -e "You can also activate using: ${CYAN}source $VENV_NAME/bin/activate${NC}"
fi

if [[ $SOURCED -eq 0 ]]; then
    echo
    echo -e "To deactivate later, type: ${CYAN}deactivate${NC}"
fi
#!/bin/bash

# Helm Schema Generator - Linux/macOS Installation Script
# This script adds the helmschema alias to your shell profile

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_PATH="$SCRIPT_DIR/generate-values-schema.sh"

# Check if script exists
if [ ! -f "$SCRIPT_PATH" ]; then
    echo -e "${RED}✗ Error: generate-values-schema.sh not found in $SCRIPT_DIR${NC}"
    exit 1
fi

# Make script executable
chmod +x "$SCRIPT_PATH"

# Detect shell and profile file
if [ -n "$ZSH_VERSION" ]; then
    SHELL_NAME="zsh"
    PROFILE_FILE="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_NAME="bash"
    if [ -f "$HOME/.bashrc" ]; then
        PROFILE_FILE="$HOME/.bashrc"
    else
        PROFILE_FILE="$HOME/.bash_profile"
    fi
else
    SHELL_NAME="unknown"
    PROFILE_FILE="$HOME/.profile"
fi

echo -e "${CYAN}Detected shell: $SHELL_NAME${NC}"
echo -e "${CYAN}Profile file: $PROFILE_FILE${NC}"
echo ""

# Create profile file if it doesn't exist
if [ ! -f "$PROFILE_FILE" ]; then
    echo -e "${CYAN}Creating profile file: $PROFILE_FILE${NC}"
    touch "$PROFILE_FILE"
fi

# Check if alias already exists
if grep -q "function helmschema" "$PROFILE_FILE" 2>/dev/null || grep -q "alias helmschema" "$PROFILE_FILE" 2>/dev/null; then
    echo -e "${YELLOW}⚠ helmschema function/alias already exists in your profile${NC}"
    read -p "Do you want to update it? (y/N): " choice
    if [ "$choice" != "y" ] && [ "$choice" != "Y" ]; then
        echo -e "${YELLOW}Installation cancelled${NC}"
        exit 0
    fi

    # Remove old function/alias
    sed -i.bak '/# Helm Schema Generator/,/^}/d' "$PROFILE_FILE" 2>/dev/null || true
    sed -i.bak '/alias helmschema/d' "$PROFILE_FILE" 2>/dev/null || true
fi

# Add function to profile
cat >> "$PROFILE_FILE" << EOF

# Helm Schema Generator
helmschema() {
    local definitions_file=""
    local force_flag=""

    # Parse arguments
    while [[ \$# -gt 0 ]]; do
        case \$1 in
            -f|--force)
                force_flag="-f"
                shift
                ;;
            -h|--help)
                "$SCRIPT_PATH" --help
                return
                ;;
            *)
                if [ -z "\$definitions_file" ]; then
                    definitions_file="\$1"
                fi
                shift
                ;;
        esac
    done

    # Call the script
    if [ -n "\$definitions_file" ]; then
        "$SCRIPT_PATH" -d "\$definitions_file" \$force_flag
    else
        "$SCRIPT_PATH" \$force_flag
    fi
}
EOF

echo ""
echo -e "${GREEN}✓ Installation completed!${NC}"
echo ""
echo -e "${CYAN}The 'helmschema' function has been added to your shell profile${NC}"
echo -e "${GRAY}Profile location: $PROFILE_FILE${NC}"
echo ""
echo -e "${YELLOW}Usage:${NC}"
echo -e "  ${WHITE}helmschema${NC}                    # Generate schema from values.yaml"
echo -e "  ${WHITE}helmschema definitions.json${NC}   # Generate with custom definitions"
echo -e "  ${WHITE}helmschema --force${NC}            # Force overwrite without prompting"
echo ""
echo -e "${CYAN}To start using it now, run:${NC}"
echo -e "  ${WHITE}source $PROFILE_FILE${NC}"
echo ""
echo -e "${CYAN}Or restart your terminal session${NC}"

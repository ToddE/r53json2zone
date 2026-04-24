#!/usr/bin/env bash
#
# Install script for r53json2zone
# Usage: curl -sSL https://raw.githubusercontent.com/ToddE/r53json2zone/main/install.sh | bash

# --- COLOR DEFINITIONS ---
GREEN='\033[1;32m'
ORANGE='\033[1;38;5;208m'
BOLD='\033[1m'
NC='\033[0m'

REPO_URL="https://raw.githubusercontent.com/ToddE/r53json2zone/main/r53json2zone"
INSTALL_DIR="$HOME/.local/bin"
BINARY_NAME="r53json2zone"

echo -e "${BOLD}Installing $BINARY_NAME...${NC}"

# 1. Ensure the install directory exists
if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "Creating $INSTALL_DIR..."
    mkdir -p "$INSTALL_DIR"
fi

# 2. Download the script
if curl -sSL "$REPO_URL" -o "$INSTALL_DIR/$BINARY_NAME"; then
    chmod +x "$INSTALL_DIR/$BINARY_NAME"
    echo -e "${GREEN}✔${NC} ${BOLD}Download complete:${NC} $INSTALL_DIR/$BINARY_NAME"
else
    echo -e "${ORANGE}✖ Error: Failed to download script from GitHub.${NC}"
    exit 1
fi

# 3. Verify PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo -e "\n${ORANGE}${BOLD}⚠ PATH WARNING:${NC}"
    echo -e "The directory $INSTALL_DIR is NOT in your PATH."
    echo -e "Add this to your .bashrc or .zshrc:"
    echo -e "${BOLD}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
else
    echo -e "${GREEN}✔${NC} Installation successful! You can now run '${BOLD}$BINARY_NAME${NC}' from any directory."
fi
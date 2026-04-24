#!/usr/bin/env bash
# Version: 20260424a
# Install script for r53json2zone
# Usage: curl -sSL https://raw.githubusercontent.com/ToddE/r53json2zone/main/install.sh | bash

# --- COLOR DEFINITIONS ---
GREEN='\033[1;32m'
ORANGE='\033[1;38;5;208m'
BOLD='\033[1m'
NC='\033[0m'

REPO_URL="https://raw.githubusercontent.com/ToddE/r53json2zone/main/r53json2zone"
SUMS_URL="https://raw.githubusercontent.com/ToddE/r53json2zone/main/SHA256SUMS"
INSTALL_DIR="$HOME/.local/bin"
BINARY_NAME="r53json2zone"

echo -e "${BOLD}Installing $BINARY_NAME...${NC}"

# 0. Check for required tools
if ! command -v curl &>/dev/null; then
    echo -e "${ORANGE}✖ Error: curl is required but not installed.${NC}"
    echo -ne "Would you like to attempt to install curl now? (y/n): "
    read -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Detect OS and install curl
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$ID
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            OS="darwin"
        else
            echo -e "${ORANGE}Unable to detect OS. Please install curl manually.${NC}"
            exit 1
        fi

        case "$OS" in
            ubuntu|debian|raspbian|armbian|linuxmint)
                sudo apt update && sudo apt install -y curl
                ;;
            centos|rhel|fedora)
                sudo dnf install -y curl || sudo yum install -y curl
                ;;
            arch)
                sudo pacman -S --noconfirm curl
                ;;
            darwin)
                if command -v brew &>/dev/null; then
                    brew install curl
                else
                    echo -e "${ORANGE}Homebrew not found. Install curl from https://brew.sh${NC}"
                    exit 1
                fi
                ;;
            *)
                echo -e "${ORANGE}Unsupported distribution. Please install curl manually.${NC}"
                exit 1
                ;;
        esac

        if ! command -v curl &>/dev/null; then
            echo -e "${ORANGE}Failed to install curl. Please install it manually.${NC}"
            exit 1
        fi
    else
        echo -e "${ORANGE}curl is required to continue.${NC}"
        exit 1
    fi
fi

# 1. Ensure the install directory exists
if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "Creating $INSTALL_DIR..."
    if ! mkdir -p "$INSTALL_DIR"; then
        echo -e "${ORANGE}✖ Error: Failed to create $INSTALL_DIR${NC}"
        echo -e "Check that you have write permissions to $(dirname "$INSTALL_DIR")"
        exit 1
    fi
fi

# 2. Check if already installed and offer backup
if [ -f "$INSTALL_DIR/$BINARY_NAME" ]; then
    echo -e "${ORANGE}${BOLD}⚠ Update detected:${NC}"
    echo -e "$BINARY_NAME is already installed at $INSTALL_DIR/$BINARY_NAME"
    echo -ne "Create a backup before updating? (y/n): "
    read -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if cp "$INSTALL_DIR/$BINARY_NAME" "$INSTALL_DIR/$BINARY_NAME.bak"; then
            echo -e "${GREEN}✔${NC} Backup created: ${BOLD}$INSTALL_DIR/$BINARY_NAME.bak${NC}"
        else
            echo -e "${ORANGE}⚠ Warning: Failed to create backup.${NC}"
        fi
    fi
fi

# 3. Download the script
if ! curl -sSL "$REPO_URL" -o "$INSTALL_DIR/$BINARY_NAME"; then
    echo -e "${ORANGE}✖ Error: Failed to download script from GitHub.${NC}"
    echo -e "Check your internet connection and try again."
    exit 1
fi

# 4. Validate downloaded file
if [ ! -s "$INSTALL_DIR/$BINARY_NAME" ]; then
    echo -e "${ORANGE}✖ Error: Downloaded file is empty or missing.${NC}"
    rm -f "$INSTALL_DIR/$BINARY_NAME"
    exit 1
fi

if ! head -1 "$INSTALL_DIR/$BINARY_NAME" | grep -q "^#!/.*bash"; then
    echo -e "${ORANGE}✖ Error: Downloaded file is not a valid bash script.${NC}"
    echo -e "The file may be corrupted or the URL is incorrect."
    rm -f "$INSTALL_DIR/$BINARY_NAME"
    exit 1
fi

# 5. Download and validate against SHA256SUMS
echo -e "Validating file integrity..."
TEMP_SUMS=$(mktemp)
if ! curl -sSL "$SUMS_URL" -o "$TEMP_SUMS"; then
    echo -e "${ORANGE}⚠ Warning: Could not download SHA256SUMS for validation.${NC}"
    rm -f "$TEMP_SUMS"
else
    # Extract expected hash for r53json2zone (hash is first field)
    SUMS_LINE=$(grep " $BINARY_NAME$" "$TEMP_SUMS")
    EXPECTED_HASH=$(echo "$SUMS_LINE" | awk '{print $1}')

    if [ -z "$EXPECTED_HASH" ]; then
        echo -e "${ORANGE}⚠ Warning: Could not find hash in SHA256SUMS.${NC}"
        rm -f "$TEMP_SUMS"
    else
        # Compute actual hash
        if command -v sha256sum &>/dev/null; then
            ACTUAL_HASH=$(sha256sum "$INSTALL_DIR/$BINARY_NAME" | awk '{print $1}')
        elif command -v shasum &>/dev/null; then
            ACTUAL_HASH=$(shasum -a 256 "$INSTALL_DIR/$BINARY_NAME" | awk '{print $1}')
        else
            echo -e "${ORANGE}⚠ Warning: sha256sum/shasum not available. Skipping validation.${NC}"
            rm -f "$TEMP_SUMS"
            ACTUAL_HASH="$EXPECTED_HASH"
        fi

        # Validate
        if [ "$ACTUAL_HASH" = "$EXPECTED_HASH" ]; then
            echo -e "${GREEN}✔${NC} ${BOLD}File integrity verified${NC}"
        else
            echo -e "${ORANGE}✖ Error: File validation failed!${NC}"
            echo -e "Expected: $EXPECTED_HASH"
            echo -e "Got:      $ACTUAL_HASH"
            rm -f "$INSTALL_DIR/$BINARY_NAME" "$TEMP_SUMS"
            exit 1
        fi
    fi
    rm -f "$TEMP_SUMS"
fi

# 6. Make the script executable
if ! chmod +x "$INSTALL_DIR/$BINARY_NAME"; then
    echo -e "${ORANGE}✖ Error: Failed to make script executable.${NC}"
    echo -e "Check file permissions in $INSTALL_DIR"
    exit 1
fi

echo -e "${GREEN}✔${NC} ${BOLD}Download complete:${NC} $INSTALL_DIR/$BINARY_NAME"

# 7. Verify PATH configuration
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo -e "\n${ORANGE}${BOLD}⚠ PATH WARNING:${NC}"
    echo -e "The directory $INSTALL_DIR is NOT in your PATH."
    echo -e "Add this to your .bashrc or .zshrc:"
    echo -e "${BOLD}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
    echo -e "\nThen reload your shell and verify installation with:"
    echo -e "${BOLD}hash -r && $BINARY_NAME --help${NC}"
else
    # Verify the command is actually accessible
    # Note: hash -r clears the command cache so the shell rescans PATH
    hash -r 2>/dev/null
    if command -v "$BINARY_NAME" &>/dev/null; then
        echo -e "${GREEN}✔${NC} Installation successful! You can now run '${BOLD}$BINARY_NAME${NC}' from any directory."
    else
        echo -e "${ORANGE}⚠ Warning: $BINARY_NAME not immediately accessible in this shell.${NC}"
        echo -e "File location: $INSTALL_DIR/$BINARY_NAME"
        echo -e "In a new shell, run: ${BOLD}$BINARY_NAME --help${NC}"
    fi
fi
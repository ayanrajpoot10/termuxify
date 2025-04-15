#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

declare -A COLORS=(
    [RESET]="\033[0m"
    [BOLD]="\033[1m"
    [PRIMARY]="\033[38;5;68m"
    [ACCENT]="\033[38;5;75m"
    [SUCCESS]="\033[38;5;78m"
    [WARNING]="\033[38;5;221m"
    [ERROR]="\033[38;5;167m"
    [INFO]="\033[38;5;110m"
)

show_message() {
    echo -e "${COLORS[$1]}$2${COLORS[RESET]}"
}

REPO_URL="https://github.com/Ayanrajpoot10/termuxify.git"
TEMP_DIR="$(mktemp -d)"
SCRIPT_DIR="$PREFIX/share/termuxify"

cleanup() {
    rm -rf "$TEMP_DIR"
}

trap 'cleanup' EXIT
trap 'show_message ERROR "Installation failed"; cleanup; exit 1' ERR

command -v git >/dev/null 2>&1 || {
    show_message WARNING "Git is not installed"
    show_message INFO "Install git? (Y/n)"
    read -n 1 -s choice
    echo
    choice=${choice:-Y}
    if [[ ${choice^^} =~ ^[Y]$ ]]; then
        show_message INFO "Installing git..."
        pkg update -y
        pkg install -y git || {
            show_message ERROR "Failed to install git"
            exit 1
        }
    else
        show_message ERROR "Git is required to proceed"
        exit 1
    fi
}

[[ -d "/data/data/com.termux" ]] || { show_message ERROR "This script must be run in Termux"; exit 1; }

clear
printf "${COLORS[ACCENT]}${COLORS[BOLD]}"
printf "┌────────────────────────────────────┐\n"
printf "│         TermuXify Installer        │\n"
printf "└────────────────────────────────────┘\n"
printf "${COLORS[RESET]}\n"

show_message INFO "Installing TermuXify..."
git clone --depth=1 "$REPO_URL" "$TEMP_DIR"
mkdir -p "$SCRIPT_DIR" "$HOME/.termux" "$SCRIPT_DIR/"{colors,fonts}
cp -r "$TEMP_DIR"/* "$SCRIPT_DIR/"
ln -sf "$SCRIPT_DIR/termuxify.sh" "$PREFIX/bin/termuxify"
chmod +x "$PREFIX/bin/termuxify"

show_message SUCCESS "Installation complete!"
show_message PRIMARY "To run script type: termuxify"

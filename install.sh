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

trap 'show_message ERROR "Installation failed at line $LINENO with exit code $?"' ERR

[[ -d "/data/data/com.termux" ]] || { show_message ERROR "This script must be run in Termux"; exit 1; }

clear
printf "${COLORS[ACCENT]}${COLORS[BOLD]}"
printf "┌────────────────────────────────────┐\n"
printf "│         TermuXify Installer        │\n"
printf "└────────────────────────────────────┘\n"
printf "${COLORS[RESET]}\n"
show_message WARNING "Note: Manual installation is not recommended.\nConsider using the Debian package instead.\nSee README.md for details.\n"

SCRIPT_DIR="$PREFIX/share/termuxify"

show_message INFO "Installing TermuXify..."
mkdir -p "$SCRIPT_DIR" "$HOME/.termux" "$SCRIPT_DIR/"{colors,fonts}

cp -r . "$SCRIPT_DIR/"
ln -sf "$SCRIPT_DIR/termuxify.sh" "$PREFIX/bin/termuxify"
chmod +x "$PREFIX/bin/termuxify"

show_message SUCCESS "Installation complete!"
show_message PRIMARY "To run script type: termuxify"

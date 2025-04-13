#!/usr/bin/env bash

set -euo pipefail

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

trap 'show_message ERROR "Uninstallation failed at line $LINENO with exit code $?"' ERR

[[ -d "/data/data/com.termux" ]] || { show_message ERROR "This script must be run in Termux"; exit 1; }

clear
printf "${COLORS[ACCENT]}${COLORS[BOLD]}"
printf "┌────────────────────────────────────┐\n"
printf "│       TermuXify Uninstaller        │\n"
printf "└────────────────────────────────────┘\n"
printf "${COLORS[RESET]}\n"

SCRIPT_DIR="$PREFIX/share/termuxify"

show_message INFO "Uninstalling TermuXify..."

rm -f "$PREFIX/bin/termuxify"

rm -rf "$SCRIPT_DIR"

show_message SUCCESS "Uninstallation complete!"

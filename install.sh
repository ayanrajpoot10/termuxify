#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

RESET="\033[0m"
BOLD="\033[1m"
PRIMARY="\033[38;5;68m"
ACCENT="\033[38;5;75m"
SUCCESS="\033[38;5;78m"
WARNING="\033[38;5;221m"
ERROR="\033[38;5;167m"
INFO="\033[38;5;110m"

show_message() {
    local type=$1
    local msg=$2
    local color
    
    case $type in
        success) color=$SUCCESS ;;
        warning) color=$WARNING ;;
        error)   color=$ERROR ;;
        info)    color=$INFO ;;
    esac
    
    echo -e "${color}${msg}${RESET}"
}

show_success() { show_message success "$1"; }
show_warning() { show_message warning "$1"; }
show_error()   { show_message error "$1";   }
show_info()    { show_message info "$1";    }

show_banner() {
    clear
    printf "${ACCENT}${BOLD}"
    printf "┌────────────────────────────────────┐\n"
    printf "│         TermuXify Installer        │\n"
    printf "└────────────────────────────────────┘"
    printf "${RESET}\n\n"
    printf "${WARNING}Note: Manual installation is not recommended.\n"
    printf "Consider using the Debian package instead.\n"
    printf "See README.md for details.${RESET}\n\n"
}

trap 'handle_error $? $LINENO' ERR

handle_error() {
    local exit_code=$1
    local line_no=$2
    show_error "Installation failed at line ${line_no} with exit code ${exit_code}"
    exit 1
}

if [ ! -d "/data/data/com.termux" ]; then
    show_error "This script must be run in Termux"
    exit 1
fi

show_banner

TERMUX_HOME="/data/data/com.termux/files/home"
TERMUX_PREFIX="/data/data/com.termux/files/usr"
SCRIPT_DIR="$TERMUX_PREFIX/share/termuxify"
BIN_DIR="$TERMUX_PREFIX/bin"

show_info "Creating directory structure..."
mkdir -p "$SCRIPT_DIR" "$TERMUX_HOME/.termux"

show_info "Installing TermuXify core files..."
cp -r . "$SCRIPT_DIR/"

show_info "Setting up executable..."
ln -sf "$SCRIPT_DIR/termuxify.sh" "$BIN_DIR/termuxify"
chmod +x "$BIN_DIR/termuxify"

show_info "Installing color schemes..."
mkdir -p "$SCRIPT_DIR/colors"
cp -r colors/* "$SCRIPT_DIR/colors/"

show_info "Installing fonts..."
mkdir -p "$SCRIPT_DIR/fonts"
cp -r fonts/* "$SCRIPT_DIR/fonts/"

show_success "Installation complete!"
echo -e "${PRIMARY}${BOLD}To run script type: termuxify${RESET}"
echo -e "${WARNING}Note: For better integration, consider using the Debian package installation method.${RESET}"

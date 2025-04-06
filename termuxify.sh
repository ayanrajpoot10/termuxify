#!/bin/bash

readonly VERSION="0.1.0"
readonly AUTHOR="Ayan Rajpoot"
readonly GITHUB="https://github.com/Ayanrajpoot10/TermuXify"

set -euo pipefail
IFS=$'\n\t'

readonly PREFIX='/data/data/com.termux/files/usr'
readonly TERMUX_DIR="$HOME/.termux"
readonly SCRIPT_DIR="$(dirname "$(realpath "$0")")"
readonly COLORS_DIR="$PREFIX/share/termuxify/colors"
readonly FONTS_DIR="$PREFIX/share/termuxify/fonts"

readonly TERMUX_PROPERTIES="$TERMUX_DIR/termux.properties"
readonly COLORS_FILE="$TERMUX_DIR/colors.properties"
readonly CURRENT_THEME_FILE="$TERMUX_DIR/.current_theme"
readonly CURRENT_FONT_FILE="$TERMUX_DIR/.current_font"

show_message() {
    local type=$1
    local msg=$2
    local color
    
    case $type in
        success) color=$SUCCESS ;;
        warning) color=$WARNING ;;
        error)   color=$ERROR ;;
        info)    color=$INFO ;;
        header)  color=$HEADER ;;
        prompt)  color=$PROMPT ;;
    esac
    
    if [[ $type == "prompt" ]]; then
        echo -en "${LEFT_PADDING}${color}${BOLD}${msg}${RESET} "
    else
        echo -e "${LEFT_PADDING}${color}${msg}${RESET}"
    fi
}

show_success() { show_message success "$1"; }
show_warning() { show_message warning "$1"; }
show_error()   { show_message error "$1";   }
show_info()    { show_message info "$1";    }
show_header()  { show_message header "$1";  }
show_prompt()  { show_message prompt "$1";  }

trap 'handle_error $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "::%s" ${FUNCNAME[@]:-})' ERR

handle_error() {
    local exit_code=$1
    local line_no=$2
    local bash_lineno=$3
    local last_command=$4
    local func_trace=$5
    
    show_error "An error occurred during execution at line $line_no"
}

init_directories() {
    mkdir -p "$TERMUX_DIR" "$COLORS_DIR" "$FONTS_DIR" 2>/dev/null || \
    show_warning "Failed to create one or more directories"
}

backup_initial_properties() {
    local files=("$TERMUX_PROPERTIES" "$COLORS_FILE")
    for file in "${files[@]}"; do
        if [ -f "$file" ] && [ ! -f "${file}.backup" ]; then
            cp "$file" "${file}.backup"
        fi
    done
}

RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
ITALIC="\033[3m"

PRIMARY="\033[38;5;68m"
SECONDARY="\033[38;5;31m"
ACCENT="\033[38;5;75m"
TEXT="\033[38;5;252m"
MUTED="\033[38;5;244m"

SUCCESS="\033[38;5;78m"
WARNING="\033[38;5;221m"
ERROR="\033[38;5;167m"
INFO="\033[38;5;110m"

HEADER="\033[38;5;32m"
BORDER="\033[38;5;240m"
PROMPT="\033[38;5;39m"
HIGHLIGHT="\033[38;5;147m"

readonly LEFT_PADDING="   "

show_banner() {
    clear
    echo
    printf "${LEFT_PADDING}${ACCENT}${BOLD}"
    printf "┌────────────────────────────────────┐\n"
    printf "${LEFT_PADDING}│             TermuXify              │\n"
    printf "${LEFT_PADDING}└────────────────────────────────────┘"
    printf "${RESET}\n"
    printf "${LEFT_PADDING}${DIM} Terminal customization tool | v${VERSION}${RESET}\n\n"
}

show_header() {
    local msg=$1
    echo -e "${LEFT_PADDING}${HEADER}${msg}${RESET}"
}

show_bordered_header() {
    local msg=$1
    echo -e "${LEFT_PADDING}${BORDER}┌$(printf '─%.0s' {1..35})┐"
    echo -e "${LEFT_PADDING}${BORDER}│${HEADER}$(printf "%-35s" "  $msg")${BORDER}│"
    echo -e "${LEFT_PADDING}${BORDER}└$(printf '─%.0s' {1..35})┘${RESET}"
}

update_property() {
    local file="$1"
    local property="$2"
    local value="$3"

    touch "$file"
    
    if grep -q "^[#[:space:]]*${property}[[:space:]]*=.*$" "$file"; then
        sed -i -E "s/^[#[:space:]]*${property}[[:space:]]*=.*$/${property}=${value}/" "$file"
    else
        echo "${property}=${value}" >> "$file"
    fi
}

get_current_theme() {
    if [ -f "$TERMUX_DIR/.current_color" ]; then
        cat "$TERMUX_DIR/.current_color"
    else
        echo "default"
    fi
}

get_current_font() {
    if [ -f "$TERMUX_DIR/.current_font" ]; then
        cat "$TERMUX_DIR/.current_font"
    else
        echo "default"
    fi
}

get_shell_rc() {
    if [ -n "${ZSH_VERSION:-}" ]; then
        echo "$HOME/.zshrc"
    elif [ -n "${BASH_VERSION:-}" ]; then
        echo "$HOME/.bashrc"
    else
        echo ""
    fi
}

load_custom_font() {
    show_prompt "Enter path to font file:"
    read source
    
    if [ ! -f "$source" ]; then
        show_error "Font file not found!"
        return 1
    fi
    
    local font_name=$(basename "$source")
    cp "$source" "$FONTS_DIR/$font_name"
    show_success "Font loaded successfully!"
    return 0
}

load_custom_theme() {
    show_prompt "Enter path to theme file:"
    read source
    
    if [ ! -f "$source" ]; then
        show_error "Theme file not found!"
        return 1
    fi
    
    # Validate theme file format
    if ! grep -q "^color[0-9]\+=#[0-9A-Fa-f]\{6\}$\|^background=#[0-9A-Fa-f]\{6\}$\|^foreground=#[0-9A-Fa-f]\{6\}$" "$source"; then
        show_error "Invalid theme file format!"
        return 1
    fi
    
    local theme_name=$(basename "$source")
    cp "$source" "$COLORS_DIR/$theme_name"
    show_success "Theme loaded successfully!"
    return 0
}

configure_font_style() {
    clear
    show_bordered_header "Font Configuration"
    
    local current_font=$(get_current_font)
    
    if [[ "default" == "${current_font%.*}" ]]; then
        echo -e "${LEFT_PADDING}${HIGHLIGHT}[D] Default ${SUCCESS}← USED${RESET}"
    else
        echo -e "${LEFT_PADDING}${TEXT}[D] Default${RESET}"
    fi
    
    local count=0
    local fonts=($FONTS_DIR/*)
    
    for font in "${fonts[@]}"; do
        local font_name=$(basename "${font%.*}")
        if [[ "$font_name" == "${current_font%.*}" ]]; then
            echo -e "${LEFT_PADDING}${HIGHLIGHT}[${count}] ${font_name} ${SUCCESS}← USED${RESET}"
        else
            echo -e "${LEFT_PADDING}${TEXT}[${count}] ${font_name}${RESET}"
        fi
        count=$((count+1))
    done
    
    echo -e "${LEFT_PADDING}${SECONDARY}[L] Load font${RESET}"
    
    show_prompt "Select option:"
    read choice
    
    case $choice in
        [Dd])
            rm -f "$TERMUX_DIR/font.ttf"
            echo "default" > "$TERMUX_DIR/.current_font"
            ;;
        [Ll])
            if load_custom_font; then
                configure_font_style  # Refresh the menu to show newly loaded font
                return
            fi
            ;;
        [0-9]*)
            if [ "$choice" -lt "${#fonts[@]}" ]; then
                font=${fonts[$choice]}
                cp "$font" "$TERMUX_DIR/font.ttf"
                echo "$(basename "$font")" > "$TERMUX_DIR/.current_font"
            else
                show_error "Invalid selection"
                return
            fi
            ;;
        *)
            show_error "Invalid option"
            return
            ;;
    esac
    
    termux-reload-settings
    show_success "Font updated"
}

change_colors() {
    clear
    show_bordered_header "Color Theme Configuration"
    
    local current_theme=$(get_current_theme)
    
    if [[ "default" == "${current_theme%.*}" ]]; then
        echo -e "${LEFT_PADDING}${HIGHLIGHT}[D] Default ${SUCCESS}← USED${RESET}"
    else
        echo -e "${LEFT_PADDING}${TEXT}[D] Default${RESET}"
    fi
    
    local count=0
    local schemes=($COLORS_DIR/*)
    
    for scheme in "${schemes[@]}"; do
        local scheme_name=$(basename "${scheme%.*}")
        if [[ "$scheme_name" == "${current_theme%.*}" ]]; then
            echo -e "${LEFT_PADDING}${HIGHLIGHT}[${count}] ${scheme_name} ${SUCCESS}← USED${RESET}"
        else
            echo -e "${LEFT_PADDING}${TEXT}[${count}] ${scheme_name}${RESET}"
        fi
        count=$((count+1))
    done
    
    echo -e "${LEFT_PADDING}${SECONDARY}[R] Random theme${RESET}"
    echo -e "${LEFT_PADDING}${SECONDARY}[L] Load theme${RESET}"
    echo -e "${LEFT_PADDING}${SECONDARY}[C] Create custom theme${RESET}"
    
    show_prompt "Select option:"
    read choice
    
    case $choice in
        [Dd])
            rm -f "$COLORS_FILE"
            echo "default" > "$TERMUX_DIR/.current_color"
            ;;
        [Rr])
            random_scheme=$(ls $COLORS_DIR | shuf -n 1)
            cp "$COLORS_DIR/$random_scheme" "$COLORS_FILE"
            echo "$random_scheme" > "$TERMUX_DIR/.current_color"
            ;;
        [Ll])
            if load_custom_theme; then
                change_colors  # Refresh the menu to show newly loaded theme
                return
            fi
            ;;
        [Cc])
            create_custom_theme
            return
            ;;
        [0-9]*)
            if [ "$choice" -lt "${#schemes[@]}" ]; then
                scheme=${schemes[$choice]}
                cp "$scheme" "$COLORS_FILE"
                echo "$(basename "$scheme")" > "$TERMUX_DIR/.current_color"
            else
                show_error "Invalid selection"
                return
            fi
            ;;
        *)
            show_error "Invalid option"
            return
            ;;
    esac
    
    termux-reload-settings
    show_success "Color theme updated"
}

create_custom_theme() {
    clear
    show_bordered_header "Create Custom Color Theme"
    show_info "Enter color values in hexadecimal format (e.g., #FF0000)"
    
    local colors=(
        "background" "foreground" "cursor" 
        "color0" "color1" "color2" "color3" 
        "color4" "color5" "color6" "color7"
        "color8" "color9" "color10" "color11"
        "color12" "color13" "color14" "color15"
    )
    
    local theme_content=""
    local theme_name
    
    show_prompt "Enter theme name:"
    read theme_name
    
    for color in "${colors[@]}"; do
        while true; do
            show_prompt "Enter $color color:"
            read value
            if [[ $value =~ ^#[0-9A-Fa-f]{6}$ ]]; then
                theme_content+="$color=$value"$'\n'
                break
            else
                show_error "Invalid color format. Use #RRGGBB format"
            fi
        done
    done
    
    local theme_file="$COLORS_DIR/${theme_name}.properties"
    echo -n "$theme_content" > "$theme_file"
    show_success "Theme created: $theme_name"
    
    show_prompt "Apply this theme now? (y/N):"
    read apply
    if [ "$apply" = "y" ] || [ "$apply" = "Y" ]; then
        cp "$theme_file" "$COLORS_FILE"
        echo "${theme_name}.properties" > "$TERMUX_DIR/.current_color"
        termux-reload-settings
        show_success "Theme applied"
    fi
}

change_cursor() {
    clear
    show_bordered_header "Cursor Style Configuration"
    
    local current_style=$(grep "^terminal-cursor-style=" "$TERMUX_PROPERTIES" 2>/dev/null | cut -d'=' -f2 | tr -d '"' || echo "block")
    local current_blink=$(grep "^terminal-cursor-blink-rate=" "$TERMUX_PROPERTIES" 2>/dev/null | cut -d'=' -f2 || echo "0")
    
    format_option() {
        local num="${1:-}"
        local name="${2:-}"
        local style="${3:-}"
        local extra_info="${4:-}"
        
        local format="${LEFT_PADDING}${TEXT}"
        [[ "$style" == "$current_style" ]] && format="${LEFT_PADDING}${HIGHLIGHT}"
        
        echo -en "$format$num. $name"
        [[ "$style" == "$current_style" ]] && echo -en " ${SUCCESS}← USED"
        [[ -n "$extra_info" ]] && echo -en " ${SUCCESS}$extra_info"
        echo -e "${RESET}"
    }
    
    format_option "1" "Block" "block"
    format_option "2" "Underline" "underline"
    format_option "3" "Bar" "bar"
    format_option "4" "Configure Blinking" "" "$([[ $current_blink != "0" ]] && echo "← ENABLED (${current_blink}ms)")"
    
    show_prompt "Select cursor style [1-4]:"
    read choice

    case $choice in
        1) update_property "$TERMUX_PROPERTIES" "terminal-cursor-style" "block" ;;
        2) update_property "$TERMUX_PROPERTIES" "terminal-cursor-style" "underline" ;;
        3) update_property "$TERMUX_PROPERTIES" "terminal-cursor-style" "bar" ;;
        4)
            show_bordered_header "Cursor Blink Configuration"
            show_info "1. Enable blinking"
            show_info "2. Disable blinking"
            show_prompt "Select option [1-2]:"
            read blink_choice

            case $blink_choice in
                1)
                    show_prompt "Enter blink rate in milliseconds (e.g., 500 for 2 blinks/sec):"
                    read blink_rate
                    if [[ "$blink_rate" =~ ^[0-9]+$ ]]; then
                        update_property "$TERMUX_PROPERTIES" "terminal-cursor-blink-rate" "$blink_rate"
                        show_success "Cursor blink rate set to $blink_rate ms"
                    else
                        show_error "Invalid blink rate"
                        return
                    fi
                    ;;
                2)
                    update_property "$TERMUX_PROPERTIES" "terminal-cursor-blink-rate" "0"
                    show_success "Cursor blinking disabled"
                    ;;
                *)
                    show_error "Invalid option"
                    return
                    ;;
            esac
            ;;
        *)
            show_error "Invalid option"
            return
            ;;
    esac
    
    termux-reload-settings
    show_success "Cursor settings updated"
    show_warning "Please restart Termux for cursor changes to take full effect"
}

manage_aliases() {
    clear
    RC_FILE=$(get_shell_rc)
    if [ -z "$RC_FILE" ]; then
        show_error "Unsupported shell! Only bash and zsh are supported."
        return
    fi

    show_bordered_header "Alias Management"
    show_info "1. Add/Update alias"
    show_info "2. List existing aliases"
    show_info "3. Remove alias"
    show_prompt "Select option [1-3]:"
    read choice

    case $choice in
        1)
            show_prompt "Enter alias name:"
            read alias_name
            show_prompt "Enter command:"
            read alias_command
            
            if grep -q "^alias $alias_name=" "$RC_FILE"; then
                sed -i "/^alias $alias_name=/c\alias $alias_name='$alias_command'" "$RC_FILE"
                show_success "Alias updated! Please restart your shell"
            else
                echo "alias $alias_name='$alias_command'" >> "$RC_FILE"
                show_success "Alias added! Please restart your shell"
            fi
            ;;
        2)
            show_bordered_header "Existing aliases"
            grep "^alias" "$RC_FILE" 2>/dev/null || show_info "No aliases found"
            ;;
        3)
            show_prompt "Enter alias name to remove:"
            read alias_name
            sed -i "/^alias $alias_name=/d" "$RC_FILE"
            show_success "Alias removed! Please restart your shell or run 'source $RC_FILE'"
            ;;
        *)
            show_error "Invalid option"
            ;;
    esac
}

configure_motd() {
    clear
    MOTD_FILE="$PREFIX/etc/motd"
    show_bordered_header "MOTD Configuration"
    show_info "1. Disable MOTD"
    show_info "2. Enable default MOTD"
    show_info "3. Set custom MOTD"
    show_prompt "Select option [1-3]:"
    read choice

    case $choice in
        1)
            if [ -f "$MOTD_FILE" ]; then
                mv "$MOTD_FILE" "$MOTD_FILE.bak"
                show_success "MOTD disabled"
            else
                show_warning "MOTD is already disabled"
            fi
            ;;
        2)
            if [ -f "$MOTD_FILE.bak" ]; then
                mv "$MOTD_FILE.bak" "$MOTD_FILE"
                show_success "Default MOTD restored"
            else
                show_error "Default MOTD backup not found"
            fi
            ;;
        3)
            show_prompt "Enter your custom MOTD (Ctrl+D when done):"
            cat > "$MOTD_FILE"
            show_success "Custom MOTD set"
            ;;
        *)
            show_error "Invalid option"
            return
            ;;
    esac
}

show_help() {
    cat << EOF
${LEFT_PADDING}${HEADER}TermuXify Help Guide${RESET}
${LEFT_PADDING}A simple tool to customize your Termux terminal

${LEFT_PADDING}${PRIMARY}Usage:${RESET}
${LEFT_PADDING}  termuxify           Start the interactive menu
${LEFT_PADDING}  termuxify -h        Show this help message
${LEFT_PADDING}  termuxify --help    Show this help message

${LEFT_PADDING}${PRIMARY}Features:${RESET}

${LEFT_PADDING}${SECONDARY}1. Font Style${RESET}
${LEFT_PADDING}   - Change terminal fonts
${LEFT_PADDING}   - Load custom TTF fonts
${LEFT_PADDING}   - Reset to default font
${LEFT_PADDING}   Example: Select option 1 and choose from available fonts

${LEFT_PADDING}${SECONDARY}2. Color Theme${RESET}
${LEFT_PADDING}   - Change terminal colors
${LEFT_PADDING}   - Create custom color schemes
${LEFT_PADDING}   - Load existing themes
${LEFT_PADDING}   - Generate random themes
${LEFT_PADDING}   Example: Select option 2 and try "Random theme" to explore

${LEFT_PADDING}${SECONDARY}3. Cursor Style${RESET}
${LEFT_PADDING}   - Change cursor shape (block, underline, bar)
${LEFT_PADDING}   - Configure cursor blinking
${LEFT_PADDING}   Example: Select option 3 and try different cursor styles

${LEFT_PADDING}${SECONDARY}4. MOTD (Message of the Day)${RESET}
${LEFT_PADDING}   - Enable/disable welcome message
${LEFT_PADDING}   - Set custom welcome message
${LEFT_PADDING}   Example: Select option 4 and set your own welcome message

${LEFT_PADDING}${SECONDARY}5. Aliases${RESET}
${LEFT_PADDING}   - Create command shortcuts
${LEFT_PADDING}   - List existing aliases
${LEFT_PADDING}   - Remove aliases
${LEFT_PADDING}   Example: Select option 5 and create alias 'cls' for 'clear'

${LEFT_PADDING}${PRIMARY}Tips:${RESET}
${LEFT_PADDING}- Press Ctrl+C anytime to exit
${LEFT_PADDING}- Restart Termux after changes for best results

${LEFT_PADDING}${PRIMARY}Need more help?${RESET}
${LEFT_PADDING}Visit: ${GITHUB}
EOF
}

main() {
    # Add help flag handling
    if [[ $# -gt 0 ]]; then
        case "$1" in
            -h|--help)
                show_banner
                show_help
                exit 0
                ;;
            *)
                show_error "Unknown option: $1"
                show_info "Use -h or --help for usage information"
                exit 1
                ;;
        esac
    fi

    init_directories
    backup_initial_properties
    
    while true; do
        show_banner
        
        current_theme=$(get_current_theme)
        current_font=$(get_current_font)
        
        echo -e "${LEFT_PADDING}${PRIMARY}Current Configuration${RESET}"
        echo -e "${LEFT_PADDING}${TEXT}Theme: ${HIGHLIGHT}${current_theme%.*}${RESET}"
        echo -e "${LEFT_PADDING}${TEXT}Font:  ${HIGHLIGHT}${current_font%.*}${RESET}\n"

        show_header "APPEARANCE"
        show_info "1. Font Style"
        show_info "2. Color Theme"
        show_info "3. Cursor Style"
        
        show_header "CONFIGURATION"
        show_info "4. MOTD"
        
        show_header "MANAGEMENT"
        show_info "5. Aliases"
        show_info "6. Exit"
        
        echo
        show_prompt "Your choice [1-6]:"
        read choice

        case $choice in
            1) configure_font_style ;;
            2) change_colors ;;
            3) change_cursor ;;
            4) configure_motd ;;
            5) manage_aliases ;;
            6) show_success "Thanks for using TermuXify!" && exit 0 ;;
            *) show_error "Invalid option" ;;
        esac
        
        echo
        show_prompt "Press Enter to continue..."
        read
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

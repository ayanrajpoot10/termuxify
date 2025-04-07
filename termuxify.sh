#!/data/data/com.termux/files/usr/bin/bash

readonly VERSION="0.1.1"
readonly AUTHOR="Ayan Rajpoot"
readonly GITHUB="https://github.com/Ayanrajpoot10/TermuXify"

set -euo pipefail
IFS=$'\n\t'

readonly TERMUX_DIR="$HOME/.termux"
readonly SCRIPT_DIR="$(dirname "$(realpath "$0")")"
readonly COLORS_DIR="$PREFIX/share/termuxify/colors"
readonly FONTS_DIR="$PREFIX/share/termuxify/fonts"

readonly TERMUX_PROPERTIES="$TERMUX_DIR/termux.properties"
readonly COLORS_FILE="$TERMUX_DIR/colors.properties"
readonly CURRENT_THEME_FILE="$TERMUX_DIR/.current_theme"
readonly CURRENT_FONT_FILE="$TERMUX_DIR/.current_font"

declare -A COLOR=(
    [reset]="\033[0m"
    [bold]="\033[1m"
    [dim]="\033[2m"
    [italic]="\033[3m"
    
    [primary]="\033[38;5;68m"
    [secondary]="\033[38;5;31m"
    [accent]="\033[38;5;75m"
    [text]="\033[38;5;252m"
    [muted]="\033[38;5;244m"
    
    [success]="\033[38;5;78m"
    [warning]="\033[38;5;221m"
    [error]="\033[38;5;167m"
    [info]="\033[38;5;110m"
    
    [header]="\033[38;5;32m"
    [border]="\033[38;5;240m"
    [prompt]="\033[38;5;39m"
    [highlight]="\033[38;5;147m"
)

readonly LEFT_PADDING="   "

show_message() {
    local type=$1
    local msg=$2
    local color="${COLOR[$type]}"
    
    if [[ $type == "prompt" ]]; then
        echo -en "${LEFT_PADDING}${color}${COLOR[bold]}${msg}${COLOR[reset]} "
    else
        echo -e "${LEFT_PADDING}${color}${msg}${COLOR[reset]}"
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

show_banner() {
    clear
    echo
    printf "${LEFT_PADDING}${COLOR[accent]}${COLOR[bold]}"
    printf "┌────────────────────────────────────┐\n"
    printf "${LEFT_PADDING}│             TermuXify              │\n"
    printf "${LEFT_PADDING}└────────────────────────────────────┘"
    printf "${COLOR[reset]}\n"
    printf "${LEFT_PADDING}${COLOR[dim]} Terminal customization tool | v${VERSION}${COLOR[reset]}\n\n"
}

show_header() {
    local msg=$1
    echo -e "${LEFT_PADDING}${COLOR[header]}${msg}${COLOR[reset]}"
}

show_bordered_header() {
    local msg=$1
    echo -e "${LEFT_PADDING}${COLOR[border]}┌$(printf '─%.0s' {1..35})┐"
    echo -e "${LEFT_PADDING}${COLOR[border]}│${COLOR[header]}$(printf "%-35s" "  $msg")${COLOR[border]}│"
    echo -e "${LEFT_PADDING}${COLOR[border]}└$(printf '─%.0s' {1..35})┘${COLOR[reset]}"
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
    
    if ! grep -q "^color[0-9]\+=#[0-9A-Fa-f]\{6\}$\|^background=#[0-9A-Fa-f]\{6\}$\|^foreground=#[0-9A-Fa-f]\{6\}$" "$source"; then
        show_error "Invalid theme file format!"
        return 1
    fi
    
    local theme_name=$(basename "$source")
    cp "$source" "$COLORS_DIR/$theme_name"
    show_success "Theme loaded successfully!"
    return 0
}

display_selectable_items() {
    local current="$1"
    local items=("${@:2}")
    
    # Display default option
    if [[ "default" == "${current%.*}" ]]; then
        echo -e "${LEFT_PADDING}${COLOR[highlight]}[D] Default ${COLOR[success]}← USED${COLOR[reset]}"
    else
        echo -e "${LEFT_PADDING}${COLOR[text]}[D] Default${COLOR[reset]}"
    fi
    
    # Display array items
    local count=0
    for item in "${items[@]}"; do
        local name=$(basename "${item%.*}")
        if [[ "$name" == "${current%.*}" ]]; then
            echo -e "${LEFT_PADDING}${COLOR[highlight]}[${count}] ${name} ${COLOR[success]}← USED${COLOR[reset]}"
        else
            echo -e "${LEFT_PADDING}${COLOR[text]}[${count}] ${name}${COLOR[reset]}"
        fi
        count=$((count+1))
    done
}

configure_font_style() {
    clear
    show_bordered_header "Font Configuration"
    
    local current_font=$(get_current_font)
    local fonts=($FONTS_DIR/*)
    
    display_selectable_items "$current_font" "${fonts[@]}"
    echo -e "${LEFT_PADDING}${COLOR[secondary]}[L] Load font${COLOR[reset]}"
    
    show_prompt "Select option:"
    read choice
    
    case $choice in
        [Dd])
            rm -f "$TERMUX_DIR/font.ttf"
            echo "default" > "$TERMUX_DIR/.current_font"
            ;;
        [Ll])
            if load_custom_font; then
                configure_font_style
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
    local schemes=($COLORS_DIR/*)
    
    display_selectable_items "$current_theme" "${schemes[@]}"
    echo -e "${LEFT_PADDING}${COLOR[secondary]}[R] Random theme${COLOR[reset]}"
    echo -e "${LEFT_PADDING}${COLOR[secondary]}[L] Load theme${COLOR[reset]}"
    echo -e "${LEFT_PADDING}${COLOR[secondary]}[C] Create custom theme${COLOR[reset]}"
    
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
                change_colors
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
        
        local format="${LEFT_PADDING}${COLOR[text]}"
        [[ "$style" == "$current_style" ]] && format="${LEFT_PADDING}${COLOR[highlight]}"
        
        echo -en "$format$num. $name"
        [[ "$style" == "$current_style" ]] && echo -en " ${COLOR[success]}← USED"
        [[ -n "$extra_info" ]] && echo -en " ${COLOR[success]}$extra_info"
        echo -e "${COLOR[reset]}"
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

main() {

    init_directories
    backup_initial_properties
    
    while true; do
        show_banner
        
        current_theme=$(get_current_theme)
        current_font=$(get_current_font)
        
        echo -e "${LEFT_PADDING}${COLOR[primary]}Current Configuration${COLOR[reset]}"
        echo -e "${LEFT_PADDING}${COLOR[text]}Theme: ${COLOR[highlight]}${current_theme%.*}${COLOR[reset]}"
        echo -e "${LEFT_PADDING}${COLOR[text]}Font:  ${COLOR[highlight]}${current_font%.*}${COLOR[reset]}\n"

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

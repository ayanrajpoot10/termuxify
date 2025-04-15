#!/usr/bin/env bash

readonly VERSION="0.3.0"
readonly AUTHOR="Ayan Rajpoot"
readonly GITHUB="https://github.com/Ayanrajpoot10/TermuXify"

set -euo pipefail
IFS=$'\n\t'

readonly TERMUX_DIR="$HOME/.termux"
readonly COLORS_DIR="$PREFIX/share/termuxify/colors"
readonly FONTS_DIR="$PREFIX/share/termuxify/fonts"

readonly TERMUX_PROPERTIES="$TERMUX_DIR/termux.properties"
readonly COLORS_PROPERTIES="$TERMUX_DIR/colors.properties"
readonly CURRENT_THEME_FILE="$TERMUX_DIR/.current_theme"
readonly CURRENT_FONT_FILE="$TERMUX_DIR/.current_font"
readonly MOTD_FILE="$PREFIX/etc/motd"

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

backup_properties() {
    local files=("$TERMUX_PROPERTIES" "$COLORS_PROPERTIES")
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
    local width=35
    local padding=$(( (width - ${#msg}) / 2 ))
    echo -e "${LEFT_PADDING}${COLOR[border]}┌$(printf '─%.0s' {1..35})┐"
    echo -e "${LEFT_PADDING}${COLOR[border]}│${COLOR[header]}$(printf "%*s%s%*s" $padding "" "$msg" $((width - padding - ${#msg})) "")${COLOR[border]}│"
    echo -e "${LEFT_PADDING}${COLOR[border]}└$(printf '─%.0s' {1..35})┘${COLOR[reset]}"
}

update_property() {
    local file="$1"
    local property="$2"
    local value="$3"

    touch "$file"
    
    if grep -q "^[#[:space:]]*${property}[[:space:]]*=.*$" "$file"; then
        sed -i "s@^[#[:space:]]*${property}[[:space:]]*=.*\$@${property}=${value}@" "$file"
    else
        echo "${property}=${value}" >> "$file"
    fi
}

get_current_theme() {
    if [ -f "$CURRENT_THEME_FILE" ]; then
        cat "$CURRENT_THEME_FILE"
    else
        echo "default"
    fi
}

get_current_font() {
    if [ -f "$CURRENT_FONT_FILE" ]; then
        cat "$CURRENT_FONT_FILE"
    else
        echo "default"
    fi
}

get_shell_rc() {
    local shell_path=$(echo $SHELL)
    case "$shell_path" in
        *zsh)
            echo "$HOME/.zshrc"
            ;;
        *bash)
            echo "$HOME/.bashrc"
            ;;
        *)
            echo ""
            ;;
    esac
}

display_selectable_items() {
    local current="$1"
    local items=("${@:2}")
    local page=${CURRENT_PAGE:-0}
    local per_page=25
    local start=$((page * per_page))
    local end=$((start + per_page))
    [[ $end -gt ${#items[@]} ]] && end=${#items[@]}
    
    if [[ "default" == "${current%.*}" ]]; then
        echo -e "${LEFT_PADDING}${COLOR[highlight]}[D] Default ${COLOR[success]}← USED${COLOR[reset]}"
    else
        echo -e "${LEFT_PADDING}${COLOR[text]}[D] Default${COLOR[reset]}"
    fi
    
    for ((i = start; i < end; i++)); do
        local name=$(basename "${items[$i]%.*}")
        local num=$((i + 1))
        
        if [[ "$name" == "${current%.*}" ]]; then
            echo -e "${LEFT_PADDING}${COLOR[highlight]}[$num] $name ${COLOR[success]}← USED${COLOR[reset]}"
        else
            echo -e "${LEFT_PADDING}${COLOR[text]}[$num] $name${COLOR[reset]}"
        fi
    done

    local total_pages=$(( (${#items[@]} + per_page - 1) / per_page ))
    echo -e "\n${LEFT_PADDING}${COLOR[muted]}Page $((page + 1))/$total_pages${COLOR[reset]}"
    echo -e "${LEFT_PADDING}${COLOR[secondary]}[N] Next [P] Previous${COLOR[reset]}"
}

handle_pagination_input() {
    local total_pages=$(( ($1 + 24) / 25 ))
    
    case $choice in
        [Nn]) ((CURRENT_PAGE = CURRENT_PAGE >= total_pages - 1 ? total_pages - 1 : CURRENT_PAGE + 1)); return 1 ;;
        [Pp]) ((CURRENT_PAGE = CURRENT_PAGE <= 0 ? 0 : CURRENT_PAGE - 1)); return 1 ;;
        *) return 0 ;;
    esac
}

display_font_menu() {
    local current_font="$1"
    local installed_fonts=($FONTS_DIR/*)
    
    if [[ "default" == "${current_font%.*}" ]]; then
        echo -e "${LEFT_PADDING}${COLOR[highlight]}[0] Default ${COLOR[success]}← USED${COLOR[reset]}"
    else
        echo -e "${LEFT_PADDING}${COLOR[text]}[0] Default${COLOR[reset]}"
    fi
    
    for ((i = 0; i < ${#installed_fonts[@]}; i++)); do
        local font=${installed_fonts[$i]}
        local name=$(basename "${font%.*}")
        local display_num=$((i + 1))
        if [[ "$name" == "${current_font%.*}" ]]; then
            echo -e "${LEFT_PADDING}${COLOR[highlight]}[$display_num] ${name} ${COLOR[success]}← USED${COLOR[reset]}"
        else
            echo -e "${LEFT_PADDING}${COLOR[text]}[$display_num] ${name}${COLOR[reset]}"
        fi
    done
}

configure_font_style() {
    clear
    show_bordered_header "Font Configuration"
    
    local current_font=$(get_current_font)
    
    while true; do
        clear
        show_bordered_header "Font Configuration"
        display_font_menu "$current_font"
        
        show_prompt "Select option:"
        read choice
        
        case $choice in
            0)
                rm -f "$TERMUX_DIR/font.ttf"
                echo "default" > "$CURRENT_FONT_FILE"
                break
                ;;
            [1-9]*)
                local installed_fonts=($FONTS_DIR/*)
                local idx=$((choice - 1))
                if [ "$idx" -lt "${#installed_fonts[@]}" ]; then
                    local font=${installed_fonts[$idx]}
                    local font_file=$(find "$font" -type f -name "*.ttf" | head -n 1)
                    if [ -n "$font_file" ]; then
                        cp "$font_file" "$TERMUX_DIR/font.ttf"
                        echo "$(basename "$font")" > "$CURRENT_FONT_FILE"
                        break
                    else
                        show_error "No valid font file found in the directory"
                    fi
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
    done
    
    termux-reload-settings
    show_success "Font updated"
}

change_colors() {
    clear
    show_bordered_header "Color Theme Configuration"
    
    local current_theme=$(get_current_theme)
    local schemes=($COLORS_DIR/*)
    CURRENT_PAGE=0
    
    while true; do
        clear
        show_bordered_header "Color Theme Configuration"
        display_selectable_items "$current_theme" "${schemes[@]}"
        echo -e "${LEFT_PADDING}${COLOR[secondary]}[R] Random theme${COLOR[reset]}"
        
        show_prompt "Select option:"
        read choice
        
        if ! handle_pagination_input ${#schemes[@]}; then
            continue
        fi
        
        case $choice in
            [Dd])
                rm -f "$COLORS_PROPERTIES"
                echo "default" > "$CURRENT_THEME_FILE"
                break
                ;;
            [Rr])
                random_scheme=$(ls $COLORS_DIR | shuf -n 1)
                cp "$COLORS_DIR/$random_scheme" "$COLORS_PROPERTIES"
                echo "$random_scheme" > "$CURRENT_THEME_FILE"
                break
                ;;
            [0-9]*)
                local actual_choice=$((choice - 1))
                if [ "$actual_choice" -lt "${#schemes[@]}" ]; then
                    scheme=${schemes[$actual_choice]}
                    cp "$scheme" "$COLORS_PROPERTIES"
                    echo "$(basename "$scheme")" > "$CURRENT_THEME_FILE"
                    break
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
    done
    
    termux-reload-settings
    show_success "Color theme updated"
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
    show_warning "Restart Termux for changes to take effect"
}

manage_aliases() {
    clear
    RC_FILE=$(get_shell_rc)
    if [ -z "$RC_FILE" ]; then
        show_error "Unsupported shell! Only bash and zsh are supported."
        return
    fi

    if [ ! -f "$RC_FILE" ]; then
        touch "$RC_FILE"
        show_warning "Created new $RC_FILE file"
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
            
            if grep -q "^alias $alias_name=" "$RC_FILE" 2>/dev/null; then
                sed -i "/^alias $alias_name=/c\alias $alias_name='$alias_command'" "$RC_FILE"
                source "$RC_FILE" 2>/dev/null || . "$RC_FILE"
                show_success "Alias updated and applied!"
            else
                echo "alias $alias_name='$alias_command'" >> "$RC_FILE"
                source "$RC_FILE" 2>/dev/null || . "$RC_FILE"
                show_success "Alias added and applied!"
            fi
            ;;
        2)
            show_bordered_header "Existing aliases"
            if ! grep "^alias" "$RC_FILE" 2>/dev/null; then
                show_info "No aliases found"
            fi
            ;;
        3)
            show_prompt "Enter alias name to remove:"
            read alias_name
            if grep -q "^alias $alias_name=" "$RC_FILE" 2>/dev/null; then
                sed -i "/^alias $alias_name=/d" "$RC_FILE"
                source "$RC_FILE" 2>/dev/null || . "$RC_FILE"
                show_success "Alias removed and applied!"
            else
                show_warning "Alias not found"
            fi
            ;;
        *)
            show_error "Invalid option"
            ;;
    esac
}

get_motd_status() {
    if [ ! -f "$MOTD_FILE" ]; then
        echo "disabled"
    elif [ -f "$MOTD_FILE.bak" ]; then
        echo "custom"
    else
        echo "default"
    fi
}

configure_motd() {
    clear
    local current_status=$(get_motd_status)
    show_bordered_header "MOTD Configuration"
    
    format_option() {
        local num="$1"
        local name="$2"
        local status="$3"
        local current="$4"
        
        local format="${LEFT_PADDING}${COLOR[text]}"
        [[ "$status" == "$current" ]] && format="${LEFT_PADDING}${COLOR[highlight]}"
        
        echo -en "$format$num. $name"
        [[ "$status" == "$current" ]] && echo -en " ${COLOR[success]}← USED"
        echo -e "${COLOR[reset]}"
    }
    
    format_option "1" "Disable MOTD" "disabled" "$current_status"
    format_option "2" "Enable default MOTD" "default" "$current_status"
    format_option "3" "Set custom MOTD" "custom" "$current_status"
    
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
            if [ -f "$MOTD_FILE.bak" ] && [ "$(readlink -f "$MOTD_FILE.bak")" != "$(readlink -f "$MOTD_FILE")" ]; then
                mv "$MOTD_FILE.bak" "$MOTD_FILE"
                show_success "Default MOTD restored"
            else
                show_error "Default MOTD backup not found"
            fi
            ;;
        3)
            if [ -f "$MOTD_FILE" ] && [ ! -f "$MOTD_FILE.bak" ]; then
                cp "$MOTD_FILE" "$MOTD_FILE.bak"
            fi
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

configure_default_directory() {
    clear
    show_bordered_header "Default Directory Configuration"
    
    local current_dir=$(grep "^default-working-directory=" "$TERMUX_PROPERTIES" 2>/dev/null | cut -d'=' -f2 | tr -d ' "' || echo "$HOME")
    
    show_info "Current default directory: ${COLOR[highlight]}$current_dir${COLOR[reset]}"
    echo
    show_info "1. Set custom directory"
    show_info "2. Reset to home directory"
    
    show_prompt "Select option [1-2]:"
    read choice
    
    case $choice in
        1)
            show_prompt "Enter new default directory path:"
            read new_dir
            
            if [ -d "$new_dir" ]; then
                update_property "$TERMUX_PROPERTIES" "default-working-directory" "$new_dir"
                show_success "Default directory updated to: $new_dir"
                show_warning "Restart Termux for changes to take effect"
            else
                show_error "Directory does not exist!"
            fi
            ;;
        2)
            sed -i '/^default-working-directory=/d' "$TERMUX_PROPERTIES"
            show_success "Reset to home directory"
            show_warning "Restart Termux for changes to take effect"
            ;;
        *)
            show_error "Invalid option"
            return
            ;;
    esac
}

configure_fullscreen() {
    clear
    show_bordered_header "Fullscreen Configuration"
    
    local current_fullscreen=$(grep "^fullscreen=" "$TERMUX_PROPERTIES" 2>/dev/null | cut -d'=' -f2 | tr -d ' "' || echo "false")
    local current_workaround=$(grep "^use-fullscreen-workaround=" "$TERMUX_PROPERTIES" 2>/dev/null | cut -d'=' -f2 | tr -d ' "' || echo "false")
    
    show_info "Current settings:"
    echo -e "${LEFT_PADDING}${COLOR[text]}Fullscreen: ${COLOR[highlight]}$current_fullscreen${COLOR[reset]}"
    echo -e "${LEFT_PADDING}${COLOR[text]}Workaround: ${COLOR[highlight]}$current_workaround${COLOR[reset]}"
    echo
    show_info "1. Toggle fullscreen"
    show_info "2. Toggle fullscreen workaround"
    show_info "3. Reset to default"
    
    show_prompt "Select option [1-3]:"
    read choice
    
    case $choice in
        1)
            local new_value=$([ "$current_fullscreen" = "true" ] && echo "false" || echo "true")
            update_property "$TERMUX_PROPERTIES" "fullscreen" "$new_value"
            show_success "Fullscreen set to: $new_value"
            ;;
        2)
            local new_value=$([ "$current_workaround" = "true" ] && echo "false" || echo "true")
            update_property "$TERMUX_PROPERTIES" "use-fullscreen-workaround" "$new_value"
            show_success "Fullscreen workaround set to: $new_value"
            ;;
        3)
            sed -i '/^fullscreen=/d' "$TERMUX_PROPERTIES"
            sed -i '/^use-fullscreen-workaround=/d' "$TERMUX_PROPERTIES"
            show_success "Reset to default settings"
            ;;
        *)
            show_error "Invalid option"
            return
            ;;
    esac
    
    show_warning "Restart Termux for changes to take effect"
}

show_about() {
    clear
    show_bordered_header "About TermuXify"
    
    echo -e "${LEFT_PADDING}${COLOR[text]}Version: ${COLOR[highlight]}${VERSION}${COLOR[reset]}"
    echo -e "${LEFT_PADDING}${COLOR[text]}Author:  ${COLOR[highlight]}${AUTHOR}${COLOR[reset]}"
    echo -e "${LEFT_PADDING}${COLOR[text]}GitHub:  ${COLOR[highlight]}${GITHUB}${COLOR[reset]}"
    echo -e "${LEFT_PADDING}${COLOR[text]}Telegram: ${COLOR[highlight]}@Ayan_rajpoot${COLOR[reset]}"
    echo
    show_info "Description:"
    echo -e "${LEFT_PADDING}${COLOR[text]}A powerful customization tool for Termux that allows you${COLOR[reset]}"
    echo -e "${LEFT_PADDING}${COLOR[text]}to easily configure themes, fonts, colors, and more.${COLOR[reset]}"
}

main() {
    backup_properties
    
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
        echo
        show_header "CONFIGURATION"
        show_info "4. MOTD"
        show_info "5. Default Directory"
        show_info "6. Fullscreen"
        echo
        show_header "MANAGEMENT"
        show_info "7. Aliases"
        show_info "8. About"
        show_info "9. Exit"
        
        echo
        show_prompt "Your choice [1-9]:"
        read choice

        case $choice in
            1) configure_font_style ;;
            2) change_colors ;;
            3) change_cursor ;;
            4) configure_motd ;;
            5) configure_default_directory ;;
            6) configure_fullscreen ;;
            7) manage_aliases ;;
            8) show_about ;;
            9) show_success "Thanks for using TermuXify!" && exit 0 ;;
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

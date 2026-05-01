#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
CONFIG_FILE="$SCRIPT_DIR/git-all.conf"
BLACKLIST_FILE="$SCRIPT_DIR/blacklist"

[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

: "${GS_GITHUB_USER:=$(git config user.name || echo 'aGuyCalledT')}"
: "${GS_DRAW_WIDTH:=65}"
: "${GS_CORNER_STYLE:=sharp}"
: "${GS_BASE_DIRS:=$HOME/git}"

GREEN=$'\e[0;32m'
RED=$'\e[0;31m'
GRAY=$'\e[90m'
NC=$'\e[0m'

if [[ "$GS_CORNER_STYLE" == "rounded" ]]; then
    C_TL="╭"
    C_TR="╮"
    C_BL="╰"
    C_BR="╯"
else
    C_TL="┌"
    C_TR="┐"
    C_BL="└"
    C_BR="┘"
fi

draw_top() {
    local title="   $1 "
    local border_line
    printf -v border_line "%$((GS_DRAW_WIDTH - 2 - ${#title}))s" ""
    echo -e "${GREEN}${C_TL}${title}${border_line// /─}${C_TR}${NC}"
}

draw_bottom() {
    local border_line
    printf -v border_line "%$((GS_DRAW_WIDTH - 2))s" ""
    echo -e "${GREEN}${C_BL}${border_line// /─}${C_BR}${NC}"
}

draw_header() {
    local title=" $1 "
    local border_line
    printf -v border_line "%$((GS_DRAW_WIDTH - ${#title}))s" ""
    local dashes="${border_line// /─}"
    local left=$((${#dashes} / 2))
    echo -e "\n${GREEN}${dashes:0:left}${title}${dashes:left}${NC}\n"
}

print_msg() {
    local clean_text=$(echo -e "$1" | sed 's/\x1b\[[0-9;]*m//g')
    local pad_len=$((GS_DRAW_WIDTH - 4 - ${#clean_text}))
    ((pad_len < 0)) && pad_len=0

    local padding
    printf -v padding "%${pad_len}s" ""
    echo -e "${GREEN}│${NC}  $1${padding}${GREEN}│${NC}"
}

ask_prompt() {
    echo -ne "${GREEN}│${NC}  $1"
}

extract_error() {
    local err=$(echo "$1" | grep -iE 'fatal:|error:|rejected' | tail -n 1 | sed -E 's/.*(fatal:|error:) //' | tr -d '\n')
    err="${err:-unknown error}"
    echo "$err" | sed -E "s|'https?://[^']+'|<remote>|g; s|'git@[^']+'|<remote>|g; s|https?://[^ ]+|<remote>|g"
}

print_error_wrapped() {
    echo "$1$2" | fold -s -w $((GS_DRAW_WIDTH - 7)) | while IFS= read -r line; do
        print_msg "${RED}${line%% }${NC}"
    done
}

get_clean_url() {
    local url=$(git config --get remote.origin.url 2>/dev/null)
    [[ -z "$url" ]] && return
    url="${url#git@github.com:}"
    url="${url%.git}"
    [[ "$url" != http* ]] && url="https://github.com/$url"
    echo "$url"
}

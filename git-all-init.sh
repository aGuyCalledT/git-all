#!/bin/bash

GREEN=$'\e[0;32m'
NC=$'\e[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
CONFIG_FILE="$SCRIPT_DIR/git-all.conf"

# Lade bisherige Config für die Standardwerte in den eckigen Klammern
[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

: "${GS_BASE_DIR:=$HOME/git}"
: "${GS_GITHUB_USER:=aGuyCalledT}"
: "${GS_DRAW_WIDTH:=65}"
: "${GS_CORNER_STYLE:=sharp}"

echo -e "\n${GREEN}git-all-initialization${NC}"

read -p "Git base directory [$GS_BASE_DIR]: " inp_dir
GS_BASE_DIR="${inp_dir:-$GS_BASE_DIR}"

read -p "GitHub username [$GS_GITHUB_USER]: " inp_user
GS_GITHUB_USER="${inp_user:-$GS_GITHUB_USER}"

read -p "Terminal box width [$GS_DRAW_WIDTH]: " inp_width
GS_DRAW_WIDTH="${inp_width:-$GS_DRAW_WIDTH}"

read -p "Corner style (rounded/sharp) [$GS_CORNER_STYLE]: " inp_corner
GS_CORNER_STYLE="${inp_corner:-$GS_CORNER_STYLE}"

read -p "Reset current blacklist? [y/N]: " inp_reset
if [[ "${inp_reset,,}" =~ ^(y|yes)$ ]]; then
    rm -f "$GS_BASE_DIR/.blacklist"
    echo "Blacklist cleared."
fi

# Schreibe die neue Config
cat <<EOF >"$CONFIG_FILE"
# git-all.conf
GS_BASE_DIR="$GS_BASE_DIR"
GS_GITHUB_USER="$GS_GITHUB_USER"
GS_DRAW_WIDTH=$GS_DRAW_WIDTH
GS_CORNER_STYLE="$GS_CORNER_STYLE"
EOF

echo -e "${GREEN}Setup complete! Configuration saved to $CONFIG_FILE${NC}\n"

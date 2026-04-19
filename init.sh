#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/lib.sh"

: "${GS_BASE_DIR:=$HOME/git}"

draw_header "git-all setup"

read -p "git base directory [$GS_BASE_DIR]: " inp_dir
GS_BASE_DIR="${inp_dir:-$GS_BASE_DIR}"

read -p "github username [$GS_GITHUB_USER]: " inp_user
GS_GITHUB_USER="${inp_user:-$GS_GITHUB_USER}"

read -p "terminal box width [$GS_DRAW_WIDTH]: " inp_width
GS_DRAW_WIDTH="${inp_width:-$GS_DRAW_WIDTH}"

read -p "corner style (rounded/sharp) [$GS_CORNER_STYLE]: " inp_corner
GS_CORNER_STYLE="${inp_corner:-$GS_CORNER_STYLE}"

read -p "reset current blacklist? [y/n]: " inp_reset
if [[ "${inp_reset,,}" =~ ^(y|yes)$ ]]; then
    rm -f "$GS_BASE_DIR/.blacklist"
    echo -e "${GREEN}blacklist cleared.${NC}"
fi

cat <<EOF >"$CONFIG_FILE"
GS_BASE_DIR="$GS_BASE_DIR"
GS_GITHUB_USER="$GS_GITHUB_USER"
GS_DRAW_WIDTH=$GS_DRAW_WIDTH
GS_CORNER_STYLE="$GS_CORNER_STYLE"
EOF

echo -e "\n${GREEN}setup done.${NC}"

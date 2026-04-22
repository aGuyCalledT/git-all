#!/bin/bash
#cute

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/lib.sh"

draw_header "git-all setup"

read -p "git base directories (space separated) [$GS_BASE_DIRS]: " inp_dirs
GS_BASE_DIRS="${inp_dirs:-$GS_BASE_DIRS}"

read -p "github username [$GS_GITHUB_USER]: " inp_user
GS_GITHUB_USER="${inp_user:-$GS_GITHUB_USER}"

read -p "terminal box width [$GS_DRAW_WIDTH]: " inp_width
GS_DRAW_WIDTH="${inp_width:-$GS_DRAW_WIDTH}"

read -p "corner style (rounded/sharp) [$GS_CORNER_STYLE]: " inp_corner
GS_CORNER_STYLE="${inp_corner:-$GS_CORNER_STYLE}"

read -p "reset blacklist? [y/n]: " inp_reset
if [[ "${inp_reset,,}" =~ ^(y|yes)$ ]]; then
    rm -f "$BLACKLIST_FILE"
    echo -e "${GREEN}blacklist cleared.${NC}"
fi

cat <<EOF >"$CONFIG_FILE"
GS_BASE_DIRS="$GS_BASE_DIRS"
GS_GITHUB_USER="$GS_GITHUB_USER"
GS_DRAW_WIDTH=$GS_DRAW_WIDTH
GS_CORNER_STYLE="$GS_CORNER_STYLE"
EOF

echo -e "\n${GREEN}setup done.${NC}"

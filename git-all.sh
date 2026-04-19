#!/bin/bash

# Finde den echten Pfad des Skripts, auch wenn es über einen globalen Alias gestartet wird
SCRIPT_FILE=$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_FILE")" &>/dev/null && pwd)"

# Wenn der Befehl "git-all init" lautet, starte das init-Skript und beende dieses hier
if [[ "${1,,}" == "init" ]]; then
    exec "$SCRIPT_DIR/git-all-init.sh"
fi

# Lade die Library
source "$SCRIPT_DIR/git-all-lib.sh"

touch "$BLACKLIST_FILE"

echo -e "\nstarting git-sweeper in $GS_BASE_DIR\n"

for dir in "$GS_BASE_DIR"/*/; do
    PROJECT_NAME=$(basename "$dir")

    [[ "$PROJECT_NAME" == *"*"* ]] && continue
    grep -Fxq "$PROJECT_NAME" "$BLACKLIST_FILE" && continue

    if [[ -d "$dir/.git" ]]; then
        REMOTE_URL=$(git -C "$dir" remote get-url origin 2>/dev/null)
        [[ -n "$REMOTE_URL" && "$REMOTE_URL" != *"$GS_GITHUB_USER"* ]] && continue
    fi

    draw_top "$PROJECT_NAME"

    (
        cd "$dir" || exit

        # Initialization
        if [[ ! -d ".git" ]]; then
            ask_prompt "not a git repo. initialize? [y/N]: "
            read init_choice

            if [[ "${init_choice,,}" =~ ^(y|yes)$ ]]; then
                git init -b main >/dev/null 2>&1
                ask_prompt "github visibility? [Private/public]: "
                read vis_choice

                VIS_FLAG="--private"
                [[ "${vis_choice,,}" == "public" ]] && VIS_FLAG="--public"

                print_msg " creating github repository..."
                gh repo create "$PROJECT_NAME" $VIS_FLAG --source=. --remote=origin >/dev/null 2>&1
            else
                echo "$PROJECT_NAME" >>"$BLACKLIST_FILE"
                print_msg " blacklisted."
                exit 0
            fi
        fi

        # History
        LAST_COMMIT=$(git log -1 --format="%ar: %s" 2>/dev/null)
        if [[ -n "$LAST_COMMIT" ]]; then
            [[ ${#LAST_COMMIT} -gt 55 ]] && LAST_COMMIT="${LAST_COMMIT:0:52}..."
            print_msg "${GRAY} last: $LAST_COMMIT${NC}"
        fi

        # Commit logic
        CHANGES_MADE=false
        if [[ -n "$(git status --porcelain)" ]]; then
            ask_prompt "enter commit message [auto commit]: "
            read msg_choice

            git add .
            git commit -m "${msg_choice:-auto commit}" >/dev/null
            print_msg "󱓌 changes committed."
            CHANGES_MADE=true
        else
            print_msg "󰘬 no changes to commit."
        fi

        # Push logic
        BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
        AHEAD_CHECK=$(git status -sb 2>/dev/null | grep -o 'ahead [0-9]\+')
        MISSING_UPSTREAM=$(git config --get branch.${BRANCH}.remote)

        if $CHANGES_MADE || [[ -n "$AHEAD_CHECK" ]] || [[ -z "$MISSING_UPSTREAM" ]]; then
            PUSH_OUT=$(git push origin "$BRANCH" 2>&1)

            if [[ $? -ne 0 ]]; then
                print_error_wrapped "󱓎 push failed: " "$(extract_error "$PUSH_OUT")"

                if ! git push -u origin "$BRANCH" >/dev/null 2>&1; then
                    git pull --rebase origin "$BRANCH" >/dev/null 2>&1
                    PUSH_OUT3=$(git push -u origin "$BRANCH" 2>&1)

                    if [[ $? -ne 0 ]]; then
                        print_error_wrapped " critical error: " "$(extract_error "$PUSH_OUT3")"
                        exit 1
                    fi
                fi
                print_msg " synchronized!"
            elif ! echo "$PUSH_OUT" | grep -q "Everything up-to-date"; then
                print_msg " synchronized!"
            fi
        fi
    )

    draw_bottom

    # Link output
    REPO_URL=$(cd "$dir" && get_clean_url)
    [[ -n "$REPO_URL" ]] && echo -e "   ${GRAY} $REPO_URL${NC}\n" || echo ""

done

echo "done."

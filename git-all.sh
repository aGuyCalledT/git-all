#!/bin/bash

SCRIPT_FILE=$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_FILE")" &>/dev/null && pwd)"

source "$SCRIPT_DIR/lib.sh"

case "${1,,}" in
init)
    exec "$SCRIPT_DIR/init.sh"
    ;;
blacklist)
    ${EDITOR:-nano} "$BLACKLIST_FILE"
    exit 0
    ;;
esac

touch "$BLACKLIST_FILE"

for base in $GS_BASE_DIRS; do
    base_path="${base/#\~/$HOME}"
    [[ ! -d "$base_path" ]] && continue

    echo -e "\nstarting git-all in $base_path\n"

    for dir in "$base_path"/*/; do
        [[ ! -d "$dir" ]] && continue

        ABS_PATH=$(readlink -f "$dir")
        grep -Fxq "$ABS_PATH" "$BLACKLIST_FILE" && continue

        PROJECT_NAME=$(basename "$dir")
        [[ "$PROJECT_NAME" == *"*"* ]] && continue

        if [[ -d "$dir/.git" ]]; then
            REMOTE_URL=$(git -C "$dir" remote get-url origin 2>/dev/null)
            [[ -n "$REMOTE_URL" && "$REMOTE_URL" != *"$GS_GITHUB_USER"* ]] && continue
        fi

        draw_top "$PROJECT_NAME"

        (
            cd "$dir" || exit

            if [[ ! -d ".git" ]]; then
                ask_prompt "not a git repo. initialize? [y/n]: "
                read init_choice

                if [[ "${init_choice,,}" =~ ^(y|yes)$ ]]; then
                    git init -b main >/dev/null 2>&1
                    ask_prompt "github visibility? [private/public]: "
                    read vis_choice

                    VIS_FLAG="--private"
                    [[ "${vis_choice,,}" == "public" ]] && VIS_FLAG="--public"

                    print_msg " creating github repository..."
                    gh repo create "$PROJECT_NAME" $VIS_FLAG --source=. --remote=origin >/dev/null 2>&1
                else
                    echo "$ABS_PATH" >>"$BLACKLIST_FILE"
                    print_msg " blacklisted."
                    exit 0
                fi
            fi

            LAST_COMMIT=$(git log -1 --format="%ar: %s" 2>/dev/null)
            if [[ -n "$LAST_COMMIT" ]]; then
                [[ ${#LAST_COMMIT} -gt 55 ]] && LAST_COMMIT="${LAST_COMMIT:0:52}..."
                print_msg "${GRAY} last: $LAST_COMMIT${NC}"
            fi

            CHANGES_MADE=false
            if [[ -n "$(git status --porcelain)" ]]; then
                ask_prompt "create a commit? [y/n]: "
                read do_commit

                if [[ -z "$do_commit" || "${do_commit,,}" =~ ^(y|yes)$ ]]; then
                    ask_prompt "enter commit message [auto commit]: "
                    read msg_choice

                    git add .
                    git commit -m "${msg_choice:-auto commit}" >/dev/null
                    print_msg "󱓌 changes committed."
                    CHANGES_MADE=true
                else
                    print_msg "󰜺 commit skipped."
                fi
            else
                print_msg "󰘬 no changes to commit."
            fi

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

        REPO_URL=$(cd "$dir" && get_clean_url)
        [[ -n "$REPO_URL" ]] && echo -e "   ${GRAY} $REPO_URL${NC}\n" || echo ""
    done
done

echo "done."

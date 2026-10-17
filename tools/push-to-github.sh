#!/usr/bin/env bash
#
# tools/push-to-github.sh
#
# Commits any pending work and pushes to GitHub, reporting a specific fix for
# each failure mode instead of git's generic error text.
#
# Usage:
#   ./tools/push-to-github.sh
#   ./tools/push-to-github.sh "my commit message"
#
# Handles the usual causes of "unable to push":
#   - not logged in / expired token
#   - remote ahead of local (needs a rebase)
#   - no upstream branch set
#   - nothing to commit
#   - network or DNS problems
#
set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

BRANCH="${BRANCH:-main}"
REMOTE="${REMOTE:-origin}"
MESSAGE="${1:-Update Indigenous GCS}"

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
warn()  { printf '\033[33m%s\033[0m\n' "$*"; }
step()  { printf '\n\033[36m==> %s\033[0m\n' "$*"; }

# ── 1. Are we in a git repository? ───────────────────────────
step "Checking repository"
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    red "Not a git repository: $PROJECT_DIR"
    exit 1
fi
green "    repository: $PROJECT_DIR"

# ── 2. Does the remote exist and are we authenticated? ───────────────────────
step "Checking remote authentication"
REMOTE_URL="$(git remote get-url "$REMOTE" 2>/dev/null)"

if [ -z "$REMOTE_URL" ]; then
    red "No remote named $REMOTE."
    echo "    Add one with:"
    echo "      git remote add origin https://github.com/GarvitTech/Indigenous-GCS.git"
    exit 1
fi
echo "    remote: $REMOTE_URL"

if ! git ls-remote --heads "$REMOTE" >/dev/null 2>&1; then
    red "    Cannot reach $REMOTE."
    echo
    echo "    Fix, in order of likelihood:"
    echo
    echo "    1. Not logged in. Authenticate with either:"
    echo "         gh auth login"
    echo "       or set up a credential helper and use a Personal Access Token:"
    echo "         git config --global credential.helper osxkeychain    (macOS)"
    echo "         git config --global credential.helper manager        (Windows)"
    echo "       Create a token at https://github.com/settings/tokens"
    echo "       It needs the repo scope."
    echo
    echo "    2. The URL is wrong. Check and correct it:"
    echo "         git remote -v"
    echo "         git remote set-url origin https://github.com/GarvitTech/Indigenous-GCS.git"
    echo
    echo "    3. No network access:"
    echo "         curl -sSf https://github.com > /dev/null && echo OK"
    echo
    exit 1
fi
green "    authenticated and reachable"

# ── 3. Commit anything pending ───────────────────────────────
step "Staging changes"
if [ -n "$(git status --porcelain)" ]; then
    git add -A
    if git diff --cached --quiet; then
        warn "    nothing to commit after staging"
    else
        CHANGED="$(git diff --cached --name-only | wc -l | awk '{print $1}')"
        if ! git commit -q -m "$MESSAGE"; then
            red "    commit failed"
            exit 1
        fi
        green "    committed $CHANGED file(s)"
    fi
else
    green "    working tree already clean"
fi

# ── 4. Reconcile with the remote before pushing ──────────────────────────────
step "Fetching remote state"
git fetch "$REMOTE" "$BRANCH" --quiet 2>/dev/null || warn "    fetch failed; continuing"

LOCAL_SHA="$(git rev-parse HEAD)"
REMOTE_SHA="$(git rev-parse "$REMOTE/$BRANCH" 2>/dev/null)"

if [ -n "$REMOTE_SHA" ]; then
    if [ "$LOCAL_SHA" = "$REMOTE_SHA" ]; then
        green "    already up to date, nothing to push"
        echo
        green "==> Done"
        exit 0
    fi

    if git merge-base --is-ancestor "$REMOTE_SHA" "$LOCAL_SHA" 2>/dev/null; then
        green "    fast-forward push possible"
    else
        warn "    remote has commits you do not have, rebasing onto it"
        if ! git rebase "$REMOTE/$BRANCH"; then
            red "    Rebase hit conflicts."
            echo
            echo "    Resolve them, then:"
            echo "      git add <resolved files>"
            echo "      git rebase --continue"
            echo "      ./tools/push-to-github.sh"
            echo
            echo "    Or abandon the rebase and keep your local state:"
            echo "      git rebase --abort"
            exit 1
        fi
        green "    rebase complete"
    fi
fi

# ── 5. Push ──────────────────
step "Pushing to $REMOTE/$BRANCH"
if git push -u "$REMOTE" "$BRANCH"; then
    echo
    green "==> Pushed successfully"
    echo "    commit: $(git rev-parse --short HEAD)"
    echo "    view:   ${REMOTE_URL%.git}"
else
    red "    push failed"
    echo
    echo "    Common causes:"
    echo
    echo "    - Protected branch: the repository may require a pull request."
    echo "      Open one at ${REMOTE_URL%.git}/compare"
    echo
    echo "    - Token lacks the repo scope. Create a new one:"
    echo "      https://github.com/settings/tokens"
    echo
    echo "    - A file over 100 MB was rejected. Find the largest tracked files:"
    echo "      git ls-files -z | xargs -0 du -h 2>/dev/null | sort -rh | head -10"
    exit 1
fi

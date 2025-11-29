#!/usr/bin/env bash
set -euo pipefail
# Usage:
#   ./scripts/git-init.sh [--branch main] [--remote https://github.com/user/repo.git] [--first-commit "msg"] [--push]
BRANCH="main"; REMOTE=""; MSG="init: scaffold"; DO_PUSH=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --branch) BRANCH="${2:-main}"; shift ;;
    --remote) REMOTE="${2:-}"; shift ;;
    --first-commit) MSG="${2:-$MSG}"; shift ;;
    --push) DO_PUSH=1 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac; shift
done
git init
git checkout -b "$BRANCH" 2>/dev/null || true
git add .
git commit -m "$MSG" || true
if [[ -n "$REMOTE" ]]; then
  git remote add origin "$REMOTE" 2>/dev/null || git remote set-url origin "$REMOTE"
  if [[ $DO_PUSH -eq 1 ]]; then
    git push -u origin "$BRANCH"
  fi
fi
echo "[*] Repo ready. Current remotes:"; git remote -v || true

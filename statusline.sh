#!/bin/bash
input=$(cat)

REMAINING=$(echo "$input" | jq -r '.context_window.remaining_percentage // 0' | cut -d. -f1)
CWD=$(echo "$input" | jq -r '.cwd')
DIR=$(basename "$CWD")
if [ "$DIR" = "sequence-platform-api" ]; then
  DIR="backend"
fi
BRANCH=$(git -C "$CWD" --no-optional-locks branch --show-current 2>/dev/null)

# Detect worktree name (only if we're in a linked worktree, not the main one)
WORKTREE=""
TOPLEVEL=$(git -C "$CWD" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
COMMON_DIR=$(git -C "$CWD" --no-optional-locks rev-parse --git-common-dir 2>/dev/null)
GIT_DIR=$(git -C "$CWD" --no-optional-locks rev-parse --git-dir 2>/dev/null)
if [ -n "$COMMON_DIR" ] && [ -n "$GIT_DIR" ] && [ "$COMMON_DIR" != "$GIT_DIR" ]; then
  WORKTREE=$(basename "$TOPLEVEL")
fi

# Strip known prefixes from branch name
if [ -n "$BRANCH" ]; then
  BRANCH="${BRANCH#kyle/}"
  BRANCH="${BRANCH#kylewaldner/}"
  BRANCH="${BRANCH#kylewaldner02/}"
  # Truncate to 37 chars + "..." if longer
  if [ ${#BRANCH} -gt 37 ]; then
    BRANCH="${BRANCH:0:37}..."
  fi
fi

# Build worktree segment
WT_SEG=""
if [ -n "$WORKTREE" ]; then
  WT_SEG=$(printf ' \033[32m[%s]\033[0m' "$WORKTREE")
fi

if [ -n "$WORKTREE" ]; then
  # Worktree mode: only show worktree name and context
  if [ "$REMAINING" = "0" ]; then
    printf '\033[32m[%s]\033[0m \033[33m...\033[0m' "$WORKTREE"
  else
    printf '\033[32m[%s]\033[0m \033[33m%s%% context remaining\033[0m' "$WORKTREE" "$REMAINING"
  fi
elif [ "$REMAINING" = "0" ]; then
  if [ -n "$BRANCH" ]; then
    printf '\033[36m%s\033[0m \033[35m%s\033[0m \033[33m...\033[0m' "$DIR" "$BRANCH"
  else
    printf '\033[36m%s\033[0m \033[33m...\033[0m' "$DIR"
  fi
else
  if [ -n "$BRANCH" ]; then
    printf '\033[36m%s\033[0m \033[35m%s\033[0m \033[33m%s%% context remaining\033[0m' "$DIR" "$BRANCH" "$REMAINING"
  else
    printf '\033[36m%s\033[0m \033[33m%s%% context remaining\033[0m' "$DIR" "$REMAINING"
  fi
fi

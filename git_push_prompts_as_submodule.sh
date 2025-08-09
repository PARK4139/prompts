#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------
# git_push_prompts_as_submodule.sh
# One-shot automation for:
#  1) commit & push submodule(s)
#  2) update & push superproject pointer(s)
# Defaults: modules=prompts, branch=main
# Pass-through args go to the Python helper if present.
# Fallback to pure shell if Python helper missing.
# -----------------------------------------------

log() {
  # Always include [PkMessages2025.XXX]
  # shellcheck disable=SC2059
  printf "%s [INFO] [PkMessages2025.LOG] %s\n" "$(date +"%Y-%m-%d %H:%M:%S")" "$*"
}
err() {
  printf "%s [ERROR] [PkMessages2025.LOG] %s\n" "$(date +"%Y-%m-%d %H:%M:%S")" "$*" 1>&2
}

# 1) Ensure we are inside a git repo and jump to repo root
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  err "[PkMessages2025.VALIDATION] Not inside a git repository"
  exit 1
fi

TOP="$(git rev-parse --show-toplevel)"
cd "$TOP"

# 2) Defaults
MODULES="prompts"
BRANCH="main"
SUBMSG=""
SUPERMSG=""
REMOTE_UPDATE="0"

# 3) Parse minimal args (compatible with the Python script)
#    We also keep unknown args to pass through to Python helper.
PASSTHRU=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --modules)
      MODULES="${2:-}"; shift 2 ;;
    --branch)
      BRANCH="${2:-}"; shift 2 ;;
    --submsg)
      SUBMSG="${2:-}"; shift 2 ;;
    --supermsg)
      SUPERMSG="${2:-}"; shift 2 ;;
    --remote-update)
      REMOTE_UPDATE="1"; shift ;;
    --no-merge)
      # kept for pass-through compatibility; fallback shell uses merge-like behavior
      PASSTHRU+=("$1"); shift ;;
    *)
      PASSTHRU+=("$1"); shift ;;
  esac
done

# 4) If Python helper exists, prefer it
PY_HELPER="ensure_git_submodule_pushed.py"
if [[ -f "$PY_HELPER" ]]; then
  log "[PkMessages2025.START] Using $PY_HELPER at $TOP"

  # Build command line
  CMD=(python "$PY_HELPER" --modules "$MODULES" --branch "$BRANCH")
  [[ -n "$SUBMSG"  ]] && CMD+=(--submsg "$SUBMSG")
  [[ -n "$SUPERMSG" ]] && CMD+=(--supermsg "$SUPERMSG")
  [[ "$REMOTE_UPDATE" == "1" ]] && CMD+=(--remote-update)
  # pass through any unknown flags for forward-compat
  CMD+=("${PASSTHRU[@]}")

  log "[PkMessages2025.EXEC] ${CMD[*]}"
  exec "${CMD[@]}"
fi

# 5) Fallback: pure shell implementation
log "[PkMessages2025.START] Python helper not found, using shell fallback"
log "[PkMessages2025.PARAM] modules=${MODULES} branch=${BRANCH} remote_update=${REMOTE_UPDATE}"

# helper: run a git command in a specific cwd
run_git() {
  local dir="$1"; shift
  ( cd "$dir" && git "$@" )
}

# ensure timestamped default messages if not set
TS="$(date +"%Y-%m-%d %H:%M:%S")"
[[ -z "$SUBMSG"   ]] && SUBMSG="chore: update submodule content [${TS}]"
[[ -z "$SUPERMSG" ]] && SUPERMSG="chore: update submodule pointer(s) [${TS}]"

# split comma-separated MODULES into an array
IFS=',' read -r -a MOD_ARR <<< "$MODULES"

UPDATED_ANY=0

for MOD in "${MOD_ARR[@]}"; do
  MOD="$(echo "$MOD" | xargs)"  # trim
  [[ -z "$MOD" ]] && continue

  # Validate submodule
  if [[ -z "$(git submodule status -- "$MOD" 2>/dev/null)" ]]; then
    err "[PkMessages2025.VALIDATION] $MOD is not a submodule (at $TOP)"
    exit 1
  fi

  ABS_MOD="$TOP/$MOD"
  if [[ ! -d "$ABS_MOD/.git" && ! -f "$ABS_MOD/.git" ]]; then
    err "[PkMessages2025.VALIDATION] Submodule worktree not found: $ABS_MOD"
    exit 1
  fi

  log "[PkMessages2025.SUBMODULE] Processing $MOD"

  # Optional: fetch latest for tracked branch (approx of --remote --merge)
  if [[ "$REMOTE_UPDATE" == "1" ]]; then
    log "[PkMessages2025.SUBMODULE] Updating from remote tracked branch for $MOD"
    git submodule update --remote --merge -- "$MOD"
  fi

  # Ensure branch
  CUR_BRANCH="$(run_git "$ABS_MOD" rev-parse --abbrev-ref HEAD || true)"
  if [[ "$CUR_BRANCH" != "$BRANCH" ]]; then
    log "[PkMessages2025.SUBMODULE] Checkout $BRANCH in $MOD (current=$CUR_BRANCH)"
    run_git "$ABS_MOD" fetch origin "$BRANCH" || true
    run_git "$ABS_MOD" checkout "$BRANCH"
    run_git "$ABS_MOD" pull --ff-only origin "$BRANCH" || true
  else
    # sync with remote
    run_git "$ABS_MOD" fetch origin "$BRANCH" || true
    run_git "$ABS_MOD" pull --ff-only origin "$BRANCH" || true
  fi

  # Commit if dirty
  if [[ -n "$(run_git "$ABS_MOD" status --porcelain)" ]]; then
    log "[PkMessages2025.SUBMODULE] Committing changes in $MOD"
    run_git "$ABS_MOD" add -A
    run_git "$ABS_MOD" commit -m "$SUBMSG"
    UPDATED_ANY=1
  else
    log "[PkMessages2025.SUBMODULE] No changes to commit in $MOD"
  fi

  # Push submodule branch (idempotent)
  log "[PkMessages2025.SUBMODULE] Pushing $MOD -> origin/$BRANCH"
  run_git "$ABS_MOD" push origin "$BRANCH"

  # Stage submodule pointer in superproject
  git add -- "$MOD"
done

# Commit pointer(s) if any staged changes exist
if [[ -n "$(git status --porcelain)" ]]; then
  log "[PkMessages2025.SUPERPROJECT] Committing pointer update(s)"
  git commit -m "$SUPERMSG"
  log "[PkMessages2025.SUPERPROJECT] Pushing superproject"
  git push
  UPDATED_ANY=1
else
  log "[PkMessages2025.SUPERPROJECT] No pointer updates"
fi

if [[ "$UPDATED_ANY" -eq 1 ]]; then
  log "[PkMessages2025.DONE] Completed with updates"
else
  log "[PkMessages2025.DONE] Nothing to update"
fi

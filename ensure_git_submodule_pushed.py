#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Run inside the submodule directory (e.g., prompts/).

Flow:
1) (optional) pull latest for the target branch
2) commit & push submodule
3) if superproject exists, stage submodule pointer, commit & push
"""

from pathlib import Path

def ensure_pk_logging_initialized_fallback(module_file: str):
    # lazy
    import logging
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] [PkMessages2025.LOG] %(message)s"
    )
    return logging.getLogger(Path(module_file).stem)

# Try user’s initializer (as requested)
try:
    from pk_logging import ensure_pk_logging_initialized  # type: ignore
    _LOGGER = ensure_pk_logging_initialized(__file__)
except Exception:
    _LOGGER = ensure_pk_logging_initialized_fallback(__file__)

def run(cmd: list[str], cwd: Path | None = None, check: bool = True) -> str:
    # lazy
    import subprocess, textwrap
    r = subprocess.run(cmd, cwd=str(cwd) if cwd else None,
                       capture_output=True, text=True, shell=False)
    if check and r.returncode != 0:
        raise RuntimeError(textwrap.dedent(
            f"""[PkMessages2025.SUBPROCESS_ERROR] cmd={cmd}
[PkMessages2025.STDOUT] {r.stdout.strip()}
[PkMessages2025.STDERR] {r.stderr.strip()}"""
        ))
    return (r.stdout or "").strip()

def git_dirty(cwd: Path) -> bool:
    res = run(["git", "status", "--porcelain"], cwd=cwd, check=False)
    return bool(res.strip())

def ensure_branch_checked_out(cwd: Path, branch: str):
    cur = run(["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd=cwd, check=False)
    if cur != branch:
        run(["git", "fetch", "origin", branch], cwd=cwd, check=False)
        run(["git", "checkout", branch], cwd=cwd)
    run(["git", "pull", "--ff-only", "origin", branch], cwd=cwd, check=False)

def commit_if_needed(cwd: Path, message: str) -> bool:
    if not git_dirty(cwd):
        _LOGGER.info("[PkMessages2025.SUBMODULE] No changes to commit at %s", cwd)
        return False
    run(["git", "add", "-A"], cwd=cwd)
    run(["git", "commit", "-m", message], cwd=cwd)
    _LOGGER.info("[PkMessages2025.SUBMODULE] Committed changes at %s", cwd)
    return True

def push_branch(cwd: Path, branch: str):
    run(["git", "push", "origin", branch], cwd=cwd)
    _LOGGER.info("[PkMessages2025.SUBMODULE] Pushed origin/%s from %s", branch, cwd)

def get_super_root(sub_root: Path) -> Path | None:
    # Returns superproject working tree path if this repo is a submodule; else None
    out = run(["git", "rev-parse", "--show-superproject-working-tree"], cwd=sub_root, check=False)
    return Path(out).resolve() if out else None

def update_super_pointer(super_root: Path, sub_root: Path, message: str) -> bool:
    # Stage submodule directory relative path in superproject
    rel = sub_root.resolve().relative_to(super_root.resolve())
    run(["git", "add", str(rel)], cwd=super_root)
    status = run(["git", "status", "--porcelain"], cwd=super_root, check=False)
    if not status.strip():
        _LOGGER.info("[PkMessages2025.SUPERPROJECT] No pointer updates to commit")
        return False
    run(["git", "commit", "-m", message], cwd=super_root)
    _LOGGER.info("[PkMessages2025.SUPERPROJECT] Committed pointer update(s)")
    run(["git", "push"], cwd=super_root)
    _LOGGER.info("[PkMessages2025.SUPERPROJECT] Pushed superproject")
    return True

def maybe_remote_update(sub_root: Path, merge: bool):
    args = ["git", "submodule", "update", "--remote"]
    if merge:
        args.append("--merge")
    # When running inside submodule, we can mimic by a simple fetch+merge fast-forward
    # but easiest is: fetch & ff-only pull on current branch (done in ensure_branch_checked_out)
    # Keep placeholder for interface parity.
    _ = (sub_root, args)  # no-op

def main():
    # lazy
    import argparse
    from datetime import datetime

    parser = argparse.ArgumentParser(
        description="Commit & push this submodule, then update superproject pointer."
    )
    parser.add_argument("--branch", default="main", help="Submodule branch to use (default: main)")
    parser.add_argument("--submsg", default=None, help="Commit message for submodule")
    parser.add_argument("--supermsg", default=None, help="Commit message for superproject pointer")
    parser.add_argument("--remote-update", action="store_true",
                        help="Fetch+FF pull before commit (latest from origin/<branch>)")
    parser.add_argument("--no-merge", action="store_true",
                        help="No-op here (kept for CLI compatibility)")
    args = parser.parse_args()

    sub_root = Path(".").resolve()
    # Verify we are inside a git repo (submodule)
    top = run(["git", "rev-parse", "--show-toplevel"], cwd=sub_root)
    sub_root = Path(top).resolve()

    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    submsg = args.submsg or f"chore: update submodule content [{ts}]"
    supermsg = args.supermsg or f"chore: update submodule pointer [{ts}]"

    _LOGGER.info("[PkMessages2025.START] Submodule at %s", sub_root)

    # 1) optional remote update + ensure branch
    if args.remote_update:
        maybe_remote_update(sub_root, merge=(not args.no_merge))
    ensure_branch_checked_out(sub_root, args.branch)

    # 2) commit & push submodule
    committed = commit_if_needed(sub_root, submsg)
    push_branch(sub_root, args.branch)

    # 3) superproject pointer update (if we are actually a submodule)
    super_root = get_super_root(sub_root)
    if super_root is None:
        _LOGGER.info("[PkMessages2025.INFO] No superproject detected. Done.")
        _LOGGER.info("[PkMessages2025.DONE] %s", "Updated" if committed else "Nothing to update")
        return

    _LOGGER.info("[PkMessages2025.SUPERPROJECT] Root detected at %s", super_root)
    pushed = update_super_pointer(super_root, sub_root, supermsg)

    if committed or pushed:
        _LOGGER.info("[PkMessages2025.DONE] Completed with updates")
    else:
        _LOGGER.info("[PkMessages2025.DONE] Nothing to update")

if __name__ == "__main__":
    main()

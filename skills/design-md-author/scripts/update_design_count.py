#!/usr/bin/env python3
"""Sync README DESIGN.md count badge with actual folder count."""

from __future__ import annotations

import os
import re
import shutil
import subprocess
from pathlib import Path


BADGE_RE = re.compile(r"(DESIGN\.md%20count-)(\d+)(-[0-9a-zA-Z]+)")


def run_git(args: list[str], cwd: Path | None = None) -> None:
    subprocess.run(
        args,
        cwd=str(cwd) if cwd else None,
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.PIPE,
        text=True,
    )


def bootstrap_cache_repo(cache_root: Path, repo_url: str, repo_ref: str) -> None:
    if shutil.which("git") is None:
        raise SystemExit("git is required to auto-fetch design-md.")

    cache_root.parent.mkdir(parents=True, exist_ok=True)
    design_root = cache_root / "design-md"

    if design_root.exists():
        return

    if (cache_root / ".git").exists():
        try:
            run_git(["git", "sparse-checkout", "set", "design-md", "README.md"], cwd=cache_root)
        except subprocess.CalledProcessError:
            pass
        run_git(["git", "fetch", "--depth", "1", "origin", repo_ref], cwd=cache_root)
        run_git(["git", "checkout", "-q", "FETCH_HEAD"], cwd=cache_root)
    else:
        if cache_root.exists():
            if any(cache_root.iterdir()):
                raise SystemExit(
                    f"Cache root exists but is not usable: {cache_root}. "
                    "Set DESIGN_MD_ROOT or clean DESIGN_MD_CACHE_ROOT."
                )
            shutil.rmtree(cache_root, ignore_errors=True)
        run_git(
            [
                "git",
                "clone",
                "--depth",
                "1",
                "--filter=blob:none",
                "--sparse",
                repo_url,
                str(cache_root),
            ]
        )
        run_git(["git", "sparse-checkout", "set", "design-md", "README.md"], cwd=cache_root)
        if repo_ref != "main":
            run_git(["git", "fetch", "--depth", "1", "origin", repo_ref], cwd=cache_root)
            run_git(["git", "checkout", "-q", "FETCH_HEAD"], cwd=cache_root)

    if not design_root.exists():
        raise SystemExit(f"Auto-fetch completed but design-md is missing in {cache_root}")


def resolve_design_root(script_dir: Path) -> Path:
    env_root = os.getenv("DESIGN_MD_ROOT")
    if env_root:
        root = Path(env_root).expanduser().resolve()
        if not root.exists():
            raise SystemExit(f"DESIGN_MD_ROOT is set but missing: {root}")
        return root

    local_root = (script_dir.parents[2] / "design-md").resolve()
    if local_root.exists():
        return local_root

    default_cache_root = Path(os.getenv("CODEX_HOME", str(Path.home() / ".codex"))) / "data" / "awesome-design-md"
    cache_root = Path(os.getenv("DESIGN_MD_CACHE_ROOT", str(default_cache_root))).expanduser().resolve()
    design_root = cache_root / "design-md"

    if design_root.exists():
        return design_root

    if os.getenv("DESIGN_MD_AUTO_FETCH", "1") != "1":
        raise SystemExit(
            "design-md not found locally and auto-fetch is disabled. "
            "Set DESIGN_MD_ROOT or DESIGN_MD_AUTO_FETCH=1."
        )

    repo_url = os.getenv("DESIGN_MD_REPO_URL", "https://github.com/VoltAgent/awesome-design-md.git")
    repo_ref = os.getenv("DESIGN_MD_REPO_REF", "main")
    bootstrap_cache_repo(cache_root, repo_url, repo_ref)
    return design_root


def resolve_readme_path(design_root: Path, script_dir: Path) -> Path:
    env_readme = os.getenv("DESIGN_MD_README")
    if env_readme:
        readme_path = Path(env_readme).expanduser().resolve()
        if not readme_path.exists():
            raise SystemExit(f"DESIGN_MD_README is set but missing: {readme_path}")
        return readme_path

    candidate = (design_root.parent / "README.md").resolve()
    if candidate.exists():
        return candidate

    fallback = (script_dir.parents[2] / "README.md").resolve()
    return fallback


def main() -> int:
    script_dir = Path(__file__).resolve().parent
    design_root = resolve_design_root(script_dir)
    readme_path = resolve_readme_path(design_root, script_dir)

    if not design_root.exists():
        raise SystemExit(f"design-md directory not found: {design_root}.")
    if not readme_path.exists():
        raise SystemExit(
            f"README.md not found: {readme_path}. "
            "Set DESIGN_MD_README to your catalog README path."
        )

    count = sum(1 for p in design_root.iterdir() if p.is_dir())
    original = readme_path.read_text(encoding="utf-8")
    updated, replacements = BADGE_RE.subn(rf"\g<1>{count}\g<3>", original, count=1)

    if replacements == 0:
        raise SystemExit("Could not find DESIGN.md count badge pattern in README.md")

    if updated != original:
        readme_path.write_text(updated, encoding="utf-8")
        print(f"Updated README badge count to {count}.")
    else:
        print(f"README badge already up to date ({count}).")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

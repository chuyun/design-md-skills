#!/usr/bin/env python3
"""Recommend DESIGN.md styles based on a natural-language request."""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


@dataclass
class StyleEntry:
    slug: str
    name: str
    category: str
    summary: str


README_BULLET_RE = re.compile(
    r"^- \[\*\*(?P<name>.+?)\*\*\]\((?P<url>.+?/design-md/(?P<slug>[^/]+)/?)\)\s*-\s*(?P<summary>.+)$"
)
README_CATEGORY_RE = re.compile(r"^###\s+(?P<category>.+?)\s*$")
TOKEN_RE = re.compile(r"[a-z0-9][a-z0-9\.\-]*")

DEFAULT_FALLBACK_ORDER = [
    "vercel",
    "stripe",
    "notion",
    "airbnb",
    "supabase",
    "figma",
    "apple",
    "tesla",
]

TOKEN_EXPANSIONS = {
    "ai": ["machine", "learning", "llm"],
    "llm": ["ai", "machine", "learning"],
    "fintech": ["finance", "banking", "crypto"],
    "crypto": ["fintech", "finance", "trading"],
    "dashboard": ["analytics", "monitoring", "data"],
    "minimal": ["clean", "monochrome", "simple"],
    "dark": ["black", "cinematic", "neon"],
    "premium": ["luxury", "editorial", "high", "end"],
    "developer": ["tools", "platform", "technical", "code"],
    "startup": ["saas", "developer", "modern", "product"],
}

QUERY_HINTS = {
    "极简": ["minimal", "clean", "monochrome"],
    "简约": ["minimal", "clean"],
    "深色": ["dark", "black", "cinematic"],
    "开发者": ["developer", "technical", "code", "tooling"],
    "科技": ["developer", "technical", "ai"],
    "金融": ["fintech", "finance", "banking", "crypto"],
    "汽车": ["car", "automotive", "luxury"],
    "电商": ["consumer", "conversion", "retail"],
    "企业": ["enterprise", "professional", "structured"],
    "编辑器": ["developer", "code", "tooling"],
    "官网": ["marketing", "landing", "brand"],
}


def tokenize(text: str) -> set[str]:
    return {t for t in TOKEN_RE.findall(text.lower()) if len(t) > 1}


def expand_query_terms(query: str) -> set[str]:
    terms = set(tokenize(query))
    for token in list(terms):
        for extra in TOKEN_EXPANSIONS.get(token, []):
            terms.update(tokenize(extra))
    for hint, extras in QUERY_HINTS.items():
        if hint in query:
            for extra in extras:
                terms.update(tokenize(extra))
    return terms


def parse_entries_from_readme(readme_path: Path | None) -> list[StyleEntry]:
    entries: list[StyleEntry] = []
    current_category = "Uncategorized"
    if readme_path is None or not readme_path.exists():
        return entries

    for raw_line in readme_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        category_match = README_CATEGORY_RE.match(line)
        if category_match:
            current_category = category_match.group("category")
            continue

        bullet_match = README_BULLET_RE.match(line)
        if not bullet_match:
            continue

        entries.append(
            StyleEntry(
                slug=bullet_match.group("slug").strip(),
                name=bullet_match.group("name").strip(),
                category=current_category,
                summary=bullet_match.group("summary").strip(),
            )
        )
    return entries


def merge_with_directory_scan(entries: Iterable[StyleEntry], design_root: Path) -> list[StyleEntry]:
    by_slug = {entry.slug: entry for entry in entries}
    if not design_root.exists():
        return list(by_slug.values())

    for path in sorted(design_root.iterdir()):
        if not path.is_dir():
            continue
        slug = path.name
        if slug in by_slug:
            continue
        by_slug[slug] = StyleEntry(
            slug=slug,
            name=slug,
            category="Uncategorized",
            summary="No README summary found. Inspect DESIGN.md directly.",
        )

    return sorted(by_slug.values(), key=lambda e: e.slug)


def score_entry(entry: StyleEntry, query_terms: set[str], query_raw: str) -> int:
    score = 0
    slug_tokens = tokenize(entry.slug.replace(".", " "))
    name_tokens = tokenize(entry.name)
    category_tokens = tokenize(entry.category)
    summary_tokens = tokenize(entry.summary)

    for term in query_terms:
        if term in slug_tokens:
            score += 8
            continue
        if term in name_tokens:
            score += 7
            continue
        if term in category_tokens:
            score += 5
            continue
        if term in summary_tokens:
            score += 3

    query_lc = query_raw.lower().strip()
    if query_lc and query_lc in f"{entry.name} {entry.summary}".lower():
        score += 10
    if query_lc and query_lc in entry.slug.lower():
        score += 12

    return score


def choose_fallback(entries: list[StyleEntry], top_n: int) -> list[StyleEntry]:
    by_slug = {entry.slug: entry for entry in entries}
    picked: list[StyleEntry] = []
    for slug in DEFAULT_FALLBACK_ORDER:
        if slug in by_slug:
            picked.append(by_slug[slug])
    if len(picked) < top_n:
        for entry in entries:
            if entry in picked:
                continue
            picked.append(entry)
            if len(picked) >= top_n:
                break
    return picked[:top_n]


def format_table(rows: list[dict]) -> str:
    header = f"{'rank':<5} {'score':<5} {'slug':<16} {'category':<32} summary"
    lines = [header, "-" * len(header)]
    for row in rows:
        category = row["category"][:31]
        summary = row["summary"]
        lines.append(
            f"{row['rank']:<5} {row['score']:<5} {row['slug']:<16} {category:<32} {summary}"
        )
    return "\n".join(lines)


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


def resolve_readme_path(design_root: Path, script_dir: Path) -> Path | None:
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
    if fallback.exists():
        return fallback
    return None


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Recommend styles from awesome-design-md based on a user request. "
            "Supports DESIGN_MD_ROOT and auto-bootstrap cache "
            "(DESIGN_MD_AUTO_FETCH / DESIGN_MD_CACHE_ROOT / DESIGN_MD_REPO_URL / DESIGN_MD_REPO_REF). "
            "Use DESIGN_MD_README for an external catalog README."
        )
    )
    parser.add_argument("query", nargs="+", help="Natural language request.")
    parser.add_argument("--top", type=int, default=6, help="Number of results to return.")
    parser.add_argument("--json", action="store_true", help="Output JSON.")
    args = parser.parse_args()

    top_n = max(1, min(args.top, 20))
    query = " ".join(args.query).strip()

    script_dir = Path(__file__).resolve().parent
    design_root = resolve_design_root(script_dir)
    readme_path = resolve_readme_path(design_root, script_dir)

    entries = merge_with_directory_scan(parse_entries_from_readme(readme_path), design_root)
    if not entries:
        raise SystemExit("No styles found. Expected design-md/ to contain style directories.")

    query_terms = expand_query_terms(query)
    scored = [
        (entry, score_entry(entry, query_terms, query))
        for entry in entries
    ]
    scored.sort(key=lambda pair: (-pair[1], pair[0].slug))

    if scored and scored[0][1] > 0:
        chosen = scored[:top_n]
    else:
        chosen = [(entry, 0) for entry in choose_fallback(entries, top_n)]

    rows = []
    for idx, (entry, score) in enumerate(chosen, start=1):
        rows.append(
            {
                "rank": idx,
                "score": score,
                "slug": entry.slug,
                "name": entry.name,
                "category": entry.category,
                "summary": entry.summary,
                "source": str(design_root / entry.slug / "DESIGN.md"),
            }
        )

    if args.json:
        print(json.dumps({"query": query, "results": rows}, ensure_ascii=False, indent=2))
    else:
        print(format_table(rows))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

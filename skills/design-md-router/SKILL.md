---
name: design-md-router
description: Route design-style requests to the right DESIGN.md profile in this repository, then apply it to a target project. Use when a user asks for style recommendations, wants a specific brand-inspired DESIGN.md, wants DESIGN.md copied into another project, or needs library validation for design-md entries.
---

Use this skill to select and apply styles from the local `design-md/` library.
By default, this skill includes a bundled `design-md` dataset under `assets/` for offline use.

## External Data Source

Resolution order:
1. `DESIGN_MD_ROOT`
2. Repository-local `design-md/`
3. Bundled `assets/design-md` (default packaged dataset)
4. Auto-fetched cache

When this skill is installed outside this repository, you can still set:
- `DESIGN_MD_ROOT`: absolute path to your shared `design-md/` directory.
- `DESIGN_MD_README` (optional): absolute path to catalog `README.md` for richer recommendations.

Or use zero-config bootstrap:
- `DESIGN_MD_AUTO_FETCH=1` (default): auto-clone into cache if missing.
- `DESIGN_MD_CACHE_ROOT` (optional): override cache root repo path.
- `DESIGN_MD_REPO_URL` / `DESIGN_MD_REPO_REF` (optional): override source repository.

## Core Workflow

1. Understand user intent, including product type, mood, industry, and light or dark preference.
2. Run `python3 scripts/recommend_style.py "<user request>" --top 6` to rank candidate styles.
3. If needed, run `bash scripts/list_styles.sh` to show all available style slugs.
4. Present 3 to 6 candidates with short rationale and ask user to pick one.
5. Apply the chosen style with `bash scripts/apply_style.sh <style-slug> <target-dir>`.
6. Run `bash scripts/validate_library.sh` when validating or maintaining this repository.

## Commands

`bash scripts/list_styles.sh`
- List all available style slugs from `design-md/`.
- Use `--count` to print only the style count.
- Use `--with-path` to include absolute source paths.

`python3 scripts/recommend_style.py "<request>" [--top N] [--json]`
- Rank styles by matching request text with README category metadata and style summaries.
- Parse this repository's `README.md` so recommendations evolve as the collection changes.

`bash scripts/apply_style.sh <style-slug> [target-dir] [--include-preview] [--include-readme] [--force]`
- Copy `design-md/<style>/DESIGN.md` into `<target-dir>/DESIGN.md`.
- Optionally copy preview HTML files and style README.
- Refuse overwrite unless `--force` is provided.

`bash scripts/validate_library.sh`
- Verify every `design-md/<style>/` directory contains non-empty required files:
  `DESIGN.md`, `README.md`, `preview.html`, `preview-dark.html`.

## Response Guidelines

1. Keep style rationale concrete, citing palette, typography, and atmosphere.
2. Prefer explicit tradeoffs:
   - Minimal + technical: `vercel`, `linear.app`, `stripe`
   - Warm + approachable: `airbnb`, `intercom`, `notion`
   - Bold + high-energy: `tesla`, `nvidia`, `ferrari`, `lamborghini`
3. Confirm the destination path before apply when the target project is ambiguous.
4. After apply, report exactly which files were copied.

## References

- Use `references/catalog.md` for quick category-level guidance.
- Use `design-md/<style>/DESIGN.md` as the authoritative style reference.

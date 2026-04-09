---
name: design-md-author
description: Author or maintain DESIGN.md style packs in this repository. Use when a user asks to add a new site folder under design-md, improve an existing DESIGN.md, regenerate starter files, sync README design count, or validate contribution completeness for DESIGN.md/README/preview files.
---

Use this skill to create and maintain style entries in the `design-md/` collection.
By default, this skill includes a bundled `design-md` dataset under `assets/` for offline use.

## External Data Source

Resolution order:
1. `DESIGN_MD_ROOT`
2. Repository-local `design-md/`
3. Bundled `assets/design-md` (default packaged dataset)
4. Auto-fetched cache

When this skill is installed outside this repository, you can still set:
- `DESIGN_MD_ROOT`: absolute path to your shared `design-md/` directory.
- `DESIGN_MD_README` (optional): absolute path to the catalog `README.md` used for badge sync.

Or use zero-config bootstrap:
- `DESIGN_MD_AUTO_FETCH=1` (default): auto-clone into cache if missing.
- `DESIGN_MD_CACHE_ROOT` (optional): override cache root repo path.
- `DESIGN_MD_REPO_URL` / `DESIGN_MD_REPO_REF` (optional): override source repository.

## Core Workflow

1. Confirm target slug and source website (or existing style folder to improve).
2. Run `bash scripts/init_style.sh <slug> --name "<Display Name>" --url "<https://...>" --dry-run` to preview changes.
3. Run without `--dry-run` to scaffold files after confirmation.
4. Fill or refine `DESIGN.md` with accurate tokens and style rules.
5. Ensure `preview.html` and `preview-dark.html` reflect token changes.
6. Run `python3 scripts/update_design_count.py` if collection size changed.
7. Run `bash ../design-md-router/scripts/validate_library.sh` to verify required files across the library.

## Commands

`bash scripts/init_style.sh <slug> --name "<Display Name>" --url "<https://...>" [--category "<Category>"] [--force] [--dry-run]`
- Create `design-md/<slug>/` with these files:
  `DESIGN.md`, `README.md`, `preview.html`, `preview-dark.html`.
- Validate slug format (lowercase letters, digits, dots, hyphens).
- Refuse overwriting existing files unless `--force`.
- Use `--dry-run` to inspect target paths without writing files.

`python3 scripts/update_design_count.py`
- Recompute style folder count from `design-md/`.
- Update the README badge `DESIGN.md count-<N>-...` automatically.

## Authoring Standards

1. Keep `DESIGN.md` in the 9-section structure already used in this repository.
2. Use concrete tokens and behaviors, not generic adjectives.
3. Align `README.md` summary with the style's actual atmosphere and use case.
4. Keep previews minimal but representative for color, type, and component feel.
5. Validate file completeness before finalizing.

## References

- Use `references/publishing-checklist.md` before finishing a new style entry.
- Use `design-md/<slug>/DESIGN.md` files from existing entries as style examples.

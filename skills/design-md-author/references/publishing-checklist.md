# Publishing Checklist

Use this checklist before opening a PR for a new or updated style.

## Required Files

1. `design-md/<slug>/DESIGN.md` exists and is non-empty.
2. `design-md/<slug>/README.md` exists and is non-empty.
3. `design-md/<slug>/preview.html` exists and is non-empty.
4. `design-md/<slug>/preview-dark.html` exists and is non-empty.

## Content Quality

1. `DESIGN.md` follows the 9-section format used across the repository.
2. Color tokens include semantic roles, not only hex dumps.
3. Typography hierarchy includes sizes, weights, and usage notes.
4. Component styles include interactive states or behavioral guidance.
5. Responsive behavior and do/don't rules are explicit.

## Preview Quality

1. `preview.html` shows palette, type, buttons, and cards in light surface context.
2. `preview-dark.html` presents equivalent tokens for dark context.
3. Preview values are consistent with `DESIGN.md`.

## Repository Sync

1. Run `python3 skills/design-md-author/scripts/update_design_count.py`.
2. Run `bash skills/design-md-router/scripts/validate_library.sh`.
3. Confirm README collection section includes the style link and summary.

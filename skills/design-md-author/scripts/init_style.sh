#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  init_style.sh <slug> --name "<Display Name>" --url "<https://example.com>" [--category "<Category>"] [--force] [--dry-run]

Environment:
  DESIGN_MD_ROOT       Optional path to external design-md directory.
  DESIGN_MD_AUTO_FETCH Auto-fetch cache if missing (default: 1, set 0 to disable).
  DESIGN_MD_CACHE_ROOT Cache repo root (default: ${CODEX_HOME:-$HOME/.codex}/data/awesome-design-md).
  DESIGN_MD_REPO_URL   Source repository URL for bootstrap.
  DESIGN_MD_REPO_REF   Source repository ref for bootstrap (default: main).

Options:
  --name        Display name for README title (required).
  --url         Source website URL (required).
  --category    Optional category label for README context.
  --force       Overwrite existing files.
  --dry-run     Print planned paths only, do not write files.
  -h, --help    Show this help message.
EOF
}

if [[ $# -lt 1 ]]; then
  usage >&2
  exit 1
fi

slug="$1"
shift

if [[ ! "${slug}" =~ ^[a-z0-9][a-z0-9\.-]*$ ]]; then
  echo "Error: invalid slug '${slug}'. Use lowercase letters, digits, dots, and hyphens." >&2
  exit 1
fi

name=""
url=""
category=""
force=0
dry_run=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)
      name="${2:-}"
      shift 2
      ;;
    --url)
      url="${2:-}"
      shift 2
      ;;
    --category)
      category="${2:-}"
      shift 2
      ;;
    --force)
      force=1
      shift
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown option '$1'" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "${name}" || -z "${url}" ]]; then
  echo "Error: --name and --url are required." >&2
  usage >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${script_dir}/bootstrap_design_md.sh"
design_root="$(ensure_design_md_root)"
style_dir="${design_root}/${slug}"

design_file="${style_dir}/DESIGN.md"
readme_file="${style_dir}/README.md"
preview_file="${style_dir}/preview.html"
preview_dark_file="${style_dir}/preview-dark.html"

echo "Target directory: ${style_dir}"
echo "Files:"
echo "  - ${design_file}"
echo "  - ${readme_file}"
echo "  - ${preview_file}"
echo "  - ${preview_dark_file}"

if (( dry_run )); then
  echo "Dry run only. No files written."
  exit 0
fi

mkdir -p "${style_dir}"

if (( force == 0 )); then
  for path in "${design_file}" "${readme_file}" "${preview_file}" "${preview_dark_file}"; do
    if [[ -e "${path}" ]]; then
      echo "Error: ${path} already exists. Use --force to overwrite." >&2
      exit 1
    fi
  done
fi

cat > "${design_file}" <<EOF
# Design System Inspiration of ${name}

## 1. Visual Theme & Atmosphere

Describe the overall mood, visual density, and brand personality.

## 2. Color Palette & Roles

List core colors with semantic usage.

## 3. Typography Rules

Document font families, type scale, weights, and spacing behavior.

## 4. Component Stylings

Define buttons, cards, navigation, inputs, and interaction states.

## 5. Layout Principles

Specify spacing scale, grid, and whitespace strategy.

## 6. Depth & Elevation

Define border, shadow, and layer hierarchy.

## 7. Do's and Don'ts

Add practical style guardrails and anti-patterns.

## 8. Responsive Behavior

Document breakpoints and mobile adaptations.

## 9. Agent Prompt Guide

Provide concise prompts for AI implementation.
EOF

category_sentence=""
if [[ -n "${category}" ]]; then
  category_sentence=" Category: ${category}."
fi

cat > "${readme_file}" <<EOF
# ${name} Inspired Design System

[DESIGN.md](https://github.com/VoltAgent/awesome-design-md/blob/main/design-md/${slug}/DESIGN.md) extracted from the public [${name}](${url}) website.${category_sentence} This is not the official design system. Colors, fonts, and spacing may not be 100% accurate. But it's a good starting point for building something similar.

## Files

| File | Description |
|------|-------------|
| \`DESIGN.md\` | Complete design system documentation (9 sections) |
| \`preview.html\` | Interactive design token catalog (light) |
| \`preview-dark.html\` | Interactive design token catalog (dark) |

Use [DESIGN.md](https://github.com/VoltAgent/awesome-design-md/blob/main/design-md/${slug}/DESIGN.md) to use as a reference for AI agents (Claude, Cursor, Stitch) to generate UI that looks like the ${name} design language.
EOF

cat > "${preview_file}" <<EOF
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>${name} Design Preview</title>
    <style>
      :root {
        --bg: #ffffff;
        --fg: #111111;
        --surface: #f5f5f5;
        --accent: #2563eb;
      }
      * { box-sizing: border-box; }
      body {
        margin: 0;
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        background: var(--bg);
        color: var(--fg);
      }
      main { max-width: 960px; margin: 40px auto; padding: 0 20px; }
      .swatch { display: inline-block; width: 120px; height: 72px; border-radius: 10px; margin-right: 12px; border: 1px solid #ddd; }
      .card { background: var(--surface); border-radius: 12px; padding: 20px; margin-top: 20px; }
      .btn { display: inline-block; margin-top: 16px; background: var(--accent); color: #fff; padding: 10px 14px; border-radius: 10px; text-decoration: none; font-weight: 600; }
      code { background: #eef2ff; padding: 2px 6px; border-radius: 6px; }
    </style>
  </head>
  <body>
    <main>
      <h1>${name} Preview (Light)</h1>
      <p>Replace placeholder tokens with real values from <code>DESIGN.md</code>.</p>
      <div class="swatch" style="background:#ffffff"></div>
      <div class="swatch" style="background:#111111"></div>
      <div class="swatch" style="background:#2563eb"></div>
      <div class="card">
        <h2>Component Sample</h2>
        <p>Use this page to quickly verify palette, typography, and component feel.</p>
        <a class="btn" href="#">Primary Action</a>
      </div>
    </main>
  </body>
</html>
EOF

cat > "${preview_dark_file}" <<EOF
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>${name} Design Preview Dark</title>
    <style>
      :root {
        --bg: #0b0b0d;
        --fg: #f5f5f5;
        --surface: #15161a;
        --accent: #60a5fa;
      }
      * { box-sizing: border-box; }
      body {
        margin: 0;
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        background: var(--bg);
        color: var(--fg);
      }
      main { max-width: 960px; margin: 40px auto; padding: 0 20px; }
      .swatch { display: inline-block; width: 120px; height: 72px; border-radius: 10px; margin-right: 12px; border: 1px solid #2a2a33; }
      .card { background: var(--surface); border-radius: 12px; padding: 20px; margin-top: 20px; }
      .btn { display: inline-block; margin-top: 16px; background: var(--accent); color: #001028; padding: 10px 14px; border-radius: 10px; text-decoration: none; font-weight: 700; }
      code { background: #1f2937; padding: 2px 6px; border-radius: 6px; color: #bfdbfe; }
    </style>
  </head>
  <body>
    <main>
      <h1>${name} Preview (Dark)</h1>
      <p>Replace placeholder tokens with real values from <code>DESIGN.md</code>.</p>
      <div class="swatch" style="background:#0b0b0d"></div>
      <div class="swatch" style="background:#f5f5f5"></div>
      <div class="swatch" style="background:#60a5fa"></div>
      <div class="card">
        <h2>Component Sample</h2>
        <p>Use this page to quickly verify palette, typography, and component feel.</p>
        <a class="btn" href="#">Primary Action</a>
      </div>
    </main>
  </body>
</html>
EOF

echo "Scaffold created for '${slug}'."

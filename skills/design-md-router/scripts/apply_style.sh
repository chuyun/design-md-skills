#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  apply_style.sh <style-slug> [target-dir] [--include-preview] [--include-readme] [--force]

Environment:
  DESIGN_MD_ROOT       Optional path to external design-md directory.
  DESIGN_MD_AUTO_FETCH Auto-fetch cache if missing (default: 1, set 0 to disable).
  DESIGN_MD_CACHE_ROOT Cache repo root (default: ${CODEX_HOME:-$HOME/.codex}/data/awesome-design-md).
  DESIGN_MD_REPO_URL   Source repository URL for bootstrap.
  DESIGN_MD_REPO_REF   Source repository ref for bootstrap (default: main).

Examples:
  apply_style.sh vercel /path/to/project
  apply_style.sh airbnb . --include-preview
  apply_style.sh stripe /path/to/project --include-preview --include-readme --force
EOF
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${script_dir}/bootstrap_design_md.sh"
design_root="$(ensure_design_md_root)"

style_slug=""
target_dir=""
include_preview=0
include_readme=0
force=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --include-preview)
      include_preview=1
      shift
      ;;
    --include-readme)
      include_readme=1
      shift
      ;;
    --force)
      force=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --*)
      echo "Error: unknown option '$1'" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [[ -z "${style_slug}" ]]; then
        style_slug="$1"
      elif [[ -z "${target_dir}" ]]; then
        target_dir="$1"
      else
        echo "Error: too many positional arguments." >&2
        usage >&2
        exit 1
      fi
      shift
      ;;
  esac
done

if [[ -z "${style_slug}" ]]; then
  echo "Error: style slug is required." >&2
  usage >&2
  exit 1
fi

if [[ -z "${target_dir}" ]]; then
  target_dir="."
fi

source_dir="${design_root}/${style_slug}"
if [[ ! -d "${source_dir}" ]]; then
  echo "Error: style '${style_slug}' not found under ${design_root}." >&2
  exit 1
fi

mkdir -p "${target_dir}"
target_dir="$(cd "${target_dir}" && pwd)"

source_design="${source_dir}/DESIGN.md"
target_design="${target_dir}/DESIGN.md"

if [[ ! -f "${source_design}" ]]; then
  echo "Error: source DESIGN.md not found at ${source_design}." >&2
  exit 1
fi

if [[ -e "${target_design}" && "${force}" -eq 0 ]]; then
  echo "Error: ${target_design} already exists. Use --force to overwrite." >&2
  exit 1
fi

cp "${source_design}" "${target_design}"
echo "Copied: ${source_design} -> ${target_design}"

if [[ "${include_preview}" -eq 1 ]]; then
  source_preview="${source_dir}/preview.html"
  source_preview_dark="${source_dir}/preview-dark.html"
  target_preview="${target_dir}/${style_slug}-preview.html"
  target_preview_dark="${target_dir}/${style_slug}-preview-dark.html"

  if [[ -e "${target_preview}" && "${force}" -eq 0 ]]; then
    echo "Error: ${target_preview} already exists. Use --force to overwrite." >&2
    exit 1
  fi
  if [[ -e "${target_preview_dark}" && "${force}" -eq 0 ]]; then
    echo "Error: ${target_preview_dark} already exists. Use --force to overwrite." >&2
    exit 1
  fi

  cp "${source_preview}" "${target_preview}"
  cp "${source_preview_dark}" "${target_preview_dark}"
  echo "Copied: ${source_preview} -> ${target_preview}"
  echo "Copied: ${source_preview_dark} -> ${target_preview_dark}"
fi

if [[ "${include_readme}" -eq 1 ]]; then
  source_readme="${source_dir}/README.md"
  target_readme="${target_dir}/${style_slug}-README.md"

  if [[ -e "${target_readme}" && "${force}" -eq 0 ]]; then
    echo "Error: ${target_readme} already exists. Use --force to overwrite." >&2
    exit 1
  fi

  cp "${source_readme}" "${target_readme}"
  echo "Copied: ${source_readme} -> ${target_readme}"
fi

echo "Done: style '${style_slug}' applied to ${target_dir}."

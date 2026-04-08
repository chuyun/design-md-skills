#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  list_styles.sh [--count] [--with-path]

Options:
  DESIGN_MD_ROOT       Optional path to external design-md directory.
  DESIGN_MD_AUTO_FETCH Auto-fetch cache if missing (default: 1, set 0 to disable).
  DESIGN_MD_CACHE_ROOT Cache repo root (default: ${CODEX_HOME:-$HOME/.codex}/data/awesome-design-md).
  DESIGN_MD_REPO_URL   Source repository URL for bootstrap.
  DESIGN_MD_REPO_REF   Source repository ref for bootstrap (default: main).
  --count              Print only the number of available styles.
  --with-path          Print "<slug>\t<absolute path>".
  -h, --help           Show this help message.
EOF
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${script_dir}/bootstrap_design_md.sh"
design_root="$(ensure_design_md_root)"

count_mode=0
with_path_mode=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --count)
      count_mode=1
      shift
      ;;
    --with-path)
      with_path_mode=1
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

if (( count_mode )); then
  find "${design_root}" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' '
  exit 0
fi

while IFS= read -r dir; do
  slug="$(basename "${dir}")"
  if (( with_path_mode )); then
    echo -e "${slug}\t${dir}"
  else
    echo "${slug}"
  fi
done < <(find "${design_root}" -mindepth 1 -maxdepth 1 -type d | sort)

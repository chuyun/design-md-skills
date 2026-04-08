#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${script_dir}/bootstrap_design_md.sh"
design_root="$(ensure_design_md_root)"

required_files=("DESIGN.md" "README.md" "preview.html" "preview-dark.html")
style_count=0
error_count=0

for style_dir in "${design_root}"/*; do
  [[ -d "${style_dir}" ]] || continue
  style_count=$((style_count + 1))
  slug="$(basename "${style_dir}")"

  for file_name in "${required_files[@]}"; do
    file_path="${style_dir}/${file_name}"
    if [[ ! -f "${file_path}" ]]; then
      echo "FAIL ${slug}: missing ${file_name}"
      error_count=$((error_count + 1))
      continue
    fi
    if [[ ! -s "${file_path}" ]]; then
      echo "FAIL ${slug}: empty ${file_name}"
      error_count=$((error_count + 1))
    fi
  done
done

echo "Checked ${style_count} style directories."

if [[ "${error_count}" -gt 0 ]]; then
  echo "Validation failed with ${error_count} issue(s)." >&2
  exit 1
fi

echo "Validation passed. All required files are present and non-empty."

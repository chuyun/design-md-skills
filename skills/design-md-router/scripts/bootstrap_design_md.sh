#!/usr/bin/env bash
set -euo pipefail

# Resolve and optionally bootstrap a design-md directory.
#
# Resolution order:
# 1) DESIGN_MD_ROOT (must exist if set)
# 2) Repository-local design-md (../../../design-md)
# 3) Cache design-md under:
#    - DESIGN_MD_CACHE_ROOT (repo root that contains design-md)
#    - default: ${CODEX_HOME:-$HOME/.codex}/data/awesome-design-md
#
# Auto bootstrap:
# - Enabled by default when cache is missing (DESIGN_MD_AUTO_FETCH=1)
# - Disabled with DESIGN_MD_AUTO_FETCH=0
# - Clone source can be customized:
#   - DESIGN_MD_REPO_URL (default: https://github.com/VoltAgent/awesome-design-md.git)
#   - DESIGN_MD_REPO_REF (default: main)

ensure_design_md_root() {
  local script_dir repo_root local_root resolved_root
  local cache_root cache_design_root auto_fetch repo_url repo_ref

  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  repo_root="$(cd "${script_dir}/../../.." && pwd)"
  local_root="${repo_root}/design-md"

  if [[ -n "${DESIGN_MD_ROOT:-}" ]]; then
    if [[ ! -d "${DESIGN_MD_ROOT}" ]]; then
      echo "Error: DESIGN_MD_ROOT is set but missing: ${DESIGN_MD_ROOT}" >&2
      return 1
    fi
    resolved_root="$(cd "${DESIGN_MD_ROOT}" && pwd)"
    echo "${resolved_root}"
    return 0
  fi

  if [[ -d "${local_root}" ]]; then
    resolved_root="$(cd "${local_root}" && pwd)"
    echo "${resolved_root}"
    return 0
  fi

  cache_root="${DESIGN_MD_CACHE_ROOT:-${CODEX_HOME:-$HOME/.codex}/data/awesome-design-md}"
  cache_design_root="${cache_root}/design-md"
  auto_fetch="${DESIGN_MD_AUTO_FETCH:-1}"
  repo_url="${DESIGN_MD_REPO_URL:-https://github.com/VoltAgent/awesome-design-md.git}"
  repo_ref="${DESIGN_MD_REPO_REF:-main}"

  if [[ -d "${cache_design_root}" ]]; then
    resolved_root="$(cd "${cache_design_root}" && pwd)"
    echo "${resolved_root}"
    return 0
  fi

  if [[ "${auto_fetch}" != "1" ]]; then
    echo "Error: design-md not found locally and auto-fetch is disabled." >&2
    echo "Set DESIGN_MD_ROOT to an existing path, or DESIGN_MD_AUTO_FETCH=1." >&2
    return 1
  fi

  if ! command -v git >/dev/null 2>&1; then
    echo "Error: git is required to auto-fetch design-md." >&2
    return 1
  fi

  mkdir -p "$(dirname "${cache_root}")"

  if [[ -d "${cache_root}/.git" ]]; then
    git -C "${cache_root}" sparse-checkout set design-md README.md >/dev/null 2>&1 || true
    git -C "${cache_root}" fetch --depth 1 origin "${repo_ref}" >/dev/null
    git -C "${cache_root}" checkout -q FETCH_HEAD >/dev/null 2>&1
  elif [[ ! -e "${cache_root}" || -z "$(ls -A "${cache_root}" 2>/dev/null || true)" ]]; then
    rm -rf "${cache_root}"
    git clone --depth 1 --filter=blob:none --sparse "${repo_url}" "${cache_root}" >/dev/null
    git -C "${cache_root}" sparse-checkout set design-md README.md >/dev/null
    if [[ "${repo_ref}" != "main" ]]; then
      git -C "${cache_root}" fetch --depth 1 origin "${repo_ref}" >/dev/null
      git -C "${cache_root}" checkout -q FETCH_HEAD >/dev/null 2>&1
    fi
  else
    echo "Error: cache root exists but is not usable: ${cache_root}" >&2
    echo "Set DESIGN_MD_ROOT or clean DESIGN_MD_CACHE_ROOT." >&2
    return 1
  fi

  if [[ ! -d "${cache_design_root}" ]]; then
    echo "Error: auto-fetch completed but design-md is still missing in ${cache_root}" >&2
    return 1
  fi

  echo "Bootstrapped design-md cache at ${cache_root}" >&2
  resolved_root="$(cd "${cache_design_root}" && pwd)"
  echo "${resolved_root}"
}


#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "${repo_root}/.memory"
scratch_root="$(mktemp -d "${repo_root}/.memory/validate-formulae.XXXXXX")"
trap 'rm -rf "${scratch_root}"' EXIT

stale_foundry_repo="nyrra-labs/nyrra""-foundry-cli"
expected_error="Active Foundry packaging references must use shpitdev/foundry-cli."

assert_stale_reference_rejected() {
  local name="$1"
  local relative_path="$2"
  local fixture="${scratch_root}/${name}"
  local output="${scratch_root}/${name}.log"

  mkdir -p "${fixture}/.github" "${fixture}/docs"
  cp -a "${repo_root}/Formula" "${fixture}/Formula"
  cp -a "${repo_root}/scripts" "${fixture}/scripts"
  cp -a "${repo_root}/.github/." "${fixture}/.github/"
  cp -a "${repo_root}/docs/." "${fixture}/docs/"
  cp "${repo_root}/README.md" "${fixture}/README.md"

  printf '\n# stale upstream: %s\n' "${stale_foundry_repo}" >>"${fixture}/${relative_path}"

  if "${fixture}/scripts/validate-formulae.sh" >"${output}" 2>&1; then
    echo "Expected stale Foundry reference in ${relative_path} to fail validation." >&2
    exit 1
  fi

  grep -Fq "${expected_error}" "${output}"
}

assert_stale_reference_rejected workflow .github/workflows/validate.yml
assert_stale_reference_rejected router scripts/update-formulae.sh

echo "validate-formulae stale-owner guard tests passed"

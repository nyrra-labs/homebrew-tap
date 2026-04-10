#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

for formula in "${repo_root}"/Formula/*.rb; do
  [[ -f "${formula}" ]] || continue
  ruby -c "${formula}" >/dev/null
done

signals_formula="${repo_root}/Formula/nyrra-signals.rb"
if [[ -f "${signals_formula}" ]]; then
  grep -q 'using: NyrraSignalsGitHubReleaseDownloadStrategy' "${signals_formula}"
  grep -q 'resolved_basename: "nyrra-signals_v' "${signals_formula}"
  grep -q 'url "https://api.github.com/repos/nyrra-labs/nyrra-signals/releases/assets/' "${signals_formula}"
fi

foundry_formula="${repo_root}/Formula/nyrra-foundry-cli.rb"
if [[ -f "${foundry_formula}" ]]; then
  grep -q 'using: NyrraFoundryCliGitHubReleaseDownloadStrategy' "${foundry_formula}"
  grep -q 'resolved_basename: "nyrra-foundry-cli_' "${foundry_formula}"
  grep -q 'url "https://api.github.com/repos/nyrra-labs/nyrra-foundry-cli/releases/assets/' "${foundry_formula}"
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

cp -a "${repo_root}/." "${tmpdir}/repo"
(
  cd "${tmpdir}/repo"
  ./scripts/update-formulae.sh auto
)

diff -ru "${repo_root}/Formula" "${tmpdir}/repo/Formula"

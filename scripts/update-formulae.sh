#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

if (($# == 0)); then
  set -- auto
fi

if [[ "$1" == "auto" ]]; then
  formulae=(scryu)
  if [[ -n "${NYRRA_GH_TOKEN:-}" || -z "${GITHUB_ACTIONS:-}" ]]; then
    formulae+=(nyrra-foundry-cli)
    formulae+=(nyrra-signals)
  fi
elif [[ "$1" == "all" ]]; then
  formulae=(
    nyrra-foundry-cli
    nyrra-signals
    scryu
  )
else
  formulae=("$@")
fi

for formula in "${formulae[@]}"; do
  case "${formula}" in
    nyrra-foundry-cli)
      if [[ "$1" == "auto" ]]; then
        "${repo_root}/scripts/update-nyrra-foundry-cli.sh" --optional
      else
        "${repo_root}/scripts/update-nyrra-foundry-cli.sh"
      fi
      ;;
    nyrra-signals)
      if [[ "$1" == "auto" ]]; then
        "${repo_root}/scripts/update-nyrra-signals.sh" --optional
      else
        "${repo_root}/scripts/update-nyrra-signals.sh"
      fi
      ;;
    scryu)
      if [[ "$1" == "auto" ]]; then
        "${repo_root}/scripts/update-scryu.sh" --optional
      else
        "${repo_root}/scripts/update-scryu.sh"
      fi
      ;;
    *)
      echo "unknown formula: ${formula}" >&2
      exit 1
      ;;
  esac
done

#!/usr/bin/env bash
set -euo pipefail

optional=false
if (($# > 1)); then
  echo "usage: $0 [--optional]" >&2
  exit 1
fi
if (($# == 1)); then
  if [[ "$1" != "--optional" ]]; then
    echo "usage: $0 [--optional]" >&2
    exit 1
  fi
  optional=true
fi

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
formula_path="${repo_root}/Formula/nyrra-signals.rb"
repo="nyrra-labs/nyrra-signals"

if [[ -n "${NYRRA_GH_TOKEN:-}" ]]; then
  release_json="$(GH_TOKEN="${NYRRA_GH_TOKEN}" gh api "repos/${repo}/releases/latest")"
elif [[ -n "${GITHUB_ACTIONS:-}" ]]; then
  if [[ "${optional}" == "true" ]]; then
    echo "Skipping nyrra-signals: NYRRA_GH_TOKEN is not configured in GitHub Actions." >&2
    exit 0
  fi
  echo "NYRRA_GH_TOKEN is required in GitHub Actions to read the private nyrra-signals release." >&2
  exit 1
else
  release_json="$(gh api "repos/${repo}/releases/latest")"
fi

version="$(jq -r '.tag_name | ltrimstr("v")' <<<"${release_json}")"
arm64_json="$(jq -c '
  .assets
  | map(select(.name | test("_darwin_arm64\\.tar\\.gz$")))
  | first
' <<<"${release_json}")"

arm64_asset="$(jq -r '.name // empty' <<<"${arm64_json}")"
arm64_sha="$(jq -r '.digest // empty' <<<"${arm64_json}")"

if [[ -z "${arm64_asset}" || "${arm64_asset}" == "null" ]]; then
  if [[ "${optional}" == "true" ]]; then
    echo "Skipping nyrra-signals: latest release is missing a darwin arm64 archive." >&2
    exit 0
  fi
  echo "nyrra-signals latest release is missing a darwin arm64 archive" >&2
  exit 1
fi

if [[ -z "${arm64_sha}" || "${arm64_sha}" == "null" ]]; then
  if [[ "${optional}" == "true" ]]; then
    echo "Skipping nyrra-signals: latest release is missing a darwin arm64 digest." >&2
    exit 0
  fi
  echo "nyrra-signals latest release is missing a darwin arm64 digest" >&2
  exit 1
fi

arm64_sha="${arm64_sha#sha256:}"

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

if [[ -n "${NYRRA_GH_TOKEN:-}" ]]; then
  GH_TOKEN="${NYRRA_GH_TOKEN}" gh release download "v${version}" --repo "${repo}" \
    --pattern "${arm64_asset}" --dir "${tmpdir}" --clobber >/dev/null
else
  gh release download "v${version}" --repo "${repo}" \
    --pattern "${arm64_asset}" --dir "${tmpdir}" --clobber >/dev/null
fi

(
  cd "${tmpdir}"
  echo "${arm64_sha}  ${arm64_asset}" | sha256sum -c
  tar -tzf "${arm64_asset}" \
    "nyrra-signals_v${version}_darwin_arm64/nyrra-signals" >/dev/null
)

cat > "${formula_path}" <<EOF
class NyrraSignals < Formula
  desc "Signal exploration TUI"
  homepage "https://github.com/nyrra-labs/nyrra-signals"
  version "${version}"
  depends_on arch: :arm64

  on_macos do
    on_arm do
      url "https://github.com/${repo}/releases/download/v${version}/${arm64_asset}"
      sha256 "${arm64_sha}"
    end
  end

  def install
    bin.install "nyrra-signals_v#{version}_darwin_arm64/nyrra-signals" => "nyrra-signals"
  end

  test do
    assert_predicate bin/"nyrra-signals", :exist?
  end
end
EOF

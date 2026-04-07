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
formula_path="${repo_root}/Formula/nyrra-foundry-cli.rb"
repo="nyrra-labs/nyrra-foundry-cli"

if [[ -n "${NYRRA_GH_TOKEN:-}" ]]; then
  release_json="$(GH_TOKEN="${NYRRA_GH_TOKEN}" gh api "repos/${repo}/releases/latest")"
elif [[ -n "${GITHUB_ACTIONS:-}" ]]; then
  if [[ "${optional}" == "true" ]]; then
    echo "Skipping nyrra-foundry-cli: NYRRA_GH_TOKEN is not configured in GitHub Actions." >&2
    exit 0
  fi
  echo "NYRRA_GH_TOKEN is required in GitHub Actions to read the private nyrra-foundry-cli release." >&2
  exit 1
else
  release_json="$(gh api "repos/${repo}/releases/latest")"
fi

version="$(jq -r '.tag_name | ltrimstr("v")' <<<"${release_json}")"
amd64_json="$(jq -c '
  .assets
  | map(select(.name | test("_darwin_amd64\\.tar\\.gz$")))
  | first
' <<<"${release_json}")"
arm64_json="$(jq -c '
  .assets
  | map(select(.name | test("_darwin_arm64\\.tar\\.gz$")))
  | first
' <<<"${release_json}")"

amd64_asset="$(jq -r '.name // empty' <<<"${amd64_json}")"
amd64_sha="$(jq -r '.digest // empty' <<<"${amd64_json}")"
arm64_asset="$(jq -r '.name // empty' <<<"${arm64_json}")"
arm64_sha="$(jq -r '.digest // empty' <<<"${arm64_json}")"

if [[ -z "${amd64_asset}" || "${amd64_asset}" == "null" || -z "${arm64_asset}" || "${arm64_asset}" == "null" ]]; then
  if [[ "${optional}" == "true" ]]; then
    echo "Skipping nyrra-foundry-cli: latest release is missing required darwin archives." >&2
    exit 0
  fi
  echo "nyrra-foundry-cli latest release is missing required darwin archives" >&2
  exit 1
fi

if [[ -z "${amd64_sha}" || "${amd64_sha}" == "null" || -z "${arm64_sha}" || "${arm64_sha}" == "null" ]]; then
  if [[ "${optional}" == "true" ]]; then
    echo "Skipping nyrra-foundry-cli: latest release is missing darwin asset digests." >&2
    exit 0
  fi
  echo "nyrra-foundry-cli latest release is missing darwin asset digests" >&2
  exit 1
fi

amd64_sha="${amd64_sha#sha256:}"
arm64_sha="${arm64_sha#sha256:}"

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

if [[ -n "${NYRRA_GH_TOKEN:-}" ]]; then
  GH_TOKEN="${NYRRA_GH_TOKEN}" gh release download "v${version}" --repo "${repo}" \
    --pattern "${amd64_asset}" --pattern "${arm64_asset}" --dir "${tmpdir}" --clobber >/dev/null
else
  gh release download "v${version}" --repo "${repo}" \
    --pattern "${amd64_asset}" --pattern "${arm64_asset}" --dir "${tmpdir}" --clobber >/dev/null
fi

(
  cd "${tmpdir}"
  echo "${amd64_sha}  ${amd64_asset}" | sha256sum -c
  echo "${arm64_sha}  ${arm64_asset}" | sha256sum -c
  tar -tzf "${amd64_asset}" \
    nyrra-foundry-cli \
    LICENSE \
    NOTICE \
    README.md \
    templates/compute-module-ts/package.json >/dev/null
  tar -tzf "${arm64_asset}" \
    nyrra-foundry-cli \
    LICENSE \
    NOTICE \
    README.md \
    templates/compute-module-ts/package.json >/dev/null
)

cat > "${formula_path}" <<EOF
class NyrraFoundryCli < Formula
  desc "Foundry DevOps automation CLI"
  homepage "https://github.com/nyrra-labs/nyrra-foundry-cli"
  version "${version}"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/${repo}/releases/download/v${version}/${arm64_asset}"
      sha256 "${arm64_sha}"
    end

    on_intel do
      url "https://github.com/${repo}/releases/download/v${version}/${amd64_asset}"
      sha256 "${amd64_sha}"
    end
  end

  def install
    libexec.install Dir["*"]

    templates_root = libexec/"templates"
    templates_root.mkpath

    template_readme = templates_root/"README.md"
    template_readme.write("# templates\n") unless template_readme.exist?

    bin.install_symlink libexec/"nyrra-foundry-cli"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/nyrra-foundry-cli version")
  end
end
EOF

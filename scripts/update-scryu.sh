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
formula_path="${repo_root}/Formula/scryu.rb"
release_base_url="${SCRYU_RELEASE_BASE_URL:-https://install.scryu.com/releases}"
manifest_url="${release_base_url%/}/latest.json"

skip_optional() {
  if [[ "${optional}" == "true" ]]; then
    echo "Skipping scryu: $1" >&2
    exit 0
  fi
  echo "scryu: $1" >&2
  exit 1
}

verify_sha256() {
  local expected="$1"
  local file="$2"
  local actual

  if command -v shasum >/dev/null 2>&1; then
    actual="$(shasum -a 256 "${file}" | awk '{print $1}')"
  elif command -v sha256sum >/dev/null 2>&1; then
    actual="$(sha256sum "${file}" | awk '{print $1}')"
  else
    echo "Unable to verify SHA-256: neither shasum nor sha256sum is available." >&2
    exit 1
  fi

  if [[ "${actual}" != "${expected}" ]]; then
    echo "SHA-256 mismatch for ${file}: expected ${expected}, got ${actual}." >&2
    exit 1
  fi
}

manifest="$(mktemp)"
if ! curl -fsSL "${manifest_url}" -o "${manifest}"; then
  skip_optional "latest release manifest is not available at ${manifest_url}"
fi

version="$(jq -r '.version | ltrimstr("v")' "${manifest}")"
arm64_json="$(jq -c '
  .assets
  | map(select(.name | test("_darwin_arm64\\.tar\\.gz$")))
  | first
' "${manifest}")"

arm64_asset="$(jq -r '.name // empty' <<<"${arm64_json}")"
arm64_url="$(jq -r '.url // empty' <<<"${arm64_json}")"
arm64_sha="$(jq -r '.sha256 // empty' <<<"${arm64_json}")"

if [[ -z "${version}" || "${version}" == "null" ]]; then
  skip_optional "latest release manifest is missing version"
fi
if [[ -z "${arm64_asset}" || "${arm64_asset}" == "null" || -z "${arm64_url}" || "${arm64_url}" == "null" ]]; then
  skip_optional "latest release manifest is missing a darwin arm64 archive"
fi
if [[ -z "${arm64_sha}" || "${arm64_sha}" == "null" ]]; then
  skip_optional "latest release manifest is missing a darwin arm64 checksum"
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}" "${manifest}"' EXIT

curl -fsSL "${arm64_url}" -o "${tmpdir}/${arm64_asset}"
(
  cd "${tmpdir}"
  verify_sha256 "${arm64_sha}" "${arm64_asset}"
  tar -tzf "${arm64_asset}" \
    "scryu_v${version}_darwin_arm64/scryu" >/dev/null
)

cat > "${formula_path}" <<EOF
class Scryu < Formula
  desc "SCRYU terminal client"
  homepage "https://scryu.com"
  url "${arm64_url}"
  version "${version}"
  sha256 "${arm64_sha}"
  license :cannot_represent
  depends_on arch: :arm64

  def install
    binary = Dir["scryu", "*/scryu"].find { |path| File.file?(path) }
    bin.install binary => "scryu"
  end

  def caveats
    <<~EOS
      First run:
        scryu login
        scryu

      Installed scryu stores local objective run state under ~/.scryu.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/scryu version")
  end
end
EOF

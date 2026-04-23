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

verify_release_archive() {
  local archive="$1"
  local listing

  listing="$(tar -tzf "${archive}")"

  grep -Fxq "nyrra-foundry-cli" <<<"${listing}"
  grep -Fxq "LICENSE" <<<"${listing}"
  grep -Fxq "NOTICE" <<<"${listing}"
  grep -Fxq "README.md" <<<"${listing}"

  if ! grep -Eq '^templates/(compute-module-ts|compute-modules/typescript)/package\.json$' <<<"${listing}"; then
    echo "Release archive ${archive} is missing a recognized compute module template package.json." >&2
    exit 1
  fi
}

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
amd64_api_url="$(jq -r '.url // empty' <<<"${amd64_json}")"
amd64_sha="$(jq -r '.digest // empty' <<<"${amd64_json}")"
arm64_asset="$(jq -r '.name // empty' <<<"${arm64_json}")"
arm64_api_url="$(jq -r '.url // empty' <<<"${arm64_json}")"
arm64_sha="$(jq -r '.digest // empty' <<<"${arm64_json}")"

if [[ -z "${amd64_asset}" || "${amd64_asset}" == "null" || -z "${amd64_api_url}" || "${amd64_api_url}" == "null" || -z "${arm64_asset}" || "${arm64_asset}" == "null" || -z "${arm64_api_url}" || "${arm64_api_url}" == "null" ]]; then
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
  verify_sha256 "${amd64_sha}" "${amd64_asset}"
  verify_sha256 "${arm64_sha}" "${arm64_asset}"
  verify_release_archive "${amd64_asset}"
  verify_release_archive "${arm64_asset}"
)

cat > "${formula_path}" <<EOF
class NyrraFoundryCliGitHubReleaseDownloadStrategy < CurlDownloadStrategy
  def initialize(url, name, version, **meta)
    @resolved_basename = meta.delete(:resolved_basename)
    @github_token = resolve_github_token

    if @github_token.nil? || @github_token.empty?
      raise CurlDownloadStrategyError.new(
        url,
        [
          "GitHub authentication is required to download the private nyrra-foundry-cli release asset.",
          "Set HOMEBREW_GITHUB_API_TOKEN, GH_TOKEN, GITHUB_TOKEN, or NYRRA_GH_TOKEN,",
          "or log in with gh auth login."
        ].join(" ")
      )
    end

    meta[:headers] ||= []
    meta[:headers] << "Accept: application/octet-stream"
    meta[:headers] << "Authorization: Bearer #{@github_token}"
    super
  end

  private

  def resolve_github_token
    %w[HOMEBREW_GITHUB_API_TOKEN GH_TOKEN GITHUB_TOKEN NYRRA_GH_TOKEN].each do |key|
      value = ENV[key]&.strip
      return value unless value.nil? || value.empty?
    end

    [
      "#{HOMEBREW_PREFIX}/bin/gh",
      "/opt/homebrew/bin/gh",
      "/usr/local/bin/gh",
      "gh"
    ].uniq.each do |gh|
      next if gh != "gh" && !File.executable?(gh)

      value = Utils.safe_popen_read(gh, "auth", "token").strip
      return value unless value.empty?
    rescue ErrorDuringExecution, Errno::ENOENT
      next
    end

    nil
  end

  def resolve_url_basename_time_file_size(url, timeout: nil)
    resolved_url, _, last_modified, file_size, content_type, is_redirection = super
    [resolved_url, @resolved_basename, last_modified, file_size, content_type, is_redirection]
  end

  def curl_output(*args, **options)
    super(*args, secrets: [@github_token], **options)
  end

  def curl(*args, print_stdout: true, **options)
    super(*args, print_stdout: print_stdout, secrets: [@github_token], **options)
  end
end

class NyrraFoundryCli < Formula
  desc "Foundry DevOps automation CLI"
  homepage "https://github.com/nyrra-labs/nyrra-foundry-cli"
  version "${version}"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "${arm64_api_url}",
          using: NyrraFoundryCliGitHubReleaseDownloadStrategy,
          resolved_basename: "${arm64_asset}"
      sha256 "${arm64_sha}"
    end

    on_intel do
      url "${amd64_api_url}",
          using: NyrraFoundryCliGitHubReleaseDownloadStrategy,
          resolved_basename: "${amd64_asset}"
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

  def caveats
    <<~EOS
      Package-manager installs do not edit your shell config.

      To add the upstream npc shorthand in zsh:
        printf '\\\\nalias npc=nyrra-foundry-cli\\\\nsource <(nyrra-foundry-cli completion --code zsh)\\\\n' >> ~/.zshrc

      To add it in bash:
        printf '\\\\nalias npc=nyrra-foundry-cli\\\\nsource <(nyrra-foundry-cli completion --code bash)\\\\n' >> ~/.bashrc
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/nyrra-foundry-cli version")
  end
end
EOF

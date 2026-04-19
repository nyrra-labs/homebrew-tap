class NyrraSignalsGitHubReleaseDownloadStrategy < CurlDownloadStrategy
  def initialize(url, name, version, **meta)
    @resolved_basename = meta.delete(:resolved_basename)
    @github_token = resolve_github_token

    if @github_token.nil? || @github_token.empty?
      raise CurlDownloadStrategyError.new(
        url,
        [
          "GitHub authentication is required to download the private nyrra-signals release asset.",
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

class NyrraSignals < Formula
  desc "Signal exploration TUI"
  homepage "https://github.com/nyrra-labs/nyrra-signals"
  version "0.0.15"
  depends_on arch: :arm64

  on_macos do
    on_arm do
      url "https://api.github.com/repos/nyrra-labs/nyrra-signals/releases/assets/399743139",
          using: NyrraSignalsGitHubReleaseDownloadStrategy,
          resolved_basename: "nyrra-signals_v0.0.15_darwin_arm64.tar.gz"
      sha256 "7991029693c98f31c89ecd87f9bbbbd05a27a8f4425b153b0f60eff834994142"
    end
  end

  def install
    bin.install "nyrra-signals"
  end

  def caveats
    <<~EOS
      Run the guided first-run setup from a real terminal:
        nyrra-signals setup

      Package-manager installs do not auto-open the TUI for you.
    EOS
  end

  test do
    assert_predicate bin/"nyrra-signals", :exist?
  end
end

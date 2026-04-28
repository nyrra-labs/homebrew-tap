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
  version "0.0.14"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://api.github.com/repos/nyrra-labs/nyrra-foundry-cli/releases/assets/405545580",
          using: NyrraFoundryCliGitHubReleaseDownloadStrategy,
          resolved_basename: "nyrra-foundry-cli_0.0.14_darwin_arm64.tar.gz"
      sha256 "dd6aff4c3206aefd1073651e51f78b94aa8372538a77c23d4bb4d436034f06f3"
    end

    on_intel do
      url "https://api.github.com/repos/nyrra-labs/nyrra-foundry-cli/releases/assets/405545591",
          using: NyrraFoundryCliGitHubReleaseDownloadStrategy,
          resolved_basename: "nyrra-foundry-cli_0.0.14_darwin_amd64.tar.gz"
      sha256 "c26f96998cc23bc2ccbc80244b65813cfa12a60109a8e001cc7594e5f9d45bce"
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
        printf '\\nalias npc=nyrra-foundry-cli\\nsource <(nyrra-foundry-cli completion --code zsh)\\n' >> ~/.zshrc

      To add it in bash:
        printf '\\nalias npc=nyrra-foundry-cli\\nsource <(nyrra-foundry-cli completion --code bash)\\n' >> ~/.bashrc
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/nyrra-foundry-cli version")
  end
end

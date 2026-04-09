class NyrraFoundryCli < Formula
  desc "Foundry DevOps automation CLI"
  homepage "https://github.com/nyrra-labs/nyrra-foundry-cli"
  version "0.0.5"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/nyrra-labs/nyrra-foundry-cli/releases/download/v0.0.5/nyrra-foundry-cli_0.0.5_darwin_arm64.tar.gz"
      sha256 "0c9059529a6b1cbfc6e61833f19cd4db79e6d470a6a408d3db4cf3be175e79ec"
    end

    on_intel do
      url "https://github.com/nyrra-labs/nyrra-foundry-cli/releases/download/v0.0.5/nyrra-foundry-cli_0.0.5_darwin_amd64.tar.gz"
      sha256 "c07a5f9b1a0565f6f9607767caca52f6ec7b785c3bbe32918141c2f23e2f4aac"
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

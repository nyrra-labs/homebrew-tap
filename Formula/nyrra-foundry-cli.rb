class NyrraFoundryCli < Formula
  desc "Foundry DevOps automation CLI"
  homepage "https://github.com/nyrra-labs/nyrra-foundry-cli"
  version "0.0.4"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/nyrra-labs/nyrra-foundry-cli/releases/download/v0.0.4/nyrra-foundry-cli_0.0.4_darwin_arm64.tar.gz"
      sha256 "67b97a242d169e8bc924e4e0a3dee42064b3e45de3105676ea915652eb0522ef"
    end

    on_intel do
      url "https://github.com/nyrra-labs/nyrra-foundry-cli/releases/download/v0.0.4/nyrra-foundry-cli_0.0.4_darwin_amd64.tar.gz"
      sha256 "5c46f6eeb5c58d6a3b45b01ceb1ea4ef0c09e018fac0c8d229a36dd92d4d0812"
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

class NyrraFoundryCli < Formula
  desc "Foundry DevOps automation CLI"
  homepage "https://github.com/nyrra-labs/nyrra-foundry-cli"
  version "0.0.2"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/nyrra-labs/nyrra-foundry-cli/releases/download/v0.0.2/nyrra-foundry-cli_0.0.2_darwin_arm64.tar.gz"
      sha256 "765b4c1b4526c62c00ab23932596a302ec4883b45d07d1f29494afee344e1521"
    end

    on_intel do
      url "https://github.com/nyrra-labs/nyrra-foundry-cli/releases/download/v0.0.2/nyrra-foundry-cli_0.0.2_darwin_amd64.tar.gz"
      sha256 "af76af0898bc8d71283527fa5f448858c9779f6fe9a3511a92b525bccf2b075b"
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

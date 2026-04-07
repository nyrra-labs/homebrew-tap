class NyrraFoundryCli < Formula
  desc "Foundry DevOps automation CLI"
  homepage "https://github.com/nyrra-labs/nyrra-foundry-cli"
  version "0.0.3"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/nyrra-labs/nyrra-foundry-cli/releases/download/v0.0.3/nyrra-foundry-cli_0.0.3_darwin_arm64.tar.gz"
      sha256 "7a47b2935540a4a59599fdacf792dc49a74da36457dc9a03c2a31fd127977033"
    end

    on_intel do
      url "https://github.com/nyrra-labs/nyrra-foundry-cli/releases/download/v0.0.3/nyrra-foundry-cli_0.0.3_darwin_amd64.tar.gz"
      sha256 "00064c740a91dbd66c9d85854423b729843804660265fec030296a4746ef4a9a"
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

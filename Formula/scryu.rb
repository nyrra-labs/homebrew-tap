class Scryu < Formula
  desc "SCRYU terminal client"
  homepage "https://scryu.com"
  url "https://install.scryu.com/releases/v0.0.1/scryu_v0.0.1_darwin_arm64.tar.gz"
  version "0.0.1"
  sha256 "fd3f175acb4ed67afb3037c197a88e4cfb9a85caa57aa0280bf2a76a985baa72"
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

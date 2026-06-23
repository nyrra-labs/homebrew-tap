class Scryu < Formula
  desc "SCRYU terminal client"
  homepage "https://scryu.com"
  url "https://install.scryu.com/releases/v0.0.14/scryu_v0.0.14_darwin_arm64.tar.gz"
  version "0.0.14"
  sha256 "5bc967809391f13354e6610e1bf64fd7063bb3e6f94fbd75b70fd5e2760b237e"
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

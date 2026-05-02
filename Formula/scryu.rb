class Scryu < Formula
  desc "SCRYU terminal client"
  homepage "https://scryu.com"
  url "https://install.scryu.com/releases/v0.0.2/scryu_v0.0.2_darwin_arm64.tar.gz"
  version "0.0.2"
  sha256 "2f71bec181221ce574946e987465771b3c3a8fa23edf1babe7217fa5309045ec"
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

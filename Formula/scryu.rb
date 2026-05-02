class Scryu < Formula
  desc "SCRYU terminal client"
  homepage "https://scryu.com"
  url "https://install.scryu.com/releases/v0.0.3/scryu_v0.0.3_darwin_arm64.tar.gz"
  version "0.0.3"
  sha256 "395cba5c7c660a87064a0e30cd160912e41325732d2634f19e4f5748a93ef472"
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

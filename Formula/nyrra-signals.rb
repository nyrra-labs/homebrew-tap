class NyrraSignals < Formula
  desc "Signal exploration TUI"
  homepage "https://github.com/nyrra-labs/nyrra-signals"
  version "0.0.7"
  depends_on arch: :arm64

  on_macos do
    on_arm do
      url "https://github.com/nyrra-labs/nyrra-signals/releases/download/v0.0.7/nyrra-signals_v0.0.7_darwin_arm64.tar.gz"
      sha256 "3db80219bd07c23be2a3729a22c5a28a41702b942f82740f327b5bec3ac71653"
    end
  end

  def install
    bin.install "nyrra-signals_v#{version}_darwin_arm64/nyrra-signals" => "nyrra-signals"
  end

  test do
    assert_predicate bin/"nyrra-signals", :exist?
  end
end

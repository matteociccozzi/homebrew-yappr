class Yappr < Formula
  desc "Local push-to-talk voice dictation for macOS Apple Silicon"
  homepage "https://github.com/matteociccozzi/yappr"
  version "0.1.2"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/matteociccozzi/yappr/releases/download/v0.1.2/yappr-0.1.2-macos-arm64.tar.gz"
      sha256 "d8ac17796b90780bd6c7e493106fb594f322f5c2b0adc85c24a9cab81356df93"
    else
      odie "yappr requires Apple Silicon (arm64). Intel Macs are not supported."
    end
  end

  depends_on :macos => :sonoma
  depends_on "jq"
  depends_on "python@3.12"
  depends_on "uv"

  def install
    # Scripts and helpers go on PATH
    bin.install Dir["bin/*"]

    # Shell completions
    bash_completion.install "completions/yappr.bash" => "yappr"
    zsh_completion.install "completions/yappr.zsh" => "_yappr"
    fish_completion.install "completions/_yappr.fish" => "yappr.fish"

    # Supporting directories (configs, prompts, scripts, docs)
    (share/"yappr").install "configs", "prompts", "scripts", "docs"

    # Man page (present in tarball after Tier 4)
    man1.install "share/man/man1/yappr.1" if (Pathname.new("share/man/man1/yappr.1")).exist?

    # Ad-hoc codesign so TCC microphone permission survives across brew upgrades.
    system "codesign", "--force", "--sign", "-", "#{bin}/YapprSttDaemon"
  end

  def caveats
    <<~EOS
      yappr requires three macOS permissions granted manually:

        1. Microphone → YapprSttDaemon
           System Settings → Privacy & Security → Microphone

        2. Accessibility → Hammerspoon
           System Settings → Privacy & Security → Accessibility

        3. Input Monitoring → Hammerspoon
           System Settings → Privacy & Security → Input Monitoring

      After install:
        yappr setup          # downloads Nemotron STT model (~200 MB, one-time)
        yappr daemon start
        yappr server start
        yappr doctor

      Full setup guide:
        https://github.com/matteociccozzi/yappr/blob/main/docs/installation.md
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/yappr version")
    assert_match "USAGE", shell_output("#{bin}/yappr help")
  end
end

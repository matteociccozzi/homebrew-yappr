class Yappr < Formula
  desc "Local push-to-talk voice dictation for macOS Apple Silicon"
  homepage "https://github.com/matteociccozzi/yappr"
  version "0.1.5"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/matteociccozzi/yappr/releases/download/v0.1.5/yappr-0.1.5-macos-arm64.tar.gz"
      sha256 "80933245f9639440419bf473ec72cb38af1ca3540063019bd1dc52b6ba58c3e3"
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
      ── Step 1: Install Hammerspoon (push-to-talk hotkey) ──────────────────
        brew install --cask hammerspoon

      ── Step 2: Run first-time setup ───────────────────────────────────────
        yappr setup
        # Downloads the Nemotron STT model (~200 MB), installs mlx-lm,
        # creates config dirs, and writes ~/.hammerspoon/init.lua.

      ── Step 3: Grant macOS permissions (required — cannot be automated) ───

        a) Input Monitoring → Hammerspoon
           System Settings → Privacy & Security → Input Monitoring
           Toggle Hammerspoon ON.
           Required so Hammerspoon can detect the Ctrl+Option+Y hotkey globally.

        b) Accessibility → Hammerspoon
           System Settings → Privacy & Security → Accessibility
           Toggle Hammerspoon ON.
           Required so Hammerspoon can type the transcribed text at the cursor.

        c) Microphone → YapprSttDaemon
           Start the daemon once — macOS will show a prompt automatically:
             yappr daemon start
           Or add it manually: System Settings → Privacy & Security → Microphone

      ── Step 4: Reload Hammerspoon and start services ──────────────────────
        # Click the Hammerspoon menu bar icon → Reload Config
        yappr server start

      ── Step 5: Verify ─────────────────────────────────────────────────────
        yappr doctor

      Hold Ctrl+Option+Y to dictate. Release to finalize and type.

      Full setup guide:
        https://github.com/matteociccozzi/yappr/blob/main/docs/installation.md
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/yappr version")
    assert_match "USAGE", shell_output("#{bin}/yappr help")
  end
end

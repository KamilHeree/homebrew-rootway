class Rootway < Formula
  desc "Rootway Agent - monitoring serwera i tunel WireGuard"
  homepage "https://github.com/KamilHeree/rootway-agent"
  url "https://github.com/KamilHeree/rootway-agent/archive/refs/tags/v1.0.0.zip"
  sha256 "TWOJA_SHA256"
  license "MIT"
  version "1.0.0" # <--- to musisz DODAĆ!

  depends_on "python@3.12"
  depends_on "wireguard-tools"

  def install
    bin.install "rootway"
    prefix.install Dir["*"]
  end

  def post_install
    system "python3", "-m", "venv", "#{prefix}/venv"
    system "#{prefix}/venv/bin/pip", "install", "-r", "#{prefix}/requirements.txt"
  end

  service do
    run [opt_prefix/"venv/bin/python3", opt_prefix/"main.py"]
    keep_alive true
    working_dir opt_prefix
    log_path var/"log/rootway.log"
    error_log_path var/"log/rootway-error.log"
  end
end

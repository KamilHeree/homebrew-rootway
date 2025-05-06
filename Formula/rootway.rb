class Rootway < Formula
  desc "Rootway Agent - monitoring serwera i tunel WireGuard"
  homepage "https://github.com/KamilHeree/rootway-agent"
  url "https://github.com/KamilHeree/rootway-agent/releases/download/v1.0.0/rootway-agent.zip"
  sha256 "7E1418BF3BD4CCB96ACE8F2930FC8B5DDAA125EC115C1C7C67663171695D71AF"
  license "MIT"
  version "1.0.0"

  depends_on "python@3.12"
  depends_on "wireguard-tools"

  def install
    # Rozpakowanie pliku ZIP w katalogu buildpath
    system "unzip", "rootway-agent.zip", "-d", buildpath

    # Instalowanie plików
    bin.install "#{buildpath}/rootway-agent/rootway"
    prefix.install Dir["#{buildpath}/rootway-agent/*"]
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

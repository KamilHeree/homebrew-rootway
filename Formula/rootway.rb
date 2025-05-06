class Rootway < Formula
  desc "Rootway Agent - monitoring serwera i tunel WireGuard"
  homepage "https://github.com/KamilHeree/rootway-agent"
  url "https://github.com/KamilHeree/rootway-agent/releases/download/v1.0.0/rootway-agent.zip"
  sha256 "26CDE3F3C6C1591611B6B646D2F8A0F67FD87CFD1EB43F7767C5E830618D3D1C"
  license "MIT"
  version "1.0.0"

  depends_on "python@3.12"
  depends_on "wireguard-tools"

  def install
    prefix.install Dir["*"]
  end

  def post_install
    python = Formula["python@3.12"].opt_bin/"python3"
    
    # Sprawdzenie, czy moduł venv jest dostępny
    unless system(python, "-m", "venv", "--help", out: File::NULL, err: File::NULL)
      opoo "Wygląda na to, że Python nie ma modułu venv!"
      opoo "Instalowanie brakującego pakietu python3.12-venv..."
      
      # Automatyczne zainstalowanie brakującego pakietu venv
      system "sudo", "apt", "install", "-y", "python3.12-venv"
      # Uruchomienie ponownie postinstall
      system "brew", "postinstall", "rootway"
      return
    end

    system python, "-m", "venv", "#{prefix}/venv"
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

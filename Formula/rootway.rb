class Rootway < Formula
  desc "Rootway Agent - monitoring serwera i tunel WireGuard"
  homepage "https://github.com/kamilheree/rootway-agent"
  url "https://github.com/kamilheree/rootway-agent/releases/download/v1.0.0/rootway-agent.zip"
  sha256 "26CDE3F3C6C1591611B6B646D2F8A0F67FD87CFD1EB43F7767C5E830618D3D1C"
  license "MIT"
  version "1.0.0"

  depends_on "python@3.12"
  depends_on "wireguard-tools" => :optional

  def install
    # Automatyczna instalacja wszystkich plików
    prefix.install Dir["*"]
    
    # Utwórz katalogi systemowe
    (var/"log").mkpath
    (etc/"wireguard").mkpath
  end

  def post_install
    # Automatyczne środowisko wirtualne
    venv_dir = opt_prefix/"venv"
    system Formula["python@3.12"].opt_bin/"python3", "-m", "venv", venv_dir
    system venv_dir/"bin/pip", "install", "-r", opt_prefix/"requirements.txt"
    
    # Konfiguracja WireGuard
    unless (etc/"wireguard/wg0.conf").exist?
      cp opt_prefix/"wg0.example.conf", etc/"wireguard/wg0.conf"
    end
  end

  service do
    run [opt_prefix/"venv/bin/python3", opt_prefix/"main.py"]
    keep_alive true
    working_dir opt_prefix
    log_path var/"log/rootway.log"
    error_log_path var/"log/rootway-error.log"
    environment_variables PATH: std_service_path_env
  end

  def caveats
    <<~EOS
      Agent został zainstalowany. Uruchom komendą:
        brew services start rootway

      Logi systemowe:
        #{var}/log/rootway.log

      Konfiguracja WireGuard:
        #{etc}/wireguard/wg0.conf
    EOS
  end
end
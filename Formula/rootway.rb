class Rootway < Formula
  desc "Rootway Agent - monitoring serwera i tunel WireGuard"
  homepage "https://github.com/kamilheree/rootway-agent"
  url "https://github.com/kamilheree/rootway-agent/releases/download/v1.0.0/rootway-agent.zip"
  sha256 "99FDCA102E784E25F8B5653E9E9AC8FCC232663DE3BC7937227785B4987C6728"
  license "MIT"
  version "1.0.0"

  depends_on "flask" => :python
  depends_on "wireguard-tools"

  def install
    # Instalacja wszystkich plików
    prefix.install Dir["*"]
    
    # Utwórz katalogi systemowe
    (var/"log").mkpath
    (prefix/"templates").mkpath
  end

  def post_install
    # Instalacja zależności Python
    venv_dir = opt_prefix/"venv"
    system Formula["python@3.12"].opt_bin/"python3", "-m", "venv", venv_dir
    system venv_dir/"bin/pip", "install", "-r", opt_prefix/"requirements.txt"
    
    # Automatyczna konfiguracja WireGuard
    system "sudo", opt_prefix/"wireguard_setup.py"
  end

  service do
    run [opt_prefix/"venv/bin/python3", opt_prefix/"main.py"]
    keep_alive true
    working_dir opt_prefix
    environment_variables PATH: std_service_path_env
  end

  def caveats
    <<~EOS
      Panel logowania dostępny pod:
        http://localhost:8080

      Konfiguracja WireGuard:
        #{etc}/wireguard/wg0.conf

      Aby uruchomić tunel WireGuard:
        sudo wg-quick up wg0
    EOS
  end
end

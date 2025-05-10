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
    # Tworzenie katalogu logów w standardowej lokalizacji Homebrew
    (var/"log").mkpath

    # Instalacja plików
    prefix.install Dir["*"]
    
    # Poprawiona ścieżka dla skryptu
    bin.install "webserver.py" => "rootway"
    chmod 0755, bin/"rootway"
  end

  def post_install
    venv_path = opt_prefix/"venv"
    python = Formula["python@3.12"].opt_bin/"python3"

    # Tworzenie venv z poprawionymi ścieżkami
    system python, "-m", "venv", venv_path.to_s

    # Instalacja zależności
    system venv_path/"bin/pip", "install", "-r", opt_prefix/"requirements.txt"
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
      Uruchom agenta komendą:
        brew services start rootway

      Logi znajdziesz w:
        #{var}/log/rootway.log
        #{var}/log/rootway-error.log

      Konfiguracja WireGuard:
        Edytuj plik: #{etc}/wireguard/wg0.conf
    EOS
  end
end
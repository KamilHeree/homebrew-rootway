class Rootway < Formula
  desc "Rootway Agent - monitoring serwera i tunel WireGuard"
  homepage "https://github.com/kamilheree/rootway-agent"
  url "https://github.com/kamilheree/rootway-agent/releases/download/v1.0.0/rootway-agent.zip"
  sha256 "26CDE3F3C6C1591611B6B646D2F8A0F67FD87CFD1EB43F7767C5E830618D3D1C"
  license "MIT"
  version "1.0.0"

  depends_on "python@3.12"
  depends_on "wireguard-tools" => :optional # Opcjonalne, bo root może być potrzebny do pełnej funkcjonalności

  def install
    # Tworzymy katalog logów w katalogu użytkownika
    log_dir = "#{ENV["HOME"]}/log"
    mkdir_p log_dir unless Dir.exist?(log_dir)

    # Instalujemy wszystkie pliki z ZIP-a do katalogu prefix
    prefix.install Dir["*"]

    # Generujemy skrypt do uruchomienia agenta z roota
    (prefix/"run-as-root.sh").write <<~EOS
      #!/bin/bash
      sudo #{opt_prefix}/venv/bin/python3 #{opt_prefix}/main.py
    EOS
    chmod 0755, prefix/"run-as-root.sh"
  end

  def post_install
    python = Formula["python@3.12"].opt_bin/"python3"

    # Sprawdzamy, czy moduł venv jest dostępny
    puts "Sprawdzanie dostępności modułu venv..."
    unless system(python, "-m", "venv", "--help", err: :out)
      onoe <<~EOS
        Moduł venv nie jest dostępny dla Pythona 3.12!
        Proszę upewnić się, że Python 3.12 jest poprawnie zainstalowany przez Homebrew:
        `brew reinstall python@3.12`
      EOS
      raise "Błąd: Moduł venv niedostępny"
    end

    # Tworzymy środowisko wirtualne
    venv_path = prefix/"venv"
    puts "Tworzenie środowiska wirtualnego w #{venv_path}..."
    unless system(python, "-m", "venv", venv_path, err: :out)
      onoe <<~EOS
        Nie udało się utworzyć środowiska wirtualnego w #{venv_path}!
        Sprawdź, czy masz uprawnienia do zapisu w #{prefix}.
      EOS
      raise "Błąd podczas tworzenia środowiska wirtualnego"
    end

    # Instalujemy zależności z requirements.txt
    pip = venv_path/"bin/pip"
    requirements = prefix/"requirements.txt"
    puts "Sprawdzanie, czy plik requirements.txt istnieje..."
    unless File.exist?(requirements)
      onoe <<~EOS
        Plik requirements.txt nie istnieje w #{prefix}!
        Proszę upewnić się, że plik requirements.txt znajduje się w paczce ZIP.
      EOS
      raise "Brak pliku requirements.txt"
    end

    puts "Instalowanie zależności z #{requirements}..."
    unless system(pip, "install", "-r", requirements, err: :out)
      onoe <<~EOS
        Nie udało się zainstalować zależności z #{requirements}!
        Sprawdź, czy plik requirements.txt jest poprawny i czy masz dostęp do internetu.
      EOS
      raise "Błąd podczas instalacji zależności"
    end

    puts "Środowisko wirtualne i zależności zostały pomyślnie zainstalowane."
    puts "Aby uruchomić agenta z uprawnieniami roota, wykonaj: sudo #{opt_prefix}/run-as-root.sh"
  end

  service do
    # Usługa jest opcjonalna i wymaga roota do konfiguracji
    run [opt_prefix/"venv/bin/python3", opt_prefix/"main.py"]
    keep_alive true
    working_dir opt_prefix
    log_path "#{ENV["HOME"]}/log/rootway.log"
    error_log_path "#{ENV["HOME"]}/log/rootway-error.log"
  end
end
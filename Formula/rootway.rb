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
    # Instalujemy wszystkie pliki z ZIP-a do katalogu prefix
    prefix.install Dir["*"]
  end

  def post_install
    python = Formula["python@3.12"].opt_bin/"python3"

    # Sprawdzamy, czy moduł venv jest dostępny
    puts "Sprawdzanie dostępności modułu venv..."
    unless system(python, "-m", "venv", "--help", err: :out)
      warn <<~EOS
        Moduł venv nie jest dostępny dla Pythona 3.12!
        Spróbujemy go zainstalować...
      EOS

      # Próbujemy zainstalować venv w zależności od systemu
      if OS.linux?
        # Debian/Ubuntu
        if system("which", "apt")
          system "sudo", "apt", "install", "python3.12-venv", "-y"
        # CentOS/RHEL
        elsif system("which", "yum")
          system "sudo", "yum", "install", "python3.12-venv", "-y"
        else
          onoe <<~EOS
            Nie udało się zainstalować python3.12-venv. Proszę zainstalować go ręcznie i spróbować ponownie.
            Na przykład na Debian/Ubuntu: `sudo apt install python3.12-venv`
            Na CentOS/RHEL: `sudo yum install python3.12-venv`
          EOS
          raise "Brak wsparcia dla instalacji venv na tym systemie"
        end
      else
        onoe <<~EOS
          Moduł venv powinien być dostępny w Pythonie zainstalowanym przez Homebrew.
          Proszę upewnić się, że Python 3.12 jest poprawnie zainstalowany: `brew reinstall python@3.12`
        EOS
        raise "Błąd: Moduł venv niedostępny"
      end
    end

    # Tworzymy środowisko wirtualne
    venv_path = prefix/"venv"
    puts "Tworzenie środowiska wirtualnego w #{venv_path}..."
    unless system(python, "-m", "venv", venv_path, err: :out)
      onoe <<~EOS
        Nie udało się utworzyć środowiska wirtualnego w #{venv_path}!
        Sprawdź, czy masz uprawnienia do zapisu w #{prefix} oraz czy Python 3.12 działa poprawnie.
        Możesz spróbować ręcznie uruchomić komendę: #{python} -m venv #{venv_path}
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
        Możesz sprawdzić zawartość ZIP-a: unzip -l #{prefix}/../rootway-agent.zip
      EOS
      raise "Brak pliku requirements.txt"
    end

    puts "Instalowanie zależności z #{requirements}..."
    unless system(pip, "install", "-r", requirements, err: :out)
      onoe <<~EOS
        Nie udało się zainstalować zależności z #{requirements}!
        Sprawdź, czy plik requirements.txt jest poprawny i czy masz dostęp do internetu.
        Możesz spróbować ręcznie uruchomić komendę: #{pip} install -r #{requirements}
      EOS
      raise "Błąd podczas instalacji zależności"
    end

    puts "Środowisko wirtualne i zależności zostały pomyślnie zainstalowane."
  end

  service do
    run [opt_prefix/"venv/bin/python3", opt_prefix/"main.py"]
    keep_alive true
    working_dir opt_prefix
    log_path var/"log/rootway.log"
    error_log_path var/"log/rootway-error.log"
  end
end
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
    # Tworzymy katalog logów w katalogu użytkownika
    log_dir = "#{ENV["HOME"]}/log"
    puts "Tworzenie katalogu logów w #{log_dir}..."
    mkdir_p log_dir unless Dir.exist?(log_dir)
    unless Dir.exist?(log_dir)
      onoe <<~EOS
        Nie udało się utworzyć katalogu logów w #{log_dir}!
        Upewnij się, że masz uprawnienia do zapisu w katalogu domowym.
      EOS
      raise "Błąd: Nie można utworzyć katalogu logów"
    end

    # Instalujemy wszystkie pliki z ZIP-a do katalogu prefix
    puts "Instalowanie plików z ZIP-a do #{prefix}..."
    prefix.install Dir["*"]

    # Generujemy skrypt do uruchomienia agenta z roota
    puts "Generowanie skryptu run-as-root.sh..."
    (prefix/"run-as-root.sh").write <<~EOS
      #!/bin/bash
      if [ -f "#{prefix}/venv/bin/python3" ]; then
        sudo "#{prefix}/venv/bin/python3" "#{prefix}/main.py"
      else
        echo "Błąd: Środowisko wirtualne nie istnieje w #{prefix}/venv/bin/python3"
        echo "Spróbuj ponownie zainstalować: brew reinstall kamilheree/rootway/rootway"
        echo "Lub utwórz środowisko ręcznie: #{Formula["python@3.12"].opt_bin}/python3 -m venv #{prefix}/venv"
        echo "A następnie zainstaluj zależności: #{prefix}/venv/bin/pip install -r #{prefix}/requirements.txt"
        exit 1
      fi
    EOS
    chmod 0755, prefix/"run-as-root.sh"
  end

  def post_install
    python = Formula["python@3.12"].opt_bin/"python3"

    # Sprawdzamy wersję Pythona i dostępność
    puts "Sprawdzanie Pythona 3.12 w #{python}..."
    unless system(python, "--version", err: :out)
      onoe <<~EOS
        Python 3.12 nie jest poprawnie zainstalowany w #{python}!
        Spróbuj reinstalować Pythona:
        `brew reinstall python@3.12`
      EOS
      raise "Błąd: Python 3.12 niedostępny"
    end

    # Sprawdzamy, czy moduł venv jest dostępny
    puts "Sprawdzanie dostępności modułu venv..."
    unless system(python, "-m", "venv", "--help", err: :out)
      onoe <<~EOS
        Moduł venv nie jest dostępny dla Pythona 3.12!
        Upewnij się, że Python 3.12 jest poprawnie zainstalowany:
        `brew reinstall python@3.12`
        Jeśli problem persistsuje, sprawdź dokumentację Pythona dla Twojego systemu.
      EOS
      raise "Błąd: Moduł venv niedostępny"
    end

    # Tworzymy środowisko wirtualne
    venv_path = prefix/"venv"
    puts "Tworzenie środowiska wirtualnego w #{venv_path}..."
    unless system(python, "-m", "venv", venv_path, err: :out)
      onoe <<~EOS
        Nie udało się utworzyć środowiska wirtualnego w #{venv_path}!
        Upewnij się, że masz uprawnienia do zapisu w #{prefix}.
        Możesz spróbować ręcznie:
        1. #{python} -m venv #{venv_path}
        2. Jeśli to nie działa, sprawdź uprawnienia: chmod -R u+w #{prefix}
        3. Spróbuj ponownie: brew reinstall kamilheree/rootway/rootway
      EOS
      raise "Błąd podczas tworzenia środowiska wirtualnego"
    end

    # Weryfikujemy, czy venv został utworzony
    puts "Weryfikacja środowiska wirtualnego..."
    unless File.exist?(venv_path/"bin/python3")
      onoe <<~EOS
        Środowisko wirtualne w #{venv_path} nie zawiera pliku bin/python3!
        Coś poszło nie tak podczas tworzenia środowiska wirtualnego.
        Spróbuj ręcznie:
        1. #{python} -m venv #{venv_path}
        2. Sprawdź uprawnienia: chmod -R u+w #{prefix}
        3. Spróbuj ponownie: brew reinstall kamilheree/rootway/rootway
      EOS
      raise "Błąd: Nieprawidłowe środowisko wirtualne"
    end

    # Instalujemy zależności z requirements.txt
    pip = venv_path/"bin/pip"
    requirements = prefix/"requirements.txt"
    puts "Sprawdzanie, czy plik requirements.txt istnieje..."
    unless File.exist?(requirements)
      onoe <<~EOS
        Plik requirements.txt nie istnieje w #{prefix}!
        Plik ten powinien znajdować się w paczce ZIP: #{url}
        Sprawdź zawartość ZIP-a:
        1. Pobierz ZIP: curl -L #{url} -o rootway-agent.zip
        2. Sprawdź pliki: unzip -l rootway-agent.zip
        Jeśli plik requirements.txt nie istnieje, skontaktuj się z twórcą pakietu.
      EOS
      raise "Brak pliku requirements.txt"
    end

    puts "Instalowanie zależności z #{requirements}..."
    unless system(pip, "install", "-r", requirements, err: :out)
      onoe <<~EOS
        Nie udało się zainstalować zależności z #{requirements}!
        Możliwe przyczyny:
        1. Plik requirements.txt zawiera nieprawidłowe zależności.
        2. Brak dostępu do internetu.
        Spróbuj ręcznie:
        1. #{pip} install -r #{requirements}
        2. Sprawdź połączenie internetowe.
        3. Sprawdź zawartość pliku: cat #{requirements}
        4. Spróbuj ponownie: brew reinstall kamilheree/rootway/rootway
      EOS
      raise "Błąd podczas instalacji zależności"
    end

    puts "Środowisko wirtualne i zależności zostały pomyślnie zainstalowane."
    puts "Aby uruchomić agenta z uprawnieniami roota, wykonaj:"
    puts "  sudo #{prefix}/run-as-root.sh"
    puts "Upewnij się, że użytkownik ma uprawnienia sudo (sprawdź: sudo -l)."
  end

  service do
    run [prefix/"venv/bin/python3", prefix/"main.py"]
    keep_alive true
    working_dir prefix
    log_path "#{ENV["HOME"]}/log/rootway.log"
    error_log_path "#{ENV["HOME"]}/log/rootway-error.log"
  end

  def caveats
    <<~EOS
      Rootway Agent został zainstalowany pomyślnie.

      Aby uruchomić agenta z uprawnieniami roota, wykonaj:
        sudo #{prefix}/run-as-root.sh

      Upewnij się, że:
      1. Masz uprawnienia sudo (sprawdź: `sudo -l`).
      2. WireGuard (jeśli używany) jest poprawnie skonfigurowany, co może wymagać roota.

      Jeśli instalacja nie powiodła się, sprawdź komunikaty w terminalu i postępuj zgodnie z instrukcjami.
      W razie problemów skontaktuj się z twórcą pakietu: https://github.com/kamilheree/rootway-agent
    EOS
  end
end
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
    
    # Sprawdzamy, czy jest dostępny moduł venv
    unless system(python, "-m", "venv", "--help", out: File::NULL, err: File::NULL)
      opoo <<~EOS
        Wygląda na to, że Python nie ma modułu venv!
        Sprawdzamy, czy masz zainstalowany pakiet python3.12-venv:
          sudo apt install python3.12-venv
        Następnie wykonaj:
          brew postinstall rootway
      EOS

      # Sprawdzamy, czy system może zainstalować brakujący pakiet
      if system("which apt")
        ohai "Instalowanie brakującego pakietu python3.12-venv"
        system("sudo apt install python3.12-venv")
        return
      else
        opoo "Nie wykryto menedżera pakietów apt. Musisz zainstalować python3.12-venv ręcznie."
      end

      # Zatrzymujemy proces, aby użytkownik mógł zainstalować brakujący pakiet
      return
    end

    # Tworzymy środowisko wirtualne
    system python, "-m", "venv", "#{prefix}/venv"
    # Instalujemy wymagane pakiety
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

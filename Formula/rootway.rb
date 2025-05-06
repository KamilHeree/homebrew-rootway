class Rootway < Formula
    desc "Rootway Agent - monitoring serwera i tunel WireGuard"
    homepage "https://twoja-strona.pl"
    url "https://twoja-strona.pl/rootway-agent.zip"
    sha256 "7E1418BF3BD4CCB96ACE8F2930FC8B5DDAA125EC115C1C7C67663171695D71AF"
    license "MIT"
  
    depends_on "python@3.12"
    depends_on "wireguard-tools"
  
    def install
      bin.install "rootway" # Jeśli masz skrypt CLI o nazwie rootway
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
  
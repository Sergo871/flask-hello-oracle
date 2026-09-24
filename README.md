# Flask Hello World - Oracle Autonomous Database

Aplicație Flask simplă care se conectează la **Oracle Autonomous Database (ADB, Always Free)** din Oracle Cloud (OCI) și afișează rezultatul interogării:

```sql
SELECT 'hello world' FROM DUAL
```

## Demo live

| Unde | Link |
|------|------|
| **Linux VM (Oracle Linux 9 + nginx + HTTPS)** | **https://flask-hello-oracle.duckdns.org** |
| Windows Server VM (waitress) | http://141.147.9.113:5000 |

Ambele afișează **hello world**, citit din Oracle Autonomous Database.

## Tehnologii

- Python 3 + Flask
- python-oracledb (mod thin, fără Oracle Instant Client)
- Oracle Autonomous Database (Always Free) + wallet mTLS
- Linux VM (Oracle Linux 9, Ampere A1 Always Free): gunicorn + nginx + systemd, HTTPS Let's Encrypt (certbot)
- Domeniu gratuit DuckDNS: `flask-hello-oracle.duckdns.org`
- Windows Server VM: waitress + Scheduled Task

## Structura proiectului

```text
flask-hello-oracle/
├── app.py                        # aplicația Flask
├── requirements.txt
├── .env.example                  # model pentru variabilele de mediu
├── deploy/
│   ├── linux/
│   │   ├── flask-hello.service   # serviciu systemd (gunicorn)
│   │   └── nginx.conf            # reverse proxy pentru domeniu
│   └── windows/
│       ├── run.ps1               # instalare + pornire pe Windows Server
│       └── install-task.ps1      # pornire automată la boot
└── README.md
```

## Configurare

Parolele **nu** se țin în cod. Copiază `.env.example` în `.env` și completează:

| Variabilă         | Descriere                                   | Implicit            |
|-------------------|---------------------------------------------|---------------------|
| `DB_USER`         | utilizatorul ADB                            | `ADMIN`             |
| `DB_PASSWORD`     | parola utilizatorului (obligatoriu)         | –                   |
| `DB_DSN`          | alias din `tnsnames.ora` al wallet-ului     | `database_high`     |
| `WALLET_DIR`      | folderul cu wallet-ul dezarhivat            | `/home/opc/wallet`  |
| `WALLET_PASSWORD` | parola wallet-ului                          | –                   |

Wallet-ul se descarcă din consola OCI: *Autonomous Database → Database connection → Download wallet*, apoi se dezarhivează în `WALLET_DIR`.

## Rulare pe Linux (Oracle Linux, VM Always Free)

```bash
git clone https://github.com/Sergo871/flask-hello-oracle.git
cd flask-hello-oracle
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env && nano .env
python app.py              # test rapid pe http://IP:5000
```

### Producție: systemd + nginx + domeniu

```bash
sudo dnf install -y git python3 python3-pip nginx

# serviciul systemd (gunicorn pe 127.0.0.1:5000); .env e citit de app.py (python-dotenv)
# SELinux: systemd trebuie să poată executa binarele din venv
sudo semanage fcontext -a -t bin_t "/home/opc/flask-hello-oracle/venv/bin(/.*)?"
sudo restorecon -R /home/opc/flask-hello-oracle/venv/bin
sudo cp deploy/linux/flask-hello.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now flask-hello

# nginx ca reverse proxy
sudo cp deploy/linux/nginx.conf /etc/nginx/conf.d/flask-hello.conf   # server_name = domeniul
sudo setsebool -P httpd_can_network_connect 1                         # SELinux: nginx -> gunicorn
sudo systemctl enable --now nginx
sudo firewall-cmd --permanent --add-service=http --add-service=https
sudo firewall-cmd --reload

# HTTPS cu Let's Encrypt (certbot e în EPEL)
sudo dnf config-manager --enable ol9_developer_EPEL
sudo dnf install -y certbot python3-certbot-nginx
sudo certbot --nginx -d flask-hello-oracle.duckdns.org --redirect
sudo systemctl enable --now certbot-renew.timer                      # reînnoire automată
```

Nu uita:
- în OCI: *VCN → Subnet → Security List* → Ingress rule TCP 80 și 443 din `0.0.0.0/0`;
- DNS: subdomeniul `flask-hello-oracle` pe [duckdns.org](https://www.duckdns.org) → IP-ul public al VM-ului Linux
  (la un domeniu cumpărat, de ex. GoDaddy: înregistrare **A** → IP-ul VM-ului).

Ce rulează efectiv pe VM-ul Linux: `vm-flask` (Oracle Linux 9.8, VM.Standard.A1.Flex 1 OCPU / 6 GB),
proiectul în `/home/opc/flask-hello-oracle`, wallet-ul în `/home/opc/wallet` (`chmod 600`),
serviciile `flask-hello`, `nginx` și `certbot-renew.timer`.

## Rulare pe Windows Server (OCI)

1. Instalează [Python 3](https://www.python.org/downloads/windows/) (bifează *Add python.exe to PATH*) și Git.
2. Dezarhivează wallet-ul, de ex. în `C:\wallet`.
3. În PowerShell:

   ```powershell
   git clone https://github.com/Sergo871/flask-hello-oracle.git
   cd flask-hello-oracle
   copy .env.example .env
   notepad .env        # WALLET_DIR=C:\wallet și parolele
   powershell -ExecutionPolicy Bypass -File .\deploy\windows\run.ps1 -Install
   ```

4. Deschide portul în Windows Firewall (PowerShell ca Administrator):

   ```powershell
   New-NetFirewallRule -DisplayName "Flask 5000" -Direction Inbound -Protocol TCP -LocalPort 5000 -Action Allow
   ```

   și adaugă regula TCP 5000 și în *Security List* din OCI.

5. Verifică: `http://IP-PUBLIC:5000` → **hello world**.

6. Pornire automată la boot (Scheduled Task, rulează ca SYSTEM):

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\deploy\windows\install-task.ps1
   ```

   Oprire / pornire: `Stop-ScheduledTask FlaskHelloOracle` / `Start-ScheduledTask FlaskHelloOracle`.

Ce rulează efectiv pe Windows Server: proiectul în `C:\flask-hello-oracle`, wallet-ul în `C:\wallet`,
Scheduled Task `FlaskHelloOracle` (waitress pe portul 5000, pornește la boot), regula *Flask 5000*
în Windows Firewall și în Security List-ul OCI → http://141.147.9.113:5000.

## Autor

Serghei — practică de producție, Oracle Cloud Infrastructure.

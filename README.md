# Flask Hello World - Oracle Autonomous Database

Aplicație Flask simplă care se conectează la **Oracle Autonomous Database (ADB, Always Free)** din Oracle Cloud (OCI) și afișează rezultatul interogării:

```sql
SELECT 'hello world' FROM DUAL
```

**Demo live (Windows Server, OCI):** http://141.147.9.113:5000

<!-- TODO: domeniul pentru VM-ul Linux (nginx) -->

## Tehnologii

- Python 3 + Flask
- python-oracledb (mod thin, fără Oracle Instant Client)
- Oracle Autonomous Database (Always Free) + wallet mTLS
- Linux VM (Always Free): gunicorn + nginx + systemd
- Windows Server VM: waitress

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
│       └── run.ps1               # instalare + pornire pe Windows Server
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
sudo cp deploy/linux/flask-hello.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now flask-hello

sudo dnf install -y nginx
sudo cp deploy/linux/nginx.conf /etc/nginx/conf.d/flask-hello.conf   # editează server_name
sudo setsebool -P httpd_can_network_connect 1                         # SELinux
sudo systemctl enable --now nginx
sudo firewall-cmd --permanent --add-service=http --add-service=https
sudo firewall-cmd --reload
```

Nu uita:
- în OCI: *VCN → Security List* → Ingress rule pentru porturile TCP 80 și 443;
- la registrar (GoDaddy etc.): înregistrare DNS **A** → IP-ul public al VM-ului;
- HTTPS (opțional): `sudo dnf install certbot python3-certbot-nginx && sudo certbot --nginx`.

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

## Autor

Serghei — practică de producție, Oracle Cloud Infrastructure.

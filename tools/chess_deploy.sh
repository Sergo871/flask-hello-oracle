#!/usr/bin/env bash
# Pune Wizard Chess (AI contra AI) pe vm-flask, la https://flask-hello-oracle.duckdns.org/chess/
# Jocul rulează ca serviciu (wizard-chess) pe 127.0.0.1:5050, iar nginx îl publică la /chess/.
#
# Rulare pe VM:
#   curl -fsSL https://raw.githubusercontent.com/Sergo871/flask-hello-oracle/claude/stoic-curie-f1i8gk/tools/chess_deploy.sh | sudo bash
set -euo pipefail

PORT=5050
REPO="https://github.com/Sergo871/lets-make-a-website.git"
BRANCH="claude/beautiful-tesla-c1c3fm"
SRC="/opt/wizard-chess-src"
NGINX_CONF="/etc/nginx/conf.d/flask-hello.conf"

if [[ $EUID -ne 0 ]]; then echo "Rulează cu sudo." >&2; exit 1; fi

echo "==> Descarc codul jocului"
command -v git >/dev/null || dnf install -y git
if [[ -d "$SRC/.git" ]]; then
  git -C "$SRC" pull -q
else
  git clone -q --depth 1 -b "$BRANCH" "$REPO" "$SRC"
fi

# Portul 80 e ocupat de nginx, așa că jocul ascultă doar local, pe $PORT.
mkdir -p /etc
if [[ -f /etc/wizard-chess.env ]]; then
  sed -i "s|^PORT=.*|PORT=$PORT|" /etc/wizard-chess.env
else
  printf 'PORT=%s\nGEMINI_API_KEY=\nGEMINI_MODEL=gemini-flash-latest\n' "$PORT" > /etc/wizard-chess.env
fi

echo "==> Instalez serviciul"
bash "$SRC/chess/deploy/oracle-setup.sh" || true   # verificarea lui finală pe portul 80 nu se aplică aici
systemctl restart wizard-chess
sleep 2
curl -fsS -o /dev/null "http://127.0.0.1:$PORT/" || { journalctl -u wizard-chess -n 30 --no-pager; exit 1; }

echo "==> nginx: /chess/"
if ! grep -q "location /chess/" "$NGINX_CONF"; then
  cp "$NGINX_CONF" "$NGINX_CONF.bak-chess"
  python3 - "$NGINX_CONF" "$PORT" <<'PY'
import re, sys
path, port = sys.argv[1], sys.argv[2]
text = open(path).read()
block = f"""    location = /chess {{ return 301 /chess/; }}

    location /chess/ {{
        proxy_pass http://127.0.0.1:{port}/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }}

"""
# în blocul HTTPS (după "listen 443"), înainte de primul "location"
i = text.find("listen 443")
if i < 0:
    sys.exit("Nu găsesc blocul HTTPS (listen 443) în " + path)
m = re.compile(r"^[ \t]*location\b", re.M).search(text, i)
if not m:
    sys.exit("Nu găsesc niciun location în blocul HTTPS")
open(path, "w").write(text[:m.start()] + block + text[m.start():])
PY
  if ! nginx -t; then
    cp "$NGINX_CONF.bak-chess" "$NGINX_CONF"
    echo "nginx -t a eșuat, am pus configurația înapoi." >&2
    exit 1
  fi
  systemctl reload nginx
fi

# SELinux (Oracle Linux): nginx trebuie să poată face proxy spre porturi locale
command -v setsebool >/dev/null && setsebool -P httpd_can_network_connect 1 || true

sleep 1
if curl -fsSk -o /dev/null "https://localhost/chess/" -H "Host: flask-hello-oracle.duckdns.org"; then
  echo
  echo "GATA! Jocul: https://flask-hello-oracle.duckdns.org/chess/"
else
  echo "nginx nu răspunde la /chess/. Vezi: sudo tail -n 20 /var/log/nginx/error.log" >&2
  exit 1
fi

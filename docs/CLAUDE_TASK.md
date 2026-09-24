# Sarcină pentru Claude Code (Windows Server)

Context: fac practica pentru dl Pavel Tuhari. Proiectul e în C:\flask-hello-oracle (repo github.com/Sergo871/flask-hello-oracle, branch claude/stoic-curie-f1i8gk). E o aplicație Flask care face SELECT 'hello world' FROM DUAL din Oracle Autonomous Database (ADB, Always Free, regiunea Frankfurt). Pe acest Windows Server merge deja: Scheduled Task "FlaskHelloOracle", http://141.147.9.113:5000. Wallet-ul ADB e în C:\wallet, parolele în C:\flask-hello-oracle\.env. Citește README.md și deploy/ înainte să începi.

Ce a cerut dl Pavel și mai lipsește:
1. Aceeași aplicație pe VM-ul Linux (Oracle Linux, Always Free), cu nginx + un domeniu.
2. Link-ul domeniului pe GitHub (README + câmpul Website din About).
3. Codul unit în main.

Fă pașii în ordine, verifică fiecare pas și oprește-te să mă întrebi când ai nevoie de ceva de la mine.

## PAS 1 – Acces la VM-ul Linux
- Întreabă-mă IP-ul public al VM-ului Linux și calea către cheia SSH privată.
- Repară permisiunile cheii pentru OpenSSH pe Windows (icacls, doar userul curent) și testează: `ssh -i <cheie> opc@<IP> "hostname"`.

## PAS 2 – Deploy pe Linux (prin ssh/scp)
- Instalează git, python3 (3.9+), python3-pip, nginx.
- Clonează repo-ul (branch claude/stoic-curie-f1i8gk) în /home/opc/flask-hello-oracle.
- Copiază cu scp conținutul C:\wallet în /home/opc/wallet și C:\flask-hello-oracle\.env în folderul proiectului, schimbând WALLET_DIR=/home/opc/wallet. chmod 600 pe .env și wallet.
- venv + `pip install -r requirements.txt`; test: `python app.py` și `curl localhost:5000` trebuie să dea hello world.
- Instalează deploy/linux/flask-hello.service (systemd, gunicorn pe 127.0.0.1:5000), `enable --now`.
- nginx cu deploy/linux/nginx.conf; `setsebool -P httpd_can_network_connect 1`; firewall-cmd pentru http și https.
- Dacă ADB refuză conexiunea de pe Linux (ACL), spune-mi ce IP trebuie adăugat în OCI.

## PAS 3 – Porturile în OCI
- Spune-mi pas cu pas ce regulă Ingress să adaug în Security List-ul subnet-ului VM-ului Linux (TCP 80 și 443 din 0.0.0.0/0). Așteaptă confirmarea mea, apoi verifică: `curl http://<IP Linux>/` de aici trebuie să dea hello world.

## PAS 4 – Domeniul
- Întreabă-mă: domeniu gratuit DuckDNS sau domeniu cumpărat (GoDaddy).
- DuckDNS: explică-mi cum creez subdomeniul pe duckdns.org și îl pun pe IP-ul Linux; cere-mi numele. GoDaddy: spune-mi ce înregistrare A să pun.
- Verifică DNS-ul (Resolve-DnsName), pune domeniul în server_name din nginx, reload.
- HTTPS cu certbot (--nginx) dacă se poate; dacă nu, rămâne http și spune-mi de ce.
- Verifică de aici că http(s)://<domeniu>/ arată hello world.

## PAS 5 – GitHub
- Actualizează README.md: link-ul live cu domeniul (sus, vizibil) + link-ul Windows http://141.147.9.113:5000; completează secțiunile Linux/Windows cu ce s-a făcut efectiv.
- Commit și push pe branch-ul claude/stoic-curie-f1i8gk, apoi unește-l în main (merge, fără force push). Dacă git cere logare la GitHub, spune-mi ce să fac.
- Spune-mi cum pun domeniul în câmpul Website din About (sau fă-o cu `gh repo edit --homepage` dacă gh e disponibil).

## PAS 6 – Siguranță
- Parola ADMIN a bazei și a wallet-ului au fost publicate în istoricul git. Spune-mi cum schimb parola ADMIN în OCI, apoi actualizează DB_PASSWORD în .env pe Windows și pe Linux, repornește ambele servicii și verifică din nou ambele link-uri.

## Reguli
- Nu urca niciodată pe git .env, wallet-ul, cheile SSH sau parole.
- Nu șterge nimic fără să mă întrebi.
- La final dă-mi un rezumat scurt în română: ce link-uri merg, ce s-a făcut, ce a rămas, plus un mesaj gata de trimis dlui Pavel.

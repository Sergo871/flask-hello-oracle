# Pornește aplicația pe Windows Server (PowerShell), din folderul proiectului.
# Prima rulare:  .\deploy\windows\run.ps1 -Install
param([switch]$Install)

Set-Location (Join-Path $PSScriptRoot "..\..")

if ($Install -or -not (Test-Path ".\venv")) {
    python -m venv venv
    .\venv\Scripts\python.exe -m pip install --upgrade pip
    .\venv\Scripts\python.exe -m pip install -r requirements.txt
}

.\venv\Scripts\waitress-serve.exe --host=0.0.0.0 --port=5000 app:app

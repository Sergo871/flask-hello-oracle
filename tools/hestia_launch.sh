#!/bin/bash
# Creează VM-ul vm-hestia (Ubuntu 24.04, A1.Flex 1 OCPU / 6 GB) și reîncearcă
# până când Oracle are capacitate ARM liberă ("Out of host capacity").
# Rulează pe vm-flask cu autentificare instance principal (dynamic group + policy).
export OCI_CLI_AUTH=instance_principal
MD=http://169.254.169.254/opc/v2
C=$(curl -s -H "Authorization: Bearer Oracle" $MD/instance/ | jq -r .compartmentId)
SUBNET=ocid1.subnet.oc1.eu-frankfurt-1.aaaaaaaanp63otm4eqwdkyhfmt5lkocjsbfc62suwznvgqh6lcq7yxkbdmaa
IMG=ocid1.image.oc1.eu-frankfurt-1.aaaaaaaa4yruuzv353vx4cf3tcsimt5xqvls6reilpxccqhxbyfk6rzn57qq
KEY=$HOME/.ssh/authorized_keys
ADS="eoNu:EU-FRANKFURT-1-AD-1 eoNu:EU-FRANKFURT-1-AD-2 eoNu:EU-FRANKFURT-1-AD-3"

command -v oci >/dev/null || { echo "EROARE: oci nu e instalat"; exit 1; }
command -v jq >/dev/null || { echo "EROARE: jq nu e instalat"; exit 1; }
[ -n "$C" ] && [ "$C" != null ] || { echo "EROARE: nu am aflat compartimentul din metadata"; exit 1; }
echo "compartiment: $C"

# verificare: are vm-flask dreptul să lucreze cu instanțe? (grupul dinamic + politica)
if ! LIST=$(oci compute instance list -c "$C" --all 2>&1); then
  echo "EROARE de acces (grupul dinamic / politica):"; echo "$LIST" | grep -E '"(code|message)"'; exit 1
fi
[ -n "$LIST" ] || LIST='{"data":[]}'
EXIST=$(echo "$LIST" | jq -r '.data[]? | select(."display-name"=="vm-hestia" and ."lifecycle-state"!="TERMINATED") | ."lifecycle-state"')
if [ -n "$EXIST" ]; then echo "vm-hestia exista deja (stare: $EXIST)"; exit 0; fi
echo "acces OK, incep sa incerc crearea vm-hestia"

while true; do
  for AD in $ADS; do
    if oci compute instance launch -c "$C" --availability-domain "$AD" --display-name vm-hestia \
        --shape VM.Standard.A1.Flex --shape-config '{"ocpus":1,"memoryInGBs":6}' \
        --image-id "$IMG" --subnet-id "$SUBNET" --assign-public-ip true \
        --ssh-authorized-keys-file "$KEY" > "$HOME/hestia_out.json" 2> "$HOME/hestia_err.txt"; then
      echo "$(date '+%d.%m %H:%M') === CREAT in $AD ==="; exit 0
    fi
    echo "$(date '+%d.%m %H:%M') $AD: $(grep -o '"message": "[^"]*' "$HOME/hestia_err.txt" | head -1 | cut -c13-)"
  done
  sleep 180
done

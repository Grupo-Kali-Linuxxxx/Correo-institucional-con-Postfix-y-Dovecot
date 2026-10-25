#!/usr/bin/env bash
# publicar_dns_correo.sh — Publica en la zona horizonte.internal (ns1) la clave pública DKIM y la política DMARC.
# Ejecutar EN ns1 después de instalar_correo_seguro.sh horizonte (en mail).
set -euo pipefail
cd "$(dirname "$0")"
[[ $EUID -eq 0 ]] || { echo "Ejecuta como root"; exit 1; }
ZONA=/var/lib/bind/db.horizonte.internal
[[ -s compartido/mail._domainkey.txt ]] || { echo "Falta compartido/mail._domainkey.txt: ejecuta primero el instalador en mail"; exit 1; }

# $INCLUDE: los registros del correo viven en un archivo aparte; la zona solo lo incluye (una sola vez)
install -o bind -g bind -m 644 compartido/mail._domainkey.txt /var/lib/bind/dkim-horizonte.inc
install -o bind -g bind -m 644 dns/dmarc.txt /var/lib/bind/dmarc-horizonte.inc
grep -q 'dkim-horizonte.inc' "$ZONA" || printf '\n$INCLUDE /var/lib/bind/dkim-horizonte.inc\n$INCLUDE /var/lib/bind/dmarc-horizonte.inc\n' >> "$ZONA"

# Subir el serial (AAAAMMDDnn): sin esto, ns2 no copia el cambio
actual=$(awk '/; serial/{print $1; exit}' "$ZONA")
nuevo=$(( actual + 1 ))
sed -i "0,/$actual *; serial/s//$nuevo  ; serial/" "$ZONA"
named-checkzone horizonte.internal "$ZONA"

# Con vistas (Lab 9) la zona vive en la vista interna; sin vistas, basta rndc reload horizonte.internal
rndc reload horizonte.internal IN interna 2>/dev/null || rndc reload horizonte.internal
sleep 2
echo "DKIM:  $(dig +short @10.10.10.2 mail._domainkey.horizonte.internal TXT | cut -c1-60)…"
echo "DMARC: $(dig +short @10.10.10.2 _dmarc.horizonte.internal TXT)"
echo "SPF:   $(dig +short @10.10.10.2 horizonte.internal TXT | grep spf1)"

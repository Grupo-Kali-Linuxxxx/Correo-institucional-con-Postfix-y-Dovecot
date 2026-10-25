#!/usr/bin/env bash
# instalar_correo.sh — Postfix para el colegio (nodo mail) o para familia.internal (nodo mail2).
# Uso:  en mail:   bash /lab/lab12/instalar_correo.sh horizonte
#       en mail2:  bash /lab/lab12/instalar_correo.sh familia
set -euo pipefail
cd "$(dirname "$0")"
[[ $EUID -eq 0 ]] || { echo "Ejecuta como root"; exit 1; }
DOMINIO="${1:?Uso: bash instalar_correo.sh horizonte|familia}"

case $DOMINIO in
  horizonte) CONF=postfix/horizonte.cf; MAILNAME=horizonte.internal; USUARIOS="ti secretaria rosario.vaca" ;;
  familia)   CONF=mail2/familia.cf;     MAILNAME=familia.internal;   USUARIOS="rosa.mamani" ;;
  *) echo "Dominio desconocido"; exit 1 ;;
esac

# 1. Postfix sin preguntas (debconf): "Internet Site" con el nombre del dominio
if ! dpkg -s postfix &>/dev/null; then
  echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
  echo "postfix postfix/mailname string $MAILNAME"            | debconf-set-selections
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq postfix swaks >/dev/null
fi

# 2. Buzones: usuarios del sistema con contraseña (Dovecot los usará en la clase 13)
for u in $USUARIOS; do
  id "$u" &>/dev/null || useradd -m -s /usr/sbin/nologin "$u"
  echo "$u:Horizonte2026!" | chpasswd
done

# 3. Configuración: cada línea clave = valor del archivo → postconf -e
grep -Ev '^\s*(#|$)' "$CONF" | while IFS= read -r linea; do postconf -e "$linea"; done
if [[ $DOMINIO == horizonte ]]; then install -m 644 postfix/aliases /etc/aliases; newaliases; fi
echo "$MAILNAME" > /etc/mailname

# 4. Validar y aplicar
postfix check
systemctl enable postfix >/dev/null 2>&1
systemctl restart postfix
sleep 1
echo "Postfix de $MAILNAME listo. Cambios respecto de los valores por defecto:"
postconf -n | grep -E '^(myhostname|mydestination|mynetworks|home_mailbox|smtpd_relay_restrictions) '

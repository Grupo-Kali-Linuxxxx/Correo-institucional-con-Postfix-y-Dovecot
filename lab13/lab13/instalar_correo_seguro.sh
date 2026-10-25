#!/usr/bin/env bash
# instalar_correo_seguro.sh — IMAPS (Dovecot), envío autenticado (587) y SPF/DKIM/DMARC.
# Uso (DESPUÉS del Laboratorio 12):
#   en mail:   bash /lab/lab13/instalar_correo_seguro.sh horizonte   (firma DKIM)
#   en mail2:  bash /lab/lab13/instalar_correo_seguro.sh familia     (verifica SPF y DKIM)
#   en ns1:    bash /lab/lab13/publicar_dns_correo.sh                (publica DKIM y DMARC)
set -euo pipefail
cd "$(dirname "$0")"
[[ $EUID -eq 0 ]] || { echo "Ejecuta como root"; exit 1; }
DOMINIO="${1:?Uso: bash instalar_correo_seguro.sh horizonte|familia}"
case $DOMINIO in
  horizonte) FQDN=mail.horizonte.internal ;;
  familia)   FQDN=mail.familia.internal ;;
  *) echo "Dominio desconocido"; exit 1 ;;
esac
dpkg -s postfix &>/dev/null || { echo "Primero completa el Laboratorio 12 en este nodo"; exit 1; }

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq dovecot-imapd opendkim opendkim-tools postfix-policyd-spf-python curl >/dev/null

# 1. Certificado del servidor firmado por la CA de correo del laboratorio (la CA se crea una sola vez en compartido/)
install -d -m 755 compartido
if [[ ! -s compartido/ca-correo.crt ]]; then
  openssl ecparam -name prime256v1 -genkey -noout -out compartido/ca-correo.key
  openssl req -x509 -new -key compartido/ca-correo.key -sha256 -days 1825 -out compartido/ca-correo.crt \
    -subj "/O=Laboratorio de correo TW1/CN=CA Correo Laboratorio" -addext "basicConstraints=critical,CA:TRUE"
fi
install -d -m 700 /etc/dovecot/private
openssl ecparam -name prime256v1 -genkey -noout -out /etc/dovecot/private/mail.key
openssl req -new -key /etc/dovecot/private/mail.key -subj "/CN=$FQDN" -out /tmp/mail.csr
printf 'subjectAltName=DNS:%s\nextendedKeyUsage=serverAuth\n' "$FQDN" > /tmp/mail.ext
openssl x509 -req -in /tmp/mail.csr -CA compartido/ca-correo.crt -CAkey compartido/ca-correo.key -CAcreateserial \
  -days 90 -sha256 -extfile /tmp/mail.ext -out /etc/dovecot/private/mail.crt 2>/dev/null
chmod 600 /etc/dovecot/private/mail.key
install -m 644 compartido/ca-correo.crt /usr/local/share/ca-certificates/ca-correo-laboratorio.crt
update-ca-certificates >/dev/null

# 2. Dovecot: IMAPS y autenticación para Postfix
install -m 644 dovecot/99-horizonte.conf /etc/dovecot/conf.d/99-horizonte.conf
doveconf -n >/dev/null
systemctl enable dovecot >/dev/null 2>&1
systemctl restart dovecot

# 3. Postfix: mismo certificado en el 25 y servicio "submission" (587) que EXIGE TLS y usuario/contraseña
postconf -e "smtpd_tls_cert_file = /etc/dovecot/private/mail.crt" \
            "smtpd_tls_key_file = /etc/dovecot/private/mail.key" \
            "smtpd_sasl_type = dovecot" \
            "smtpd_sasl_path = private/auth" \
            "smtpd_sasl_auth_enable = no"
postconf -M "submission/inet=submission inet n - y - - smtpd"
grep -Ev '^\s*(#|$)' postfix/submission.txt | while IFS= read -r linea; do postconf -P "submission/inet/$linea"; done
# Cada usuario solo puede enviar con SU propia dirección
printf '/^([^@]+)@%s\\.internal$/ ${1}\n' "$DOMINIO" > /etc/postfix/remitentes.pcre
dpkg -s postfix-pcre &>/dev/null || apt-get install -y -qq postfix-pcre >/dev/null

# 4. DKIM y SPF según el papel del servidor
install -d -o opendkim -g opendkim -m 750 /etc/opendkim/keys /run/opendkim
if [[ $DOMINIO == horizonte ]]; then
  # Firmar: la clave privada queda en el servidor; la pública (TXT) se entrega al DNS (ns1)
  if [[ ! -s /etc/opendkim/keys/mail.private ]]; then
    opendkim-genkey -b 2048 -d horizonte.internal -s mail -D /etc/opendkim/keys
    chown opendkim:opendkim /etc/opendkim/keys/mail.private
  fi
  install -m 644 /etc/opendkim/keys/mail.txt compartido/mail._domainkey.txt
  install -m 644 opendkim/opendkim-firma.conf /etc/opendkim.conf
else
  # Verificar: DKIM con OpenDKIM y SPF con policyd-spf (agregan cabeceras con el resultado)
  install -m 644 opendkim/opendkim-verifica.conf /etc/opendkim.conf
  postconf -M "policyd-spf/unix=policyd-spf unix - n n - 0 spawn user=policyd-spf argv=/usr/bin/policyd-spf"
  postconf -e "policyd-spf_time_limit = 3600" \
              "smtpd_recipient_restrictions = reject_non_fqdn_recipient, reject_unknown_recipient_domain, permit_mynetworks, reject_unauth_destination, check_policy_service unix:private/policyd-spf"
fi
postconf -e "milter_default_action = accept" "smtpd_milters = inet:localhost:8891" "non_smtpd_milters = inet:localhost:8891"
systemctl enable opendkim >/dev/null 2>&1
systemctl restart opendkim

postfix check
systemctl restart postfix
sleep 1
ss -tln | grep -E ':(25|587|993|143) ' | awk '{print "escuchando:", $4}'
[[ $DOMINIO == horizonte ]] && echo "Siguiente: en ns1, bash /lab/lab13/publicar_dns_correo.sh"
echo "Correo seguro de $FQDN listo."

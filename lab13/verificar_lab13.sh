#!/usr/bin/env bash
# verificar_lab13.sh — Comprueba IMAPS, envío autenticado y SPF/DKIM/DMARC. Ejecutar en el nodo CLIENTE:
#   docker compose exec cliente bash /lab/lab13/verificar_lab13.sh
cd "$(dirname "$0")"
ok=0; total=0
revisar() {
  local desc="$1"; shift; total=$((total + 1))
  if "$@" &>/dev/null; then echo "✅ $desc"; ok=$((ok + 1)); else echo "❌ $desc"; fi
}
CLAVE='Horizonte2026!'
M=mail.horizonte.internal; F=mail.familia.internal
command -v swaks >/dev/null || { apt-get update -qq; apt-get install -y -qq swaks >/dev/null; }
if [[ -s compartido/ca-correo.crt && ! -s /usr/local/share/ca-certificates/ca-correo-laboratorio.crt ]]; then
  install -m 644 compartido/ca-correo.crt /usr/local/share/ca-certificates/ca-correo-laboratorio.crt; update-ca-certificates >/dev/null 2>&1
fi
enviar() { swaks --server $M --port 587 --tls --auth LOGIN --auth-user "$1" --auth-password "$CLAVE" --from "$2" --to "$3" --h-Subject "$4" --body "Prueba del verificador." 2>&1; }

cert_valido()  { echo | openssl s_client -connect $M:993 -servername $M -verify_return_error 2>&1 | grep -q 'Verification: OK'; }
imaps_ok()     { curl -s imaps://$M/INBOX --user "secretaria:$CLAVE" -X 'STATUS INBOX (MESSAGES)' | grep -q 'MESSAGES'; }
imaps_malo()   { ! curl -s -m 5 imaps://$M/INBOX --user 'secretaria:clave-incorrecta' -X 'STATUS INBOX (MESSAGES)'; }
sin_143()      { ! curl -s -m 5 imap://$M/ --user "secretaria:$CLAVE"; }
sin_auth_claro(){ swaks --server $M --port 587 --auth LOGIN --auth-user secretaria --auth-password "$CLAVE" --from secretaria@horizonte.internal --to ti@horizonte.internal 2>&1 | grep -q 'did not advertise authentication'; }
sin_login()    { swaks --server $M --port 587 --tls --from secretaria@horizonte.internal --to rosa.mamani@familia.internal 2>&1 | grep -qE '^<~\* (553|554)'; }
# Ojo: primero se guarda TODA la salida; un "| grep -q" cortaría a swaks antes de enviar el mensaje
con_login()    { local r; r=$(enviar secretaria secretaria@horizonte.internal rosa.mamani@familia.internal "Verificador $$"); grep -q '235 2.7.0' <<<"$r" && grep -q 'queued as' <<<"$r"; }
ajeno()        { local r; r=$(enviar secretaria rosario.vaca@horizonte.internal rosa.mamani@familia.internal "Ajeno"); grep -q 'not owned by user secretaria' <<<"$r"; }
txt()          { dig +short "$1" TXT | tr -d '"' | grep -q "$2"; }
cabeceras()    { local n; sleep 4
                 n=$(curl -s imaps://$F/INBOX --user "rosa.mamani:$CLAVE" -X "SEARCH SUBJECT \"Verificador $$\"" | awk '{print $NF}' | tr -d '\r')
                 [[ -n $n ]] && curl -s "imaps://$F/INBOX;MAILINDEX=$n" --user "rosa.mamani:$CLAVE" > /tmp/v13.eml; }
dkim_pass()    { grep -q 'dkim=pass.*header.d=horizonte.internal' /tmp/v13.eml; }
spf_pass()     { grep -q '^Received-SPF: Pass' /tmp/v13.eml; }
alineado()     { grep -q '^From: secretaria@horizonte.internal' /tmp/v13.eml && grep -q 'd=horizonte.internal;' /tmp/v13.eml; }

revisar "Certificado de IMAPS válido para la CA de correo"        cert_valido
revisar "IMAPS (993) con usuario y contraseña"                    imaps_ok
revisar "IMAPS rechaza una contraseña incorrecta"                 imaps_malo
revisar "IMAP sin cifrar (143) cerrado"                           sin_143
revisar "587 sin TLS no ofrece autenticación"                     sin_auth_claro
revisar "587 sin usuario: rechazado"                              sin_login
revisar "587 con usuario y TLS: aceptado (235 + cola)"            con_login
revisar "No se puede enviar con la dirección de otra persona"     ajeno
revisar "SPF publicado (v=spf1 mx -all)"                          txt horizonte.internal 'v=spf1 mx -all'
revisar "Clave DKIM publicada (mail._domainkey)"                  txt mail._domainkey.horizonte.internal 'v=DKIM1'
revisar "DMARC publicado con p=quarantine"                        txt _dmarc.horizonte.internal 'p=quarantine'
revisar "La familia recibe el correo (leído por IMAPS en mail2)"  cabeceras
revisar "DKIM: dkim=pass en el destino"                           dkim_pass
revisar "SPF: Received-SPF: Pass en el destino"                   spf_pass
revisar "Alineación DMARC: From y firma del mismo dominio"        alineado
echo "Resultado: $ok de $total comprobaciones"
[[ $ok -eq $total ]]

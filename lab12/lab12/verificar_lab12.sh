#!/usr/bin/env bash
# verificar_lab12.sh — Comprueba el Postfix del colegio. Ejecutar EN el nodo mail:
#   docker compose exec mail bash /lab/lab12/verificar_lab12.sh
# Truco: desde mail, "--server 127.0.0.1" entra como red de confianza; "--server 10.10.10.25" entra con la IP
# 10.10.10.25, que NO está en mynetworks: así se prueba el relay desde "afuera".
cd "$(dirname "$0")"
ok=0; total=0
revisar() {
  local desc="$1"; shift; total=$((total + 1))
  if "$@" &>/dev/null; then echo "✅ $desc"; ok=$((ok + 1)); else echo "❌ $desc"; fi
}
S() { swaks --silent 1 --server "$@" 2>&1; }
cuenta() { ls "/home/$1/Maildir/new" 2>/dev/null | wc -l; }

mynet_cerrada() { ! postconf -h mynetworks | grep -qE '0\.0\.0\.0/0|10\.10\.10\.0/24'; }
entrega_maildir(){ local a; a=$(cuenta ti); S 127.0.0.1 --from secretaria@horizonte.internal --to ti@horizonte.internal >/dev/null; sleep 2; (( $(cuenta ti) > a )); }
alias_doble()  { local a b; a=$(cuenta secretaria); b=$(cuenta rosario.vaca)
                 S 127.0.0.1 --from prueba@horizonte.internal --to inscripciones@horizonte.internal >/dev/null; sleep 2
                 (( $(cuenta secretaria) > a && $(cuenta rosario.vaca) > b )); }
sin_relay()    { S 10.10.10.25 --from prueba@familia.internal --to rosa.mamani@familia.internal | grep -q '554 5.7.1.*Relay access denied'; }
sale_a_familia(){ local id; id=$(S 127.0.0.1 --from ti@horizonte.internal --to rosa.mamani@familia.internal | grep -o 'queued as [A-F0-9]*' | awk '{print $3}')
                 sleep 3; grep "$id: to=<rosa.mamani@familia.internal>" /var/log/mail.log | grep -q 'relay=mail.familia.internal.*status=sent'; }
sin_vrfy()     { local r; r=$(printf 'EHLO prueba\r\nVRFY ti\r\nQUIT\r\n' | nc -C -w 3 127.0.0.1 25); ! grep -q '250-VRFY' <<<"$r" && grep -q '^502' <<<"$r"; }
starttls()     { printf 'EHLO prueba\r\nQUIT\r\n' | nc -C -w 3 127.0.0.1 25 | grep -q 'STARTTLS'; }
banner()       { printf 'QUIT\r\n' | nc -C -w 3 127.0.0.1 25 | head -1 | tr -d '\r' | grep -qx '220 mail.horizonte.internal ESMTP'; }

command -v swaks >/dev/null && command -v nc >/dev/null || apt-get install -y -qq swaks netcat-openbsd >/dev/null 2>&1
revisar "postfix check sin errores"                              postfix check
revisar "Postfix activo y escuchando en el puerto 25"            bash -c "systemctl is-active postfix && ss -tln | grep -q ':25 '"
revisar "El MX de horizonte.internal apunta a este servidor"      bash -c "dig +short horizonte.internal MX | grep -q 'mail.horizonte.internal'"
revisar "Acepta horizonte.internal como destino final"           bash -c "postconf -h mydestination | grep -q 'mydomain\|horizonte.internal'"
revisar "mynetworks NO está abierta a toda la red"               mynet_cerrada
revisar "Entrega local en Maildir"                               entrega_maildir
revisar "Alias inscripciones → secretaria y dirección"           alias_doble
revisar "Relay desde fuera rechazado (554 Relay access denied)"  sin_relay
revisar "Envío a otro dominio por su MX (familia.internal)"      sale_a_familia
revisar "VRFY desactivado (no revela usuarios)"                  sin_vrfy
revisar "Ofrece STARTTLS"                                        starttls
revisar "Saludo sin versión del sistema"                         banner
echo "Resultado: $ok de $total comprobaciones"
[[ $ok -eq $total ]]

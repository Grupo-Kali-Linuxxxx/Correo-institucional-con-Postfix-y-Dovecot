#!/usr/bin/env bash
# instalar_dns_correo.sh — En el RESOLUTOR: agrega el DNS simulado de familia.internal (el otro dominio).
# Uso:  docker compose exec resolutor bash /lab/lab12/instalar_dns_correo.sh
set -euo pipefail
cd "$(dirname "$0")"
install -m 644 unbound/familia-internal.conf /etc/unbound/unbound.conf.d/
unbound-checkconf
systemctl restart unbound
sleep 1
echo "MX de familia.internal: $(dig +short @127.0.0.1 familia.internal MX)"
echo "MX de horizonte.internal: $(dig +short @127.0.0.1 horizonte.internal MX)"

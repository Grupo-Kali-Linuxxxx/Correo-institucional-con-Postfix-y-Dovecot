# Laboratorio 13 — Hoja de trabajo: correo seguro (IMAPS, envío autenticado, SPF, DKIM y DMARC)

Nombre: ______________________   Fecha: ___/___/2026

Requisito: Laboratorio 12 en 12/12 (Postfix en mail y mail2). Contraseña de los buzones: `Horizonte2026!`.

## Parte A — Instalación (en este orden)
1. En mail: `bash /lab/lab13/instalar_correo_seguro.sh horizonte`
2. En ns1: `bash /lab/lab13/publicar_dns_correo.sh`
3. En mail2: `bash /lab/lab13/instalar_correo_seguro.sh familia`
4. En el cliente: `bash /lab/lab13/verificar_lab13.sh` → anota el puntaje inicial: ____ de 15.

## Parte B — Leer el correo con IMAPS (Dovecot)
1. Completa los 3 TODO de `dovecot/99-horizonte.conf` y reinstala en mail.
2. Desde el cliente:
   `curl -s imaps://mail.horizonte.internal/INBOX --user 'secretaria:Horizonte2026!' -X 'STATUS INBOX (MESSAGES)'`
3. `echo | openssl s_client -connect mail.horizonte.internal:993` → ¿quién emitió el certificado? ¿Se verifica?
4. ¿Qué pasa con `curl imap://mail.horizonte.internal/` (puerto 143)? ¿Por qué se cerró?
5. (Opcional) Configura Thunderbird: IMAP 993 SSL/TLS y SMTP 587 STARTTLS, con la CA del laboratorio instalada.

## Parte C — Enviar con usuario y contraseña (puerto 587)
Completa los 3 TODO de `postfix/submission.txt` y reinstala. Desde el cliente prueba y explica cada resultado:

| Prueba | Resultado | ¿Por qué? |
|---|---|---|
| 587 con TLS pero sin usuario | | |
| 587 con usuario pero sin TLS | | |
| 587 con TLS y usuario secretaria | | |
| secretaria enviando como rosario.vaca@ | | |

Comando base: `swaks --server mail.horizonte.internal --port 587 --tls --auth LOGIN --auth-user secretaria --auth-password 'Horizonte2026!' --from secretaria@horizonte.internal --to rosa.mamani@familia.internal`

## Parte D — SPF, DKIM y DMARC
1. `dig +short horizonte.internal TXT`, `dig +short mail._domainkey.horizonte.internal TXT`, `dig +short _dmarc.horizonte.internal TXT`: explica cada registro.
2. Si el destino dice `dkim=fail reason="key not found in DNS"`, completa el TODO de OpenDKIM (pista: ¿qué
   resolutor usa?). ¿Por qué `dig` sí encuentra la clave y OpenDKIM no?
3. Completa el TODO de `dns/dmarc.txt` y vuelve a publicar en ns1.
4. Envía un correo a rosa.mamani y léelo por IMAPS en mail2. Copia y explica las cabeceras `Received-SPF`,
   `DKIM-Signature` y `Authentication-Results`.
5. En mail2, con la biblioteca de SPF:
   `python3 -c "import spf; print(spf.check2(i='10.10.10.26', s='ti@horizonte.internal', h='x'))"`
   ¿Qué responde para 10.10.10.25 y para 10.10.10.26? ¿Qué significa?
6. En mail2, toma el archivo de ese correo en `Maildir` y compruébalo con `opendkim-testmsg < archivo`. Luego cambia una
   palabra del texto en una copia y repite. ¿Qué demuestra?
7. Explica con tus palabras la **alineación** de DMARC en tu correo de prueba.

## Parte E — Verificación
`bash /lab/lab13/verificar_lab13.sh` → objetivo **15 de 15**.

## Reflexión
Compara tu servidor con Google Workspace o Microsoft 365: ¿qué de lo que configuraste hoy hacen ellos por ti y qué
sigue siendo responsabilidad del administrador del dominio (pista: el DNS)?

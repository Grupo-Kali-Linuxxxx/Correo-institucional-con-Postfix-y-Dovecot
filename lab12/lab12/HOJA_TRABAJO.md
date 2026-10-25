# Laboratorio 12 — Hoja de trabajo: el correo del colegio con Postfix

Nombre: ______________________   Fecha: ___/___/2026

Usa `red_dns` actualizada (nodos `mail` 10.10.10.25 y `mail2` 10.10.10.26): `docker compose up -d`.
Requisitos: ns1/ns2 (Lab 7) y el resolutor (Lab 8) funcionando.
Buzones de prueba: `ti`, `secretaria`, `rosario.vaca` (directora) en horizonte.internal y `rosa.mamani` en
familia.internal. Contraseña de todos: `Horizonte2026!` (se usará en la clase 13).

## Parte A — El DNS del correo (en el nodo cliente)
| Comando | Resultado | ¿Qué información aporta? |
|---|---|---|
| `dig +short horizonte.internal MX` | | |
| `dig +short familia.internal MX` | | |
| `dig +short mail.horizonte.internal A` | | |
| `dig +short -x 10.10.10.25` | | |
| `dig +short @10.10.10.4 -x 10.10.10.25` | | |

1. ¿Por qué los dos PTR son distintos?
2. ¿Para qué necesita un servidor de correo un MX, un A y un PTR?

## Parte B — Instalar y configurar (6 TODO)
1. Resolutor: `docker compose exec resolutor bash /lab/lab12/instalar_dns_correo.sh`
2. mail2: `docker compose exec mail2 bash /lab/lab12/instalar_correo.sh familia`
3. En mail, con los archivos tal como vienen: `bash /lab/lab12/instalar_correo.sh horizonte` y luego
   `bash /lab/lab12/verificar_lab12.sh`. Anota el puntaje: ____ de 12.
4. **Prueba de relay** (desde mail, que para sí mismo es "un equipo de afuera"):
   `swaks --server 10.10.10.25 --from prueba@familia.internal --to rosa.mamani@familia.internal`
   ¿El servidor aceptó reenviar un correo entre dos dominios que NO son del colegio? ¿Qué riesgo implica?
5. Completa `postfix/horizonte.cf` (5 TODO) y `postfix/aliases` (1 TODO), reinstala y repite la prueba de relay.
   Verificador → objetivo **12 de 12**.
6. Explica con tus palabras la diferencia entre `mydestination` y `mynetworks`.

## Parte C — SMTP "a mano" (como TELNET, clase 10)
Desde el cliente: `nc -C mail.horizonte.internal 25` y escribe línea por línea:
```
EHLO pc-secretaria.horizonte.internal
MAIL FROM:<secretaria@horizonte.internal>
RCPT TO:<ti@horizonte.internal>
DATA
Subject: Prueba a mano

Hola desde la terminal.
.
QUIT
```
1. Anota cada código de respuesta y su significado.
2. ¿Qué extensiones anuncia EHLO? ¿Aparece VRFY? ¿Por qué importa?
3. ¿Qué diferencia hay entre `MAIL FROM` (el sobre) y la cabecera `From:` del mensaje?

## Parte D — Seguir un correo
1. Desde el cliente: `swaks --server mail.horizonte.internal --from secretaria@horizonte.internal --to rosa.mamani@familia.internal`.
   En mail: `grep <ID> /var/log/mail.log` → explica `relay=`, `delay=`, `dsn=` y `status=`.
2. Envía a `inscripciones@horizonte.internal`: ¿a qué buzones llegó? (mira `orig_to=` en el registro).
3. En mail2: `ls /home/rosa.mamani/Maildir/new` y abre el archivo: explica las cabeceras `Received:`.
4. ¿Qué muestra `postqueue -p` y cuándo tendría correos?

## Parte E — TLS
`echo | openssl s_client -starttls smtp -connect mail.horizonte.internal:25`
1. ¿Qué versión de TLS y qué cifrado se negociaron? ¿Quién emitió el certificado?
2. ¿Por qué entre servidores de correo se acepta un certificado que no se puede verificar?

## Reflexión
¿Por qué la mayoría de las instituciones usa hoy correo gestionado (Google Workspace, Microsoft 365) y cuándo tiene
sentido operar un servidor propio?

# Laboratorio 12 — Hoja de trabajo: el correo del colegio con Postfix

**Estudiante:** Ketfer Gianella Salazar  
**Fecha:** 25/10/2026  
**Docente:** M.Sc. Ing. Jimmy Nataniel Requena Llorentty  
**Materia:** Tecnología Web I (SIS-0150) — Universidad Privada Domingo Savio (UPDS)  
**Entorno de Práctica:** Red Docker `red_dns` (`tw1-dns`) con nodos `mail` (10.10.10.25), `mail2` (10.10.10.26), `resolutor` (10.10.10.4) y `cliente` (10.10.10.50).  

---

## Parte A — El DNS del correo (en el nodo cliente)

Comandos ejecutados en el contenedor `cliente`:

| Comando | Resultado | ¿Qué información aporta? |
|---|---|---|
| `dig +short horizonte.internal MX` | `10 mail.horizonte.internal.` | Prioridad (10) y FQDN del servidor de intercambio de correo autorizado para el dominio del colegio. |
| `dig +short familia.internal MX` | `10 mail.familia.internal.` | Prioridad (10) y FQDN del servidor de correo del dominio externo simulado. |
| `dig +short mail.horizonte.internal A` | `10.10.10.25` | Dirección IP IPv4 a la que debe abrirse el socket TCP en el puerto 25 para entregar correos. |
| `dig +short -x 10.10.10.25` | `mail.tw1-dns_horizonte.` | Resolución PTR del resolver interno embebido de Docker (`127.0.0.11`), identificando el contenedor en su red bridge. |
| `dig +short @10.10.10.4 -x 10.10.10.25` | `mail.horizonte.internal.` | Resolución PTR oficial del resolutor institucional Unbound (delegado a `ns1`), correspondiente a la zona inversa `10.10.10.in-addr.arpa`. |

### Preguntas conceptuales:
1. **¿Por qué los dos PTR son distintos?**  
   Porque consultan a servidores DNS con ámbitos y propósitos diferentes. El primer comando (`dig +short -x 10.10.10.25`) consulta al resolver local por defecto del contenedor provisto por el motor Docker (`127.0.0.11`), el cual resuelve la IP al nombre interno asignado al contenedor dentro de la red virtual de Docker (`mail.tw1-dns_horizonte.`). El segundo comando (`dig +short @10.10.10.4 -x 10.10.10.25`) consulta de forma explícita al resolutor institucional Unbound (`10.10.10.4`), el cual consulta autoritativamente a BIND9 (`ns1` 10.10.10.2) donde reside la zona inversa oficial del colegio `10.10.10.in-addr.arpa`, respondiendo con el nombre canónico FQDN institucional `mail.horizonte.internal.`.

2. **¿Para qué necesita un servidor de correo un MX, un A y un PTR?**  
   - **Registro MX (*Mail Exchanger*):** Indica a cualquier remitente en el mundo qué servidor se encarga de recibir los correos del dominio (ej. `@horizonte.internal -> mail.horizonte.internal`).
   - **Registro A (*Address*):** Traduce el nombre del servidor MX a una dirección IP enrutable para que el remitente pueda establecer la conexión TCP en el puerto 25.
   - **Registro PTR (*Pointer / DNS Inverso*):** Es el mecanismo indispensable para validación de reputación antispam (*Forward-Confirmed Reverse DNS* o FCrDNS). Cuando el servidor `mail` envía un correo a otro servidor, el destinatario verifica que la IP remitente tenga un PTR que coincida con el nombre anunciado y que dicho nombre resuelva a la misma IP. Si no coinciden o no existe PTR, el correo es rechazado o enviado directamente a SPAM por ser considerado una IP residencial o máquina comprometida.

---

## Parte B — Instalar y configurar (6 TODO)

1. En resolutor: `docker compose exec resolutor bash /lab/lab12/instalar_dns_correo.sh`
2. En mail2: `docker compose exec mail2 bash /lab/lab12/instalar_correo.sh familia`
3. En mail: `bash /lab/lab12/instalar_correo.sh horizonte` y `bash /lab/lab12/verificar_lab12.sh`.
4. **Prueba de relay desde el nodo `mail` (conectando a su IP externa `10.10.10.25`):**
   ```bash
   swaks --server 10.10.10.25 --from prueba@familia.internal --to rosa.mamani@familia.internal --quit-after RCPT
   ```
   - **Respuesta obtenida:**  
     `<** 554 5.7.1 <rosa.mamani@familia.internal>: Relay access denied`
   - **¿El servidor aceptó reenviar un correo entre dos dominios que NO son del colegio? ¿Qué riesgo implica?**  
     Con la configuración inicial (`mynetworks = 0.0.0.0/0`), el servidor operaba como un **Open Relay** (retransmisor abierto), aceptando reenviar mensajes entre cualquier dominio externo sin autenticación. El riesgo de un Open Relay es crítico: spammers y botnets mundiales escanean constantemente Internet y, al detectar un servidor abierto, lo utilizan para enviar millones de correos masivos de phishing y malware. Como resultado, la dirección IP del colegio es agregada en cuestión de minutos a las listas negras mundiales (RBL como Spamhaus o Barracuda), impidiendo que la institución pueda volver a comunicarse por correo.
   - Tras corregir `mynetworks = 127.0.0.0/8, 10.10.10.50/32`, el servidor rechaza con éxito todo intento de relay no autorizado con el código `554 5.7.1`.

5. **Ajustes aplicados en `postfix/horizonte.cf` y `postfix/aliases`:**
   - Saludo sin versión del SO: `smtpd_banner = $myhostname ESMTP`
   - Destinos locales aceptados: `mydestination = $myhostname, $mydomain, localhost.$mydomain, localhost`
   - Redes de confianza restringidas: `mynetworks = 127.0.0.0/8, 10.10.10.50/32`
   - Formato de buzón moderno: `home_mailbox = Maildir/`
   - Higiene y anti-enumeración: `disable_vrfy_command = yes`
   - Alias de inscripciones: `inscripciones: secretaria, direccion`

6. **Diferencia entre `mydestination` y `mynetworks`:**  
   - **`mydestination`:** Define para qué dominios este servidor actúa como **destino final**. Cuando llega un correo para un dominio listado en `mydestination` (ej. `horizonte.internal`), Postfix no lo retransmite; busca el buzón local del usuario en el sistema y deposita el archivo en `/home/<usuario>/Maildir/new/`.
   - **`mynetworks`:** Define qué direcciones IP o subredes tienen permiso para usar este servidor como **puente de salida (relay)** hacia otros dominios (ej. hacia `familia.internal` o Internet). Solo el servidor local (`127.0.0.0/8`) y la máquina de secretaría (`10.10.10.50/32`) están autorizados.

---

## Parte C — SMTP "a mano" (con Netcat)

Comando ejecutado desde `cliente`:
```bash
printf 'EHLO pc-secretaria.horizonte.internal\r\nMAIL FROM:<secretaria@horizonte.internal>\r\nRCPT TO:<ti@horizonte.internal>\r\nDATA\r\nSubject: Prueba a mano\r\n\r\nHola desde la terminal.\r\n.\r\nQUIT\r\n' | nc -C mail.horizonte.internal 25
```

### 1. Códigos de respuesta observados y su significado:
- `220 mail.horizonte.internal ESMTP`: Banner de bienvenida del servicio SMTP indicando disponibilidad para recibir comandos.
- `250 (o 250-) Ok`: Código de éxito. Acepta el saludo `EHLO`, confirma el remitente `MAIL FROM` y valida que el destinatario `RCPT TO` existe localmente.
- `354 End data with <CR><LF>.<CR><LF>`: Notificación para iniciar el ingreso del cuerpo del mensaje (concluye con una línea que contiene solo un punto `.`).
- `250 2.0.0 Ok: queued as 97063159A3`: Confirmación de que el mensaje fue aceptado e ingresado en la cola de salida con identificador único.
- `221 2.0.0 Bye`: Cierre ordenado de la sesión de correo.

### 2. Extensiones anunciadas por `EHLO` y comando `VRFY`:
- **Extensiones:** `PIPELINING`, `SIZE 26214400`, `ETRN`, `STARTTLS`, `ENHANCEDSTATUSCODES`, `8BITMIME`, `DSN`, `SMTPUTF8`, `CHUNKING`.
- **¿Aparece VRFY?:** No aparece; se encuentra deshabilitado con `disable_vrfy_command = yes`.
- **¿Por qué importa?:** El comando `VRFY` permite a un atacante enviar listas de nombres para verificar si existen en el sistema. Desactivarlo impide la enumeración automatizada de cuentas de correo y mitiga ataques dirigidos de ingeniería social y fuerza bruta.

### 3. Diferencia entre `MAIL FROM` y la cabecera `From:`:
- `MAIL FROM` (sobre o *Envelope Sender*): Es la dirección remitente transmitida en el protocolo SMTP. Es la que utilizan los servidores para enrutar el correo, aplicar filtros SPF y enviar notificaciones de rebote (*Return-Path*).
- Cabecera `From:`: Es un campo de texto informativo ubicado dentro del contenido del mensaje (`DATA`, RFC 5322). Es el nombre y correo que el usuario final visualiza en su aplicación de correo (Thunderbird o webmail), pero puede ser falsificado fácilmente si no existen políticas estrictas de autenticación.

---

## Parte D — Seguir un correo

### 1. Trazabilidad en `/var/log/mail.log`:
Línea capturada:
```text
Oct 25 06:39:15 mail postfix/smtp[1673]: 1368D12D06: to=<rosa.mamani@familia.internal>, relay=mail.familia.internal[10.10.10.26]:25, delay=0.08, delays=0/0.01/0.06/0.01, dsn=2.0.0, status=sent (250 2.0.0 Ok: queued as 25B441599F)
```
- `relay=mail.familia.internal[10.10.10.26]:25`: Host e IP del servidor remoto al que Postfix entregó el correo vía TCP 25.
- `delay=0.08`: Tiempo total en segundos transcurrido desde la recepción del correo hasta su entrega completa.
- `dsn=2.0.0`: Código de estado de entrega exitosa (*Delivery Status Notification*).
- `status=sent`: Confirmación de que el servidor receptor aceptó la custodia del mensaje.

### 2. Envío a `inscripciones@horizonte.internal`:
- Gracias al alias `inscripciones: secretaria, direccion` y `direccion: rosario.vaca`, el correo se bifurca automáticamente y se entrega simultáneamente en dos buzones: **`secretaria`** y **`rosario.vaca`** (la directora).

### 3. Buzones `Maildir` y cabeceras `Received:` en `mail2`:
- En `mail2`, el correo se almacena en `/home/rosa.mamani/Maildir/new/`. A diferencia del formato monolítico `mbox` (donde todos los correos se agrupan en un solo archivo plano con problemas de concurrencia y bloqueo de archivos), `Maildir` almacena cada mensaje como un archivo individual independiente, facilitando copias de seguridad incrementales y accesos concurrentes de Dovecot (IMAP/POP3).
- Las cabeceras `Received:` documentan la trazabilidad forense cronológica inversa: indican qué servidor entregó el paquete (`mail.horizonte.internal [10.10.10.25]`), qué servidor lo recibió (`mail.familia.internal`), el protocolo (`ESMTP`), la fecha/hora exacta y el ID de transacción.

### 4. Comando `postqueue -p`:
- Muestra el estado de la cola de mensajes de Postfix. Normalmente reporta `Mail queue is empty`.
- Tendría correos acumulados cuando el servidor destinatario está apagado o no responde (quedando en cola diferida o *deferred queue* para reintentos periódicos) o durante ráfagas de envío masivo.

---

## Parte E — Seguridad TLS (STARTTLS)

Comando ejecutado:
```bash
echo | openssl s_client -starttls smtp -connect mail.horizonte.internal:25
```
1. **Versión y Cifrado:**
   - Protocolo: **`TLSv1.3`**
   - Cifrado: **`TLS_AES_256_GCM_SHA384`** (suite AEAD de alta seguridad).
   - Emisor del certificado: Certificado autofirmado de prueba de Ubuntu (`Ubuntu mail server test cert`), configurado con nivel oportunista (`smtpd_tls_security_level = may`).

2. **¿Por qué entre servidores de correo se acepta un certificado que no se puede verificar?**  
   Por el estándar de **TLS Oportunista (STARTTLS / RFC 3207)**: La prioridad histórica del correo en Internet es la **entrega garantizada**. Si los servidores SMTP rechazaran correos cuando una CA es desconocida o autofirmada, se interrumpiría la comunicación de millones de organizaciones. Por ello, el estándar adopta el principio de "cifrar siempre que sea posible": es preferible que la sesión viaje cifrada contra escuchas pasivas en tránsito, aun cuando la identidad no esté respaldada por una CA pública comercial.

---

## Parte F — Verificación Oficial Automatizada (12 de 12)

Comando ejecutado en `mail`:
```bash
bash /lab/lab12/verificar_lab12.sh
```

**Resultado de la comprobación oficial (100% Superado):**
```text
✅ postfix check sin errores
✅ Postfix activo y escuchando en el puerto 25
✅ El MX de horizonte.internal apunta a este servidor
✅ Acepta horizonte.internal como destino final
✅ mynetworks NO está abierta a toda la red
✅ Entrega local en Maildir
✅ Alias inscripciones → secretaria y dirección
✅ Relay desde fuera rechazado (554 Relay access denied)
✅ Envío a otro dominio por su MX (familia.internal)
✅ VRFY desactivado (no revela usuarios)
✅ Ofrece STARTTLS
✅ Saludo sin versión del sistema
Resultado: 12 de 12 comprobaciones
```

---

## Reflexión

### ¿Por qué la mayoría de las instituciones usa hoy correo gestionado (Google Workspace, Microsoft 365) y cuándo tiene sentido operar un servidor propio?

La gran mayoría de las empresas y centros educativos optan por servicios gestionados en la nube debido a que el factor crítico del correo electrónico moderno no es la instalación del software MTA (como Postfix), sino la **gestión de la entregabilidad y la reputación IP**. Mantener una dirección IP limpia en Internet exige un esfuerzo titánico: si una cuenta sufre una filtración de credenciales y envía spam, los grandes proveedores mundiales (Gmail, Outlook, Yahoo) bloquean la IP o envían todos los correos institucionales a la carpeta de correo no deseado. Además, los servicios SaaS garantizan alta disponibilidad geográfica (99.99%), filtros antispam/antiphishing potenciados por aprendizaje automático, y liberan al equipo de TI del mantenimiento continuo de parches y almacenamiento.

Sin embargo, **operar un servidor propio tiene pleno sentido y es indispensable en:**
1. **Soberanía y Cumplimiento Normativo:** Instituciones estatales, militares, judiciales, médicas o financieras donde las leyes nacionales exigen que los datos y comunicaciones confidenciales permanezcan físicamente dentro del territorio nacional y en servidores propios, sin quedar sujetos a legislaciones extraterritoriales (como el *US CLOUD Act*).
2. **Entornos Aislados e Intranets:** Redes de campus, bases operativas o plantas industriales desconectadas de Internet que requieren mensajería interna inmediata, resiliente y de alta capacidad sin consumir ancho de banda de enlace satelital o externo.
3. **Control Absoluto y Privacidad:** Organizaciones que no desean que sus flujos de información sean indexados, analizados con fines de telemetría comercial o dependan de costos de licenciamiento por usuario recurrente.

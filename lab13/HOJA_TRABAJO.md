# Laboratorio 13 — Hoja de trabajo: correo seguro (IMAPS, envío autenticado, SPF, DKIM y DMARC)

**Estudiante:** Ketfer Gianella Salazar  
**Fecha:** 25/10/2026  
**Docente:** M.Sc. Ing. Jimmy Nataniel Requena Llorentty  
**Materia:** Tecnología Web I (SIS-0150) — Universidad Privada Domingo Savio (UPDS)  
**Entorno de Práctica:** Red Docker `red_dns` (`tw1-dns`) con nodos `mail` (10.10.10.25), `mail2` (10.10.10.26), `ns1` (10.10.10.2), `resolutor` (10.10.10.4) y `cliente` (10.10.10.50).  

---

## Parte A — Instalación y Secuencia Operativa

Se ejecutó la secuencia establecida para el despliegue de correo seguro:
1. En `mail`: `bash /lab/lab13/instalar_correo_seguro.sh horizonte` (Generación de CA institucional, certificados TLS para `mail.horizonte.internal`, configuración de Dovecot IMAPS, SASL en Postfix y generación de claves privadas/públicas OpenDKIM).
2. En `ns1`: `bash /lab/lab13/publicar_dns_correo.sh` (Inclusión de `dkim-horizonte.inc` y `dmarc-horizonte.inc` en `/var/lib/bind/db.horizonte.internal`, incremento de número de serie y recarga con `rndc`).
3. En `mail2`: `bash /lab/lab13/instalar_correo_seguro.sh familia` (Configuración de Dovecot IMAPS receptor, OpenDKIM verificador y agente `policyd-spf`).
4. En `cliente`: `bash /lab/lab13/verificar_lab13.sh` -> **15 de 15 comprobaciones superadas (100%)**.

---

## Parte B — Leer el correo con IMAPS (Dovecot)

### 1. Ajustes en `dovecot/99-horizonte.conf`:
- `ssl = required`: Se exige TLS de forma obligatoria, prohibiendo conexiones en claro.
- `inet_listener imap { port = 0 }`: Se desactiva y cierra por completo el puerto estándar 143 sin cifrar.
- `inet_listener imaps { port = 993, ssl = yes }`: Canal exclusivo de recepción IMAPS cifrado.
- `service auth { unix_listener /var/spool/postfix/private/auth ... }`: Socket UNIX con permisos `0660` para que Postfix valide usuarios contra Dovecot (SASL).

### 2. Prueba con `curl` hacia IMAPS (puerto 993):
Comando ejecutado desde `cliente`:
```bash
curl -s imaps://mail.horizonte.internal/INBOX --user 'secretaria:Horizonte2026!' -X 'STATUS INBOX (MESSAGES)'
```
- **Resultado:** `* STATUS INBOX (MESSAGES 2)`  
- Confirma que la autenticación asimétrica y de credenciales fue exitosa y el buzón Maildir contiene 2 mensajes.

### 3. Inspección del Certificado TLS con OpenSSL:
Comando: `echo | openssl s_client -connect mail.horizonte.internal:993`
- **Emisor:** `/O=Laboratorio de correo TW1/CN=CA Correo Laboratorio`.
- **¿Se verifica?:** Sí, la verificación retorna `Verification: OK`. Esto es posible porque el certificado raíz de la Autoridad Certificadora del laboratorio (`ca-correo.crt`) fue instalado y registrado en el almacén de certificados de confianza del sistema (`/usr/local/share/ca-certificates/ca-correo-laboratorio.crt`) mediante `update-ca-certificates`.

### 4. Prueba hacia IMAP sin cifrar (puerto 143):
Comando: `curl -m 3 imap://mail.horizonte.internal/ --user 'secretaria:Horizonte2026!'`
- **Resultado:** `curl: (7) Failed to connect to mail.horizonte.internal port 143: Couldn't connect to server`.
- **Explicación:** El puerto se encuentra totalmente cerrado porque se configuró `port = 0` en el listener `imap`. Esto garantiza el principio de seguridad en tránsito: ninguna credencial ni correo puede ser transmitido en texto claro.

---

## Parte C — Enviar con usuario y contraseña (puerto 587 Submission)

Pruebas ejecutadas desde `cliente` con `swaks`:

| Prueba | Resultado | ¿Por qué? |
|---|---|---|
| **587 con TLS pero sin usuario** | `<~* 554 5.7.1 Relay access denied` | Porque `smtpd_relay_restrictions = permit_sasl_authenticated, reject` exige que el cliente esté formalmente autenticado para hacer relay hacia dominios externos; sin usuario ni contraseña, Postfix rechaza la transacción. |
| **587 con usuario pero sin TLS** | `did not advertise authentication` / `530 Must issue STARTTLS` | Porque `smtpd_tls_auth_only = yes` y `smtpd_tls_security_level = encrypt` prohíben anunciar mecanismos de autenticación (SASL) en conexiones sin cifrar, evitando que la contraseña viaje en texto plano. |
| **587 con TLS y usuario secretaria** | `235 2.7.0 Authentication successful` y `250 2.0.0 Ok: queued as...` | Transacción exitosa: el canal está protegido con TLSv1.3, las credenciales coinciden con las validadas por Dovecot en SASL y el remitente está autorizado. |
| **secretaria enviando como rosario.vaca@** | `<** 553 5.7.1 <rosario.vaca@horizonte.internal>: Sender address rejected: not owned by user secretaria` | Mecanismo Anti-Spoofing: `smtpd_sender_login_maps` y `smtpd_sender_restrictions = reject_sender_login_mismatch` validan que la cuenta autenticada sea dueña legítima de la dirección del sobre (`MAIL FROM`), impidiendo la suplantación interna entre funcionarios. |

---

## Parte D — SPF, DKIM y DMARC

### 1. Registros DNS de Autenticación de Correo:
- `dig +short horizonte.internal TXT` -> `"v=spf1 mx -all"`:  
  **Sender Policy Framework (SPF):** Declara que solo los hosts listados en el registro MX del dominio (`mail.horizonte.internal`) tienen autorización para emitir correos a nombre de `@horizonte.internal`. La directriz estricta `-all` instruye al mundo a descartar o rechazar cualquier correo proveniente de otra IP.
- `dig +short mail._domainkey.horizonte.internal TXT` -> `"v=DKIM1; h=sha256; k=rsa; p=MIIB..."`:  
  **DomainKeys Identified Mail (DKIM):** Publica la clave pública RSA de 2048 bits para el selector `mail`. Permite que cualquier servidor receptor en Internet verifique la firma matemática estampada por OpenDKIM en la cabecera `DKIM-Signature`.
- `dig +short _dmarc.horizonte.internal TXT` -> `"v=DMARC1; p=quarantine; rua=mailto:dmarc@horizonte.internal; ... adkim=s; aspf=s"`:  
  **DMARC:** Política unificadora que vincula SPF y DKIM. Exige que si un correo falla la autenticación alineada con el dominio visible `From:`, sea puesto en cuarentena (`p=quarantine`). Establece alineación estricta (`adkim=s; aspf=s`) y envío de reportes a `dmarc@horizonte.internal`.

### 2. Resolución de claves en OpenDKIM:
- Si OpenDKIM reportaba `key not found in DNS`, se debe a que OpenDKIM por defecto consulta los servidores configurados en `/etc/resolv.conf` (que en Docker apunta al resolver bridge `127.0.0.11` o a IPs públicas como `1.1.1.1`), los cuales desconocen las zonas privadas del laboratorio. `dig` funcionaba porque consultaba explícitamente a `10.10.10.4`. Se solucionó agregando la directiva `Nameservers 10.10.10.4` en `/etc/opendkim.conf`.

### 3. Cabeceras de Verificación en el Servidor Receptor (`mail2`):
Al inspeccionar el correo recibido por `rosa.mamani`:
- `Received-SPF: Pass (mail.familia.internal: domain of secretaria@horizonte.internal designates 10.10.10.25 as permitted sender)`
- `DKIM-Signature: v=1; a=rsa-sha256; d=horizonte.internal; s=mail; ...`
- `Authentication-Results: mail.familia.internal; dkim=pass (2048-bit key) header.d=horizonte.internal; spf=pass ... dmarc=pass`

### 4. Prueba con biblioteca `spf` en Python (`mail2`):
- `spf.check2(i='10.10.10.25', s='ti@horizonte.internal', h='x')` ➔ `('pass', 250, 'sender SPF authorized')`
- `spf.check2(i='10.10.10.26', s='ti@horizonte.internal', h='x')` ➔ `('fail', 550, 'SPF fail - not authorized')`
- **Significado:** La IP `10.10.10.25` es el servidor MX legítimo del colegio; cualquier otra IP (`10.10.10.26`) es calificada como suplantadora no autorizada.

### 5. Integridad Criptográfica con `opendkim-testmsg`:
- Sobre el correo original: `opendkim-testmsg` valida con éxito (código de salida 0).
- Al modificar una sola palabra del cuerpo en una copia: la verificación falla con error `verification failed: bad signature`.
- **Demostración:** DKIM garantiza **no repudio e integridad absoluta**: ningún intermediario ni atacante puede alterar una sola letra del correo sin romper la firma matemática.

### 6. Alineación DMARC:
- El dominio visible en `From:` (`horizonte.internal`) coincide con exactitud matemática con el dominio autenticado por SPF (`MAIL FROM: secretaria@horizonte.internal`) y con el dominio de la firma DKIM (`d=horizonte.internal`), cumpliendo la alineación estricta exigida (`adkim=s`, `aspf=s`).

---

## Parte E — Verificación Oficial Automatizada (15 de 15)

Comando ejecutado en `cliente`:
```bash
bash /lab/lab13/verificar_lab13.sh
```

**Resultado de la comprobación oficial (100% Superado):**
```text
✅ Certificado de IMAPS válido para la CA de correo
✅ IMAPS (993) con usuario y contraseña
✅ IMAPS rechaza una contraseña incorrecta
✅ IMAP sin cifrar (143) cerrado
✅ 587 sin TLS no ofrece autenticación
✅ 587 sin usuario: rechazado
✅ 587 con usuario y TLS: aceptado (235 + cola)
✅ No se puede enviar con la dirección de otra persona
✅ SPF publicado (v=spf1 mx -all)
✅ Clave DKIM publicada (mail._domainkey)
✅ DMARC publicado con p=quarantine
✅ La familia recibe el correo (leído por IMAPS en mail2)
✅ DKIM: dkim=pass en el destino
✅ SPF: Received-SPF: Pass en el destino
✅ Alineación DMARC: From y firma del mismo dominio
Resultado: 15 de 15 comprobaciones
```

---

## Reflexión

### Comparación entre Servidor Propio y Servicios Gestionados (Google Workspace / Microsoft 365)

| Componente del Servicio | Servicio Gestionado (Google / Microsoft 365) | Servidor Propio (Postfix + Dovecot) |
|---|---|---|
| **Infraestructura y Software** | Administrado 100% por el proveedor SaaS (parches, alta disponibilidad y discos). | Responsabilidad del administrador local (mantenimiento de demonios, discos y CA). |
| **Generación y Firma DKIM** | Google/Microsoft generan las claves privadas en sus HSM y firman automáticamente. | El administrador genera con `opendkim-genkey` y configura el milter local en Postfix. |
| **Certificados y TLS en Tránsito** | Provistos y renovados automáticamente por el proveedor en sus servidores de borde. | El administrador gestiona los certificados TLS (Let's Encrypt o CA corporativa). |
| **Publicación de Registros DNS** | **Responsabilidad EXCLUSIVA del cliente (administrador del dominio).** | **Responsabilidad del administrador del dominio.** |
| **Definición de Políticas DMARC** | **Responsabilidad EXCLUSIVA del cliente (el cliente fija `p=quarantine` o `p=reject`).** | **Responsabilidad del administrador del dominio.** |

**Conclusión Fundamental:**  
Incluso cuando una institución contrata el servicio de correo más costoso en la nube (Google Workspace o Microsoft 365), la seguridad y la autenticidad del correo **siguen dependiendo indefectiblemente del administrador del dominio DNS**. Ni Google ni Microsoft pueden publicar el registro SPF en la zona autoritativa del colegio, ni pueden publicar la clave pública DKIM, ni pueden definir la política DMARC; si el administrador del dominio no configura correctamente estos registros en BIND9/DNS, los correos enviados desde Google o Microsoft seguirán siendo rechazados o catalogados como spam en el mundo. La criptografía del correo electrónico es un estándar federado donde el control soberano siempre reside en el servidor DNS del dominio.

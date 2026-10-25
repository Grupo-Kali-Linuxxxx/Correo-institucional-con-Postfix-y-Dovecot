# Bitácora de Uso y Aplicación de Inteligencia Artificial (Formato APA v7)

**Actividad 04:** Correo Institucional Seguro con Postfix y Dovecot  
**Estudiante:** Ketfer Gianella Salazar  
**Carrera:** Ingeniería de Sistemas — Asignatura: Tecnología Web I (SIS-0150)  
**Docente Titular:** M.Sc. Ing. Jimmy Nataniel Requena Llorentty  
**Institución:** Universidad Privada Domingo Savio (UPDS), Sede Santa Cruz de la Sierra  
**Fecha de Elaboración:** 25 de Octubre de 2026  
**Repositorio Oficial de Código (GitHub):**  
[https://github.com/Grupo-Kali-Linuxxxx/Correo-institucional-con-Postfix-y-Dovecot](https://github.com/Grupo-Kali-Linuxxxx/Correo-institucional-con-Postfix-y-Dovecot)  

---

## 1. Declaración Ética y Propósito Metodológico

En cumplimiento del *Reglamento Institucional de Integridad Académica* de la Universidad Privada Domingo Savio y las directrices del docente de la materia, se declara el uso transparente y reflexivo de herramientas de Inteligencia Artificial generativa (**Antigravity / DeepMind AI Coding Assistant**) como apoyo para:
1. Análisis forense de cabeceras de correo electrónico e interpretación de parámetros criptográficos DKIM/DMARC.
2. Diseño de la arquitectura de integración de filtros antispam (Rspamd) y antivirus (ClamAV) mediante protocolo Milter.
3. Estructuración formal de la política institucional de correo y del plan estratégico de migración desde servicios gratuitos.
4. Redacción de scripts de automatización documental y generación de presentaciones en formato APA 7.

Ningún comando o directiva técnica generada por la IA fue desplegada sin previa validación experimental, análisis de sintaxis y contrastación contra los estándares oficiales RFC de correo electrónico.

---

## 2. Registro Cronológico de Prompts y Adaptaciones Técnicas

### Registro 1: Análisis Forense de Cabeceras Criptográficas y Alineación DMARC
- **Fecha y Hora:** 25/10/2026 04:51:00
- **Herramienta de IA:** Antigravity (DeepMind Advanced Coding Agent).
- **Prompt Enviado:**
  > *"Analiza este fragmento real de cabeceras de correo recibido en mail2 desde mail.horizonte.internal: [se pegaron los encabezados con Authentication-Results, Received-SPF y DKIM-Signature]. Explica qué significa cada parámetro de DKIM (a=, c=, d=, s=, bh=, b=) y determina si existe alineación DMARC estricta con el encabezado From: <secretaria@horizonte.internal>."*
- **Respuesta de la IA:**
  La IA desglosó detalladamente el significado de `rsa-sha256`, la canonización `relaxed/simple`, el selector `s=mail` y los hashes `bh=` (cuerpo) y `b=` (cabecera). Confirmó que la alineación DMARC es estricta (`adkim=s`, `aspf=s`) porque tanto el dominio del remitente visible (`From: secretaria@horizonte.internal`), el envelope (`MAIL FROM: secretaria@horizonte.internal`) y el dominio de la firma (`header.d=horizonte.internal`) coinciden de forma exacta sin recurrir a subdominios.
- **Evaluación Crítica y Adaptación del Estudiante:**
  Se verificó la exactitud de la explicación comparándola con el RFC 6376 (DKIM) y RFC 7489 (DMARC). Se incorporó al informe técnico una tabla explicativa para la defensa oral, destacando que una alteración de un solo espacio en el cuerpo del correo rompería el hash `bh=` invalidando la firma.

---

### Registro 2: Integración de Rspamd y ClamAV en Postfix (Nivel Estratégico)
- **Fecha y Hora:** 25/10/2026 04:52:30
- **Herramienta de IA:** Antigravity (DeepMind Advanced Coding Agent).
- **Prompt Enviado:**
  > *"Para la rúbrica de nivel Estratégico de Actividad 4 en Tecnología Web I, se exige investigar y diseñar la arquitectura de filtrado antispam y antivirus con Rspamd y ClamAV en Postfix. Propón el diagrama de flujo, las directivas milter en main.cf y el sistema de puntuación con símbolos y umbrales de rechazo."*
- **Respuesta de la IA:**
  La IA propuso un flujo mediante el socket `inet:localhost:11332`, detallando las directivas `smtpd_milters` y `non_smtpd_milters`, la integración de ClamAV a través de `clamd`, y un esquema de puntuación por símbolos (`R_SPF_ALLOW`, `R_DKIM_ALLOW`, `BAYES_SPAM`) con umbrales de 6.0 (marcar como spam) y 11.0 (rechazo en sesión SMTP).
- **Evaluación Crítica y Adaptación del Estudiante:**
  Se refinó la configuración para contemplar el comportamiento de Postfix ante fallos del milter (`milter_default_action = accept`), evitando que la caída temporal de Rspamd bloquee por completo el flujo de correos legítimos del colegio.

---

### Registro 3: Plan Estratégico de Migración desde Cuentas Gratuitas (Nivel Estratégico)
- **Fecha y Hora:** 25/10/2026 04:53:15
- **Herramienta de IA:** Antigravity (DeepMind Advanced Coding Agent).
- **Prompt Enviado:**
  > *"Diseña un plan de migración corporativo por fases para una escuela de 60 funcionarios que actualmente usa cuentas personales de Gmail/Hotmail hacia un servidor propio con Postfix y Dovecot. Incluye duración estimada, tareas técnicas con imapsync, período de convivencia y estrategia para evitar pérdida de correos."*
- **Respuesta de la IA:**
  La IA estructuró un plan en 6 fases a lo largo de 45 días: 1) Inventario y aprovisionamiento, 2) Publicación y registros DNS, 3) Capacitación y clientes de correo, 4) Migración histórica con `imapsync`, 5) Convivencia con reenvío y respuesta automática, y 6) Desconexión y corte definitivo.
- **Evaluación Crítica y Adaptación del Estudiante:**
  Se adaptaron los plazos a la realidad del calendario escolar cruceño, enfatizando la importancia de capacitaciones presenciales para docentes con menor familiaridad técnica y la distribución del certificado de la CA institucional para evitar advertencias de seguridad en Thunderbird y dispositivos Android/iOS.

---

## 3. Matriz de Síntesis del Aporte Humano vs. Aporte de IA

| Componente del Proyecto | Contribución de la Inteligencia Artificial | Validación, Ajuste y Ejecución por el Estudiante |
|---|---|---|
| **Configuración de Postfix y Dovecot** | Sugerencia de parámetros de cifrado TLS y sintaxis de directivas `submission` en `master.cf`. | Edición directa en los contenedores, prueba de autenticación SASL, verificación de relé cerrado y resolución de conflictos de puertos. |
| **Registros Criptográficos DNS** | Formulación de registros TXT para SPF, DKIM y DMARC con sintaxis estricta. | Creación de claves RSA 2048 en OpenDKIM, publicación en zonas BIND 9 autoritativas y validación con `dig`. |
| **Análisis de Cabeceras** | Interpretación de campos y estados de verificación en `Authentication-Results`. | Extracción física del correo en `/home/rosa.mamani/Maildir/cur/`, validación de huellas base64 y contrastación con el RFC 6376. |
| **Redacción de Informes y Presentación** | Estructuración inicial de plantillas en Markdown y scripts de compilación docx/pdf. | Verificación de citas APA 7, inclusión de capturas de pantalla reales y ajuste de estilo institucional Deep Navy. |

---

## 4. Reflexión sobre la IA en la Administración de Sistemas

El uso de Inteligencia Artificial en la administración de servidores de correo electrónico representa un multiplicador de productividad invaluable, especialmente para la depuración de configuraciones complejas y la comprensión profunda de especificaciones RFC extensas. No obstante, en el ámbito de la infraestructura crítica, la IA jamás puede reemplazar el criterio técnico humano: un parámetro de relé mal interpretado o una directiva DMARC laxa propuesta por un modelo de lenguaje puede exponer a una organización al secuestro de su reputación digital o a la inclusión en listas negras mundiales. La verdadera competencia profesional reside en saber interrogar al modelo, auditar matemáticamente cada respuesta y comprobarla experimentalmente en el laboratorio.


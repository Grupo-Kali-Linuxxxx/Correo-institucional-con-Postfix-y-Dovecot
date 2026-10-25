# Actividad 04: Correo Institucional Seguro (Postfix, Dovecot IMAPS, SPF, DKIM y DMARC)

**Universidad Privada Domingo Savio (UPDS)**  
**Facultad de Ingeniería — Carrera de Ingeniería de Sistemas (Sexto Semestre)**  
**Asignatura:** Tecnología Web I (SIS-0150)  
**Docente Titular:** M.Sc. Ing. Jimmy Nataniel Requena Llorentty  

### Equipo Estudiantil (Grupo):
1. **Ketfer Gianella Salazar**
2. **Charles Yourdan Conde**
3. **Brian Calás**
4. **Marco Barriga**
5. **Adaniel Balderrama Orellana**

**Sede:** Santa Cruz de la Sierra — Gestión II-2026  
**Repositorio Oficial:** `https://github.com/Grupo-Kali-Linuxxxx/Correo-institucional-con-Postfix-y-Dovecot`

---

## 🎯 Descripción y Alcance de la Actividad

El presente repositorio contiene la implementación práctica, justificaciones técnicas y evidencias de auditoría correspondientes a la **Actividad 04 (Correo Institucional con Postfix y Dovecot)** evaluada sobre los **Laboratorios 12 y 13**:

- **Laboratorio 12 (Servidor MTA Postfix, Maildir y DNS MX):** Configuración de Postfix 3.8 en el dominio institucional `horizonte.internal`, almacenamiento jerárquico Maildir (`cur/`, `new/`, `tmp/`), alias corporativos (`inscripciones -> secretaria, direccion`), pruebas de inyección con `swaks` y blindaje estricto contra relé abierto (`554 5.7.1 Relay access denied`). *(12 de 12 comprobaciones superadas - 100%)*.
- **Laboratorio 13 (Dovecot IMAPS 993, Submission 587 y Tríada Criptográfica DNS):** Clausura del puerto en claro 143 (`port = 0`), acceso exclusivo por IMAPS 993 con TLS implícito, servicio Submission 587 con STARTTLS forzado y autenticación SASL (`smtpd_tls_auth_only = yes`), control anti-suplantación (*anti-spoofing*) con tabla PCRE (código `553 5.7.1`), y publicación autoritativa en BIND 9 de la tríada criptográfica: SPF estricto (`v=spf1 mx -all`), firma DKIM RSA de 2048 bits (`mail._domainkey`) y política DMARC en modo cuarentena (`p=quarantine; adkim=s; aspf=s`). *(15 de 15 comprobaciones superadas - 100%)*.
- **Aportes de Nivel Estratégico (10/10 Puntos):**
  1. Análisis forense de cabeceras de correos reales entregados en buzones (`dkim=pass`, `bh=`, `ESMTPSA` vs `ESMTPS`).
  2. Investigación exhaustiva sobre las causas de clasificación en spam y su solución técnica.
  3. Arquitectura de filtrado antispam y antivirus en tiempo real mediante Postfix + Rspamd Milter + ClamAV.
  4. Política institucional de correo y plan estratégico de migración en 6 fases con `imapsync`.

---

## 📂 Estructura del Repositorio

```
Correo-institucional-con-Postfix-y-Dovecot/
├── 00_ENTREGABLES_PDF/                      # Entregables oficiales en formato PDF
│   ├── Actividad4_Informe_Tecnico_APA7.pdf  # Informe Técnico en formato APA v7 (10 páginas)
│   ├── Actividad4_Bitacora_IA_APA7.pdf      # Bitácora Metodológica de Inteligencia Artificial (3 págs)
│   ├── Actividad4_Presentacion.pdf          # Diapositivas de la presentación oral (12 slides)
│   ├── Actividad4_Guia_Defensa.pdf          # Guía de defensa con 9 preguntas orales y respuestas
│   ├── Lab12.pdf                            # Informe de Laboratorio 12
│   └── Lab13.pdf                            # Informe de Laboratorio 13
├── Actividad 4/                             # Documentación fuente de la actividad
│   ├── INFORME_TECNICO_APA7.md              # Fuente Markdown del informe técnico
│   ├── BITACORA_IA_APA7.md                  # Fuente Markdown de la bitácora IA
│   ├── GUIA_DEFENSA_Y_PREGUNTAS.md          # Banco de 9 preguntas técnicas de examen oral
│   ├── presentacion/index.html              # Presentación interactiva en HTML5/CSS3
│   └── evidencias/                          # 11 capturas de terminal auténticas
├── lab12/                                   # Scripts y configuraciones de Postfix y Maildir del Lab 12
└── lab13/                                   # Scripts, configuraciones de Dovecot, OpenDKIM y DMARC del Lab 13
```

---

## 📊 Resultados Oficiales de Auditoría

- **Laboratorio 12:** 12 / 12 verificaciones superadas (`bash /root/lab12/verificar_lab12.sh`).
- **Laboratorio 13:** 15 / 15 verificaciones superadas (`bash /root/lab13/verificar_lab13.sh`).
- **Nivel de Dominio Alcanzado:** Estratégico (10 / 10 Puntos).

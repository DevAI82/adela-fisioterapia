# 004 · Infraestructura (VPS Contabo + Coolify + Supabase)

| Campo | Valor |
|---|---|
| Estado | `borrador`: pendiente de aprobación de José Miguel |
| Módulo | Transversal |
| Prioridad | Alta: sin ella no se puede desplegar nada |
| Aprobada por | — |
| Fecha | 2026-10-14 |

## 1. Contexto y objetivo
Montar el servidor donde vivirán la web, el portal, el panel y la base de datos, siguiendo el stack aprobado en la spec 003 (D-016, D-019, D-020 y D-021).
Objetivo: un entorno de **staging** y otro de **producción** seguros, con copias diarias probadas y monitorización, listos para desplegar la app Astro + Vue.

## 2. Historias de usuario
- Como **José Miguel**, quiero desplegar con un `git push` y ver logs y estado desde Coolify, sin entrar por SSH en el día a día.
- Como **Adela**, quiero que mis datos y los de mis pacientes estén seguros, en Europa y con copia diaria.

## 3. Criterios de aceptación

### Servidor
- [ ] **CA-1:** VPS Contabo en **Francia (Lauterbourg)** con 8 GB de RAM o más, Ubuntu LTS actualizado.
- [ ] **CA-2:** Acceso SSH solo con clave (sin contraseña ni login de root), cortafuegos con solo 22, 80 y 443 abiertos, fail2ban y actualizaciones de seguridad automáticas.
- [ ] **CA-3:** Contrato de encargado del tratamiento (AVV/DPA) de Contabo firmado y guardado.

### Coolify y despliegue
- [ ] **CA-4:** Coolify instalado, con el panel en un subdominio con HTTPS y 2FA activado.
- [ ] **CA-5:** Dos entornos separados, **staging** y **producción**, cada uno con sus variables de entorno en Coolify (nunca en el repo).
- [ ] **CA-6:** Despliegue automático: un push a `main` despliega en staging; producción se despliega a mano desde Coolify.
- [ ] **CA-7:** HTTPS automático (Let's Encrypt) en todos los dominios.

### Supabase autoalojado
- [ ] **CA-8:** Supabase desplegado como servicio en Coolify (Postgres, Auth, Storage, REST, Realtime y Studio).
- [ ] **CA-9:** **Studio no es accesible públicamente**: protegido con autenticación y, si es posible, restringido por IP o túnel SSH.
- [ ] **CA-10:** Claves `JWT_SECRET`, `ANON_KEY` y `SERVICE_ROLE_KEY` generadas nuevas (no las de ejemplo) y guardadas solo en Coolify.
- [ ] **CA-11:** Auth configurado: email de Resend para confirmaciones, URL del sitio y redirecciones, y MFA (TOTP) disponible para la cuenta de Adela.

### Copias de seguridad (D-020)
- [ ] **CA-12:** Copia **diaria** de Postgres con la función de copias de Coolify, enviada a almacenamiento S3 **en la UE** (propuesta: bucket de Cloudflare R2 con jurisdicción UE, o Contabo Object Storage en la UE).
- [ ] **CA-13:** Copia **diaria** de los ficheros de Storage (informes adjuntos y audios personalizados), coherente con la de la base de datos.
- [ ] **CA-14:** Retención de 30 copias diarias como mínimo; la clave de cifrado de Coolify guardada aparte.
- [ ] **CA-15:** **Prueba de restauración** completa en staging, documentada en un runbook. Se repite cada mes.

### Analítica y monitorización
- [ ] **CA-16:** Umami desplegado en Coolify en un subdominio, sin cookies (D-021).
- [ ] **CA-17:** Monitorización de disponibilidad (por ejemplo Uptime Kuma en Coolify) con aviso por email si cae la web, el portal o Supabase.

## 4. Fuera de alcance
- El código de la app (specs de la fase 1) y el esquema de base de datos (spec 005).
- Configurar Stripe, Zernio y Google: cada integración tiene su spec.

## 5. Datos y privacidad
- Todo dato personal reside en el VPS de Francia o en las copias en la UE.
- **Cifrado:** HTTPS en tránsito; copias cifradas. Cifrado de disco: comprobar si el VPS de Contabo permite LUKS; si no, documentarlo como riesgo aceptado con las demás medidas.
- Acceso de administración: solo José Miguel, con 2FA en Coolify.

## 6. Diseño / UX
No aplica.

## 7. Plan técnico
1. Contratar el VPS y añadir la clave SSH; endurecer el servidor (usuario sin root, ufw, fail2ban, unattended-upgrades).
2. Instalar Coolify; configurar el dominio y el subdominio del panel; activar 2FA.
3. Crear los proyectos staging y producción; desplegar Supabase desde la plantilla de Coolify; generar claves nuevas.
4. Configurar el destino S3 y las copias diarias; probar la restauración en staging.
5. Desplegar Umami y Uptime Kuma.
6. Documentar todo en `docs/runbooks/` (alta del servidor, despliegue, restauración).

**Subdominios propuestos** (dominio pendiente): `www` (web), `app` o rutas `/portal` y `/panel` en el mismo dominio, `api` (Supabase), `staging`, `coolify` y `stats` (Umami).

**Riesgos:**
- Supabase consume mucha RAM → empezar con 8 GB y vigilar.
- La copia de Postgres de Coolify dentro del servicio Supabase hay que verificarla en la práctica (CA-15).
- Un único VPS es un punto único de fallo → las copias fuera del servidor permiten reconstruir en otro VPS.

## 8. Tareas
- [ ] T1 Contratar el VPS Contabo (Francia) y firmar el AVV — *José Miguel*
- [ ] T2 Registrar el dominio — *José Miguel / Adela*
- [ ] T3 Endurecer el servidor (CA-2)
- [ ] T4 Instalar y asegurar Coolify (CA-4 a CA-7)
- [ ] T5 Desplegar Supabase en staging y producción (CA-8 a CA-11)
- [ ] T6 Copias diarias y prueba de restauración (CA-12 a CA-15)
- [ ] T7 Umami y monitorización (CA-16, CA-17)
- [ ] T8 Runbooks en `docs/runbooks/`

## 9. Verificación
_(se rellena al terminar)_

## 10. Notas y decisiones
- Necesita de José Miguel: cuenta de Contabo, dominio y acceso SSH al VPS (o que ejecute los pasos guiados).

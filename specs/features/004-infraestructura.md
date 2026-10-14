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

**Topología (D-022, D-023):**
- **Coolify central en el VPS de José Miguel (Altera)**, con un *team* por cliente.
- **Staging** en el VPS de Altera, **solo con datos ficticios**. Se monta ya, antes de que Adela contrate.
- **Producción** en el VPS Contabo de Adela (titular: Adela), añadido como servidor remoto del Coolify central por SSH. En él corren la app, Supabase, Umami y el proxy; los datos nunca salen de ese VPS.
- **HetrixTools** monitoriza ambos VPS (agente en cada servidor).

## 2. Historias de usuario
- Como **José Miguel**, quiero desplegar con un `git push` y ver logs y estado desde Coolify, sin entrar por SSH en el día a día.
- Como **Adela**, quiero que mis datos y los de mis pacientes estén seguros, en Europa y con copia diaria.

## 3. Criterios de aceptación

### Servidor
- [ ] **CA-1:** Producción: VPS Contabo en **Francia (Lauterbourg)** a nombre de Adela, con 8 GB de RAM o más y Ubuntu LTS actualizado. Staging: VPS de Altera con recursos suficientes para Supabase (≈ 4 GB libres).
- [ ] **CA-2:** Acceso SSH solo con clave (sin contraseña ni login de root), cortafuegos con solo 22, 80 y 443 abiertos, fail2ban y actualizaciones de seguridad automáticas.
- [ ] **CA-3:** Contratos firmados: AVV/DPA de Contabo (Adela) y **contrato de encargado del tratamiento Adela ↔ Altera** (art. 28 RGPD), con confidencialidad y cláusula de reversibilidad.
- [ ] **CA-3b:** Acceso de Altera al VPS de Adela con **usuario propio con sudo y solo clave SSH**; nunca la contraseña de root ni la cuenta de Contabo de Adela.

### Coolify y despliegue
- [ ] **CA-4:** Coolify central (VPS de Altera) con HTTPS y 2FA, y un **team propio para Adela** que contiene su servidor, sus proyectos y sus variables.
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
- [ ] **CA-17:** **HetrixTools**: agente en ambos VPS (CPU, RAM, disco) y monitores de disponibilidad de la web, el portal y la API, con aviso por email.
- [ ] **CA-18:** **Runbook de salida** probado en staging: quitar el servidor de Coolify con "solo eliminar de Coolify" (nunca "Delete all resources") y comprobar que la app sigue funcionando.

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
**Ahora (sin el VPS de Adela):**
1. En el Coolify del VPS de Altera: crear el team "Fisioterapia Online con Adela" y el proyecto de staging.
2. Desplegar Supabase y Umami en staging con datos ficticios; generar claves nuevas.
3. Configurar las copias diarias y hacer la prueba de restauración en staging.
4. Agente de HetrixTools en el VPS de Altera.

**Cuando Adela contrate su VPS:**
5. Endurecer el servidor; crear el usuario de Altera con sudo y clave SSH.
6. Añadirlo como servidor remoto en el team de Adela (Coolify instala Docker y el proxy).
7. Desplegar producción (Supabase, app y Umami) siguiendo el runbook probado en staging; configurar las copias diarias; agente de HetrixTools.
8. Documentar en `docs/runbooks/`: alta de servidor, despliegue, restauración y **salida**.

**Subdominios propuestos** (dominio pendiente; staging usa un subdominio del dominio de Altera): `www` (web), `app` o rutas `/portal` y `/panel` en el mismo dominio, `api` (Supabase), `staging`, `coolify` y `stats` (Umami).

**Riesgos:**
- Supabase consume mucha RAM → empezar con 8 GB y vigilar.
- La copia de Postgres de Coolify dentro del servicio Supabase hay que verificarla en la práctica (CA-15).
- Un único VPS es un punto único de fallo → las copias fuera del servidor permiten reconstruir en otro VPS.
- El Coolify central guarda las claves de todos los clientes → 2FA, copias propias de Coolify (incluida su clave de cifrado) y acceso solo de José Miguel. Si cae, las apps de los clientes siguen funcionando; solo se pierde la capacidad de desplegar.

**Plan de salida (reversibilidad):**
1. Entregar al cliente: acceso o transferencia del repositorio, runbooks, última copia y lista de variables por canal seguro.
2. El nuevo responsable instala su propio Coolify en el VPS o gestiona Docker directamente, y redespliega desde Git.
3. Quitar el servidor del Coolify central con **"solo eliminar de Coolify"**; borrar el usuario y la clave SSH de Altera; desinstalar el agente de HetrixTools.
4. El cliente **rota todas las claves** (Supabase, Stripe, Resend, Zernio, Google, R2), porque Altera las tuvo.

## 8. Tareas
- [ ] T0 Montar staging en el VPS de Altera con datos ficticios (puede empezar ya)
- [ ] T1 Adela contrata el VPS Contabo (Francia) y firma el AVV; Altera y Adela firman el contrato de encargado del tratamiento
- [ ] T2 Registrar el dominio — *José Miguel / Adela*
- [ ] T3 Endurecer el servidor (CA-2)
- [ ] T4 Instalar y asegurar Coolify (CA-4 a CA-7)
- [ ] T5 Desplegar Supabase en staging y producción (CA-8 a CA-11)
- [ ] T6 Copias diarias y prueba de restauración (CA-12 a CA-15)
- [ ] T7 Umami y monitorización (CA-16, CA-17)
- [ ] T8 Runbooks en `docs/runbooks/` (incluido el de salida, CA-18)

## 9. Verificación
_(se rellena al terminar)_

## 10. Notas y decisiones
- 14/10/2026: José Miguel decide staging en su VPS y Coolify central (opción B) (D-022, D-023). El VPS de producción lo contrata Adela.
- Para ejecutar los pasos hace falta acceso al Coolify y al VPS de Altera, o que José Miguel los ejecute guiado.

# 005 · Modelo de datos y seguridad (Supabase + RLS)

| Campo | Valor |
|---|---|
| Estado | `en curso`: esquema, RLS y tests hechos; quedan CA-13 a CA-16 (dependen de la app y de staging) |
| Módulo | Transversal (base de M2, M3, M5, M6 y M8) |
| Prioridad | Alta: es la base de todas las funcionalidades y de la privacidad |
| Aprobada por | José Miguel (14/10/2026) |
| Fecha | 2026-10-14 |

## 1. Contexto y objetivo
Definir el esquema de base de datos, los permisos (RLS) y el almacenamiento de ficheros que necesitan el historial del paciente, la biblioteca, las rutinas, el mini cuestionario, la agenda y los pagos (brief §7, prototipo v2).
La privacidad de los datos de salud depende de esta spec: **las reglas de acceso viven en la base de datos, no solo en la interfaz.**

## 2. Historias de usuario
- Como **paciente**, quiero ver solo mis datos y que nadie más pueda verlos.
- Como **Adela**, quiero ver todo de mis pacientes, y que mis notas privadas no las vea nunca el paciente.
- Como **José Miguel**, quiero que el esquema esté versionado y probado para poder evolucionarlo sin miedo.

## 3. Criterios de aceptación

### Esquema
- [x] **CA-1:** Todas las tablas de `01-stack.md §3` creadas mediante migraciones SQL versionadas en `supabase/migrations/`.
- [x] **CA-2:** Las notas de consulta se guardan en **dos tablas**: `consult_notes` (resumen visible para el paciente) y `consult_notes_private` (solo la fisio) (D-014).
- [x] **CA-3:** El mini cuestionario (`session_feedback`) guarda rigidez (`elevada`, `moderada`, `ligera`, `ninguna`), EVA (0–10), estabilidad (`alta`, `media`, `baja`), comentario y respuesta de la fisio, con restricciones `CHECK`.
- [x] **CA-4:** Las rutinas guardan por ejercicio: vídeo, voz en off (opcional), series, repeticiones, frecuencia, duración y nota.
- [x] **CA-5:** Las tablas clínicas **no se borran en cascada** (`ON DELETE RESTRICT`); el paciente se da de baja con borrado lógico (conservación ≥ 5 años, Ley 41/2002).

### Permisos (RLS)
- [x] **CA-6:** RLS **activado en todas las tablas**, sin excepciones.
- [x] **CA-7:** Rol de la fisio comprobado con una función `is_fisio()` basada en `profiles.role`; el rol no se puede modificar desde el cliente.
- [x] **CA-8:** Un paciente solo lee **sus** filas en cuestionarios, adjuntos, rutinas, sesiones, citas, pagos y resúmenes de consulta.
- [x] **CA-9:** `consult_notes_private` y `audit_log` **no son accesibles** para ningún paciente ni para usuarios anónimos.
- [x] **CA-10:** `payments` solo se escribe desde el servidor (webhook de Stripe con la clave de servicio); el cliente no puede crear ni modificar pagos.
- [x] **CA-11:** Los consentimientos solo se insertan (nunca se modifican ni se borran) y guardan la versión del texto aceptado.

### Ficheros
- [x] **CA-12:** Buckets **privados** `attachments` (informes médicos) y `personal-voices` (audios para un paciente), con rutas `paciente_id/…` y políticas de Storage equivalentes a la RLS.
- [ ] **CA-13:** Descargas solo mediante **URL firmada de corta duración** (≤ 5 min para informes médicos).
- [ ] **CA-14:** Los vídeos y voces genéricos de R2 se sirven con URL firmada generada en el servidor, y solo para pacientes con una rutina activa que los incluya.

### Seguridad de la cuenta y trazabilidad
- [ ] **CA-15:** La cuenta de Adela exige **MFA (TOTP)** para entrar al panel.
- [ ] **CA-16:** Los accesos a datos clínicos desde el panel (ver ficha, abrir un informe) quedan en `audit_log` (quién, qué, cuándo).

### Tests
- [x] **CA-17:** Tests automáticos de RLS en `supabase/tests/` que se ejecutan en CI. Como mínimo:
  - un paciente A no puede leer nada del paciente B;
  - un paciente no puede leer `consult_notes_private`;
  - un usuario anónimo no lee ningún dato clínico;
  - un paciente no puede insertar pagos ni cambiar su rol;
  - la fisio lee todo.
- [x] **CA-18:** Datos de prueba ficticios (`supabase/seed.sql`) con los pacientes del prototipo; **nunca datos reales**.

## 4. Fuera de alcance
- Las pantallas que usan estos datos (specs de la fase 1).
- Integraciones (Stripe, Zernio, Google): cada una en su spec. Esta spec solo deja preparadas sus tablas.

## 5. Datos y privacidad
Esta spec es la implementación técnica del brief §8. Datos de salud: `questionnaires`, `attachments`, `consult_notes*`, `routines`, `session_feedback` y `messages`. Todos con RLS, y sus ficheros en buckets privados en el VPS.

## 6. Diseño / UX
No aplica.

## 7. Plan técnico
- **Herramientas:** CLI de Supabase para migraciones y para levantar un Supabase local en CI; tests de RLS con pgTAP (`supabase test db`).
- **Tablas** (resumen; el detalle de columnas se fija en la primera migración):
  `profiles`, `patients`, `consents`, `questionnaires`, `attachments`, `consult_notes`, `consult_notes_private`, `library_videos`, `library_voices`, `routines`, `routine_items`, `session_feedback`, `appointments`, `availability`, `payments`, `payment_links`, `messages`, `audit_log`.
- **Relaciones clave:** `patients.profile_id → profiles`; casi todo cuelga de `patient_id`; `routine_items → library_videos / library_voices`; `session_feedback → routines`.
- **Funciones:** `is_fisio()`, `current_patient_id()`; trigger que impide cambiar `profiles.role`.
- **Riesgo:** una política RLS mal escrita expone datos de salud. Por eso CA-17 es obligatorio y bloquea cualquier merge.

## 8. Tareas
- [x] T1 Inicializar `supabase/` con la CLI
- [x] T2 Migración 001: perfiles, pacientes, consentimientos y funciones de rol
- [x] T3 Migración 002: cuestionarios, adjuntos y notas (pública y privada)
- [x] T4 Migración 003: biblioteca, rutinas y mini cuestionario
- [x] T5 Migración 004: agenda, disponibilidad, pagos y enlaces de pago
- [x] T6 Migración 005: mensajes y `audit_log`
- [x] T7 Buckets privados y políticas de Storage
- [x] T8 Tests de RLS y `seed.sql` ficticio; integración en CI

## 9. Verificación
14/10/2026 · `scripts/db/test-local.sh` sobre `supabase/postgres:17.6.1.064`: las 5 migraciones y el seed se aplican sin errores y **36/36 tests de privacidad pasan**.
- **Prueba de control:** se abrió a propósito un agujero (notas privadas visibles y `TRUNCATE` permitido) y los tests 4 y 17 fallaron, como debían.
- **CI:** `.github/workflows/tests-privacidad.yml` ejecuta el mismo script en cada cambio de `supabase/`.

Pendiente para cerrar la spec:
- **CA-13 y CA-14** (URLs firmadas de informes y vídeos): se implementan en el servidor de la app (spec de la fase 1); la base de datos ya lo soporta (`in_my_active_routine`, buckets privados).
- **CA-15** (MFA de Adela): se activa en la configuración de Auth al montar staging (spec 004) y se exige en el panel.
- **CA-16** (registro de accesos): la tabla y sus permisos están listos; las escrituras las hará el panel.
- Validar la migración 005 contra **Supabase real** en staging, con storage-api: aquí se usó un sustituto mínimo de las tablas de Storage.

## 10. Notas y decisiones
- Se puede desarrollar y probar en local (Supabase CLI) **antes** de tener el VPS: no depende de la spec 004.
- 14/10/2026: `supabase start` no funcionó en el entorno de desarrollo (ECR bloqueado y límite de descargas de Docker Hub). Los tests se ejecutan con un Postgres de Supabase desechable (`scripts/db/test-local.sh`), también en CI.
- Endurecimientos añadidos al implementar:
    - Se retira `TRUNCATE` a anon y authenticated: Supabase lo concede por defecto y RLS no lo protege.
    - Anon sin acceso a ninguna tabla salvo `availability`.
    - **Nadie, tampoco la fisio, puede borrar historia clínica desde el cliente.**
    - El solapamiento de citas (con los 15 min de descanso) y "Bizum solo en pagos únicos" se garantizan en la propia base de datos.

# Runbook 01 · Montar staging en el Coolify de Altera

> Spec 004 · tarea T0. Entorno de pruebas **solo con datos ficticios** (D-022).
> Tiempo estimado: 1–2 horas. Lo ejecuta José Miguel (o Claude con acceso SSH).
> Los nombres de menús de Coolify pueden variar ligeramente según la versión.

## 0. Requisitos

- [ ] Coolify v4 funcionando en el VPS de Altera, con **2FA activado** en tu cuenta.
- [ ] Al menos **4 GB de RAM libres** en el VPS (Supabase levanta unos 10 contenedores). Compruébalo con `free -h`.
- [ ] Dos subdominios de **tu** dominio apuntando (registro A) a la IP del VPS, por ejemplo:
  - `api-adela-staging.<tu-dominio>` → API de Supabase
  - `stats-adela-staging.<tu-dominio>` → Umami
- [ ] Una cuenta de Resend (plan gratuito) con tu dominio verificado, para los emails de prueba.

## 1. Team y proyecto

1. **Teams → New team:** `Fisioterapia Online con Adela`. Todo lo de este cliente va aquí (D-023).
2. Dentro del team: **Projects → New:** `adela-fisio`, con el entorno `staging`.

## 2. Supabase

1. En el entorno `staging`: **+ New → Service → Supabase**.
2. **Dominios:** asigna `https://api-adela-staging.<tu-dominio>` al servicio **Kong** (es la puerta de entrada de la API).
3. **Variables:** revisa que Coolify haya generado valores aleatorios en todas las claves (`SERVICE_PASSWORD_*`, `SERVICE_SUPABASEANON_KEY`, `SERVICE_SUPABASESERVICE_KEY`, JWT). **No uses claves de ejemplo.**
4. **Studio** (el panel de administración): debe quedar protegido con usuario y contraseña fuertes (variables `DASHBOARD_USERNAME` / `DASHBOARD_PASSWORD`). Si puedes, no le asignes dominio público y entra por túnel SSH.
5. **Auth** (contenedor `supabase-auth`), variables:
   - `GOTRUE_SITE_URL` = URL de la web de staging (por ahora puede ser la del prototipo).
   - SMTP con Resend: `GOTRUE_SMTP_HOST=smtp.resend.com`, `GOTRUE_SMTP_PORT=465`, `GOTRUE_SMTP_USER=resend`, `GOTRUE_SMTP_PASS=<API key de Resend>`, `GOTRUE_SMTP_ADMIN_EMAIL=no-reply@<tu-dominio>`.
   - MFA para la cuenta de la fisio (spec 005 · CA-15): `GOTRUE_MFA_TOTP_ENROLL_ENABLED=true` y `GOTRUE_MFA_TOTP_VERIFY_ENABLED=true`.
6. **Deploy** y espera a que todos los contenedores estén en verde.

## 3. Migraciones, datos ficticios y tests de privacidad

Desde el VPS (por SSH), con el repositorio clonado:

```bash
git clone https://github.com/DevAI82/adela-fisioterapia.git && cd adela-fisioterapia
DB=$(docker ps --format '{{.Names}}' | grep -m1 'supabase-db')    # contenedor de Postgres del servicio
for f in supabase/migrations/*.sql; do
  echo "→ $f"; docker exec -i "$DB" psql -U postgres -v ON_ERROR_STOP=1 < "$f" || break
done
docker exec -i "$DB" psql -U postgres -v ON_ERROR_STOP=1 < supabase/seed.sql
# Tests de privacidad contra Supabase REAL (se ejecutan en una transacción y no dejan rastro)
docker exec -i "$DB" psql -U postgres -X -t -A -v ON_ERROR_STOP=1 < supabase/tests/rls_privacidad_test.sql | grep -E '^(ok|not ok)'
```

- [ ] Las 5 migraciones se aplican sin errores (la 005 crea los buckets en el Storage real).
- [ ] **Los 36 tests salen `ok`.** Si alguno sale `not ok`, para y avísame: es un fallo de privacidad.

## 4. Copias de seguridad diarias (D-020)

1. **Settings → S3 Storages → Add:** un bucket **en la UE**, privado y exclusivo para copias. Opciones:
   - Cloudflare R2 con jurisdicción UE (aprovechas la cuenta de los vídeos).
   - Contabo Object Storage en la UE.
2. En la base de datos del servicio Supabase → **Backups:**
   - frecuencia diaria (`0 3 * * *`, a las 3:00);
   - destino: el S3 anterior;
   - retención: 30 copias.
3. **Ficheros de Storage:** configura también la copia del volumen de Storage, con la copia de volúmenes de Coolify si tu versión la tiene; si no, lo resolvemos con un cron y `rclone`.
4. Guarda **fuera de Coolify** su clave de cifrado (`APP_KEY` del `.env` de Coolify) en tu gestor de contraseñas.
5. **Prueba de restauración:** restaura la copia en una base de datos nueva y comprueba que el seed ficticio está entero. Anota fecha y resultado al final de este runbook.

## 5. Umami (analítica sin cookies, D-021)

1. En el entorno `staging`: **+ New → Service → Umami**, con el dominio `https://stats-adela-staging.<tu-dominio>`.
2. Entra, **cambia la contraseña por defecto** (`admin` / `umami`) y crea el sitio "Fisioterapia Online con Adela (staging)".
3. Copia el *Website ID* para `PUBLIC_UMAMI_WEBSITE_ID`.

## 6. Monitorización (HetrixTools)

- [ ] Agente de HetrixTools instalado en el VPS de Altera (si no lo tenías ya).
- [ ] Monitores de disponibilidad para `api-adela-staging` y `stats-adela-staging`, con aviso por email.

## 7. Cierre

- [ ] Rellena el registro de abajo.
- [ ] Avísame para actualizar `MEMORY.md` y marcar la tarea T0 de la spec 004.

### Registro de ejecución

| Fecha | Paso | Resultado | Notas |
|---|---|---|---|
| | | | |

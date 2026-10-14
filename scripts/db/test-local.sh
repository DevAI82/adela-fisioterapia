#!/usr/bin/env bash
# Prueba las migraciones y las políticas RLS en un Postgres de Supabase desechable (Docker),
# sin levantar todo el stack. Útil en local o cuando `supabase start` no está disponible.
#
#   scripts/db/test-local.sh            # crea el contenedor, migra, siembra y ejecuta los tests
#   KEEP=1 scripts/db/test-local.sh     # deja el contenedor levantado para inspeccionarlo
#
# En CI se usa el stack completo: `supabase start` + `supabase test db` (ver .github/workflows).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
IMAGE="${PG_IMAGE:-supabase/postgres:17.6.1.064}"
NAME="${PG_CONTAINER:-fisio-db-test}"
PORT="${PG_PORT:-54329}"
export PGHOST=localhost PGPORT="$PORT" PGUSER=postgres PGPASSWORD=postgres PGDATABASE=postgres

docker rm -f "$NAME" >/dev/null 2>&1 || true
docker run -d --name "$NAME" -e POSTGRES_PASSWORD=postgres -p "$PORT:5432" "$IMAGE" >/dev/null
[ "${KEEP:-0}" = "1" ] || trap 'docker rm -f "$NAME" >/dev/null 2>&1' EXIT

echo "→ Esperando a Postgres ($IMAGE)…"
for _ in $(seq 1 60); do psql -tAc "select 1" >/dev/null 2>&1 && break; sleep 1; done
sleep 2

run() { psql -q -v ON_ERROR_STOP=1 -f "$1" >/dev/null; }

# Las tablas de Storage las crea storage-api (no presente aquí): se imitan como supabase_admin.
PGUSER=supabase_admin run "$ROOT/scripts/db/local-storage-stub.sql"
for f in "$ROOT"/supabase/migrations/*.sql; do
  echo "→ Migración $(basename "$f")"
  run "$f"
done
echo "→ Seed ficticio"
run "$ROOT/supabase/seed.sql"

status=0
for t in "$ROOT"/supabase/tests/*.sql; do
  echo "→ Tests $(basename "$t")"
  out="$(psql -X -t -A -v ON_ERROR_STOP=1 -f "$t" 2>&1)" || status=1
  echo "$out" | grep -E '^(ok|not ok|1\.\.|#)' || true
  if echo "$out" | grep -qE '^not ok|ERROR'; then status=1; echo "$out" | grep -E 'ERROR' || true; fi
done
[ $status -eq 0 ] && echo "✅ Todos los tests de privacidad pasan" || echo "❌ Hay tests que fallan"
exit $status

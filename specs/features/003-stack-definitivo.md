# 003 · Stack definitivo

| Campo | Valor |
|---|---|
| Estado | `borrador`: **pendiente de aprobación de José Miguel** |
| Módulo | Transversal (infraestructura y arquitectura) |
| Prioridad | Alta: bloquea las specs 004 (infraestructura) y 005 (modelo de datos) |
| Aprobada por | — |
| Fecha | 2026-10-14 |

## 1. Contexto y objetivo
Cerrar las piezas del stack que siguen abiertas en `01-stack.md`, para empezar a construir la aplicación real.
Ya están decididos: VPS en Francia con Coolify y Supabase autoalojado (D-010), Stripe (D-009), WhatsApp vía Zernio (D-011) y Cloudflare R2 para los vídeos genéricos (D-012).

## 2. Propuesta (cada fila necesita ✅, 🔄 o ❌)

| Decisión | Propuesta | Por qué | Alternativa | ¿Aprobada? |
|---|---|---|---|---|
| Frontend | **Next.js (App Router) + Tailwind + `@supabase/ssr`**, una sola aplicación para web, portal y panel | Renderizado en servidor para el SEO de la web pública, autenticación con cookies seguras, gran ecosistema; se despliega como contenedor en Coolify | SvelteKit (más ligero, ecosistema menor) o Astro para la web pública + app aparte | ❓ |
| Proveedor del VPS | **OVHcloud** o **Scaleway** (centros de datos en Francia), con ≥ 8 GB de RAM | Supabase autoalojado levanta varios contenedores (Postgres, Auth, Storage, Realtime, Studio…); 8 GB dan margen junto a la app y la analítica | Hetzner (más barato, pero sin centro de datos en Francia) | ❓ |
| Videollamada | **Google Meet** creado desde la API de Google Calendar, con **Google Workspace** (Business Starter) | Adela necesita cuenta de Google de todas formas; Workspace incluye email profesional con su dominio, Calendar, Meet y contrato de encargado del tratamiento | Jitsi autoalojado (más trabajo de mantenimiento) o un servicio de vídeo embebido de pago | ❓ |
| Email transaccional | Servicio con **servidores en la UE** (por ejemplo Brevo) o el SMTP de Google Workspace para el volumen inicial | Confirmaciones, recordatorios y justificantes; volumen bajo | Resend (verificar la opción de región UE) | ❓ |
| Copias de seguridad | `pg_dump` diario cifrado + snapshot semanal del VPS, en almacenamiento de objetos en la UE; restauración probada cada mes | Exigencia RGPD y Ley 41/2002 | Backups gestionados del proveedor | ❓ |
| Analítica web | **Umami** autoalojado en Coolify (sin cookies) | No requiere banner de cookies para analítica | Plausible | ❓ |
| Facturación | Fuera del CRM en la fase 1: el CRM registra los pagos de Stripe y la gestoría emite las facturas | Evita VeriFactu en el MVP | Software de facturación homologado conectado por API | ❓ |
| Calidad | GitHub Actions: lint, typecheck, tests (Vitest y Playwright) y pruebas de RLS contra un Supabase local | Las políticas RLS son la principal garantía de privacidad: deben tener tests | — | ❓ |

## 3. Arquitectura resultante

```
                         Coolify en VPS (Francia)
 ┌─────────────────────────────────────────────────────────────────┐
 │  App Next.js  (web pública · portal paciente · panel de Adela)  │
 │        │  @supabase/ssr (sesión con cookies, RLS)               │
 │  Supabase: Postgres · Auth · Storage privado · Edge Functions   │
 │  Umami (analítica sin cookies)                                  │
 └──────┬──────────────┬───────────────┬──────────────┬────────────┘
        │              │               │              │
   Stripe (pagos)  Zernio (WhatsApp)  Google Workspace  Cloudflare R2
   webhooks        webhooks          Calendar + Meet   vídeos genéricos
                                     + email           (URLs firmadas)
 Copias cifradas diarias → almacenamiento de objetos en la UE
```

## 4. Criterios de aceptación
- [ ] **CA-1:** Cada fila de §2 tiene una decisión (✅, 🔄 con la alternativa elegida, o ❌).
- [ ] **CA-2:** Todos los proveedores con datos personales están en la UE o tienen contrato de encargado del tratamiento.
- [ ] **CA-3:** `01-stack.md` refleja lo decidido; `.env.example` tiene solo las variables necesarias.
- [ ] **CA-4:** `AGENTS.md §3` incluye la estructura de carpetas de la aplicación.
- [ ] **CA-5:** Las decisiones quedan registradas en `MEMORY.md`.

## 5. Fuera de alcance
Instalar o contratar nada: eso es la spec 004 (infraestructura).

## 6. Coste orientativo mensual (a confirmar con precios actuales)
VPS de 8 GB en Francia, Google Workspace Business Starter (1 usuario), dominio, Stripe (comisión por cobro), Zernio (plan gratuito) y R2 (gratis hasta 10 GB). Lo detallaremos con precios reales al aprobar la spec.

## 7. Plan técnico
Una vez aprobada:
1. Actualizar `01-stack.md`, `.env.example` y `AGENTS.md §3`.
2. Escribir la spec 004 (infraestructura) y la 005 (modelo de datos y seguridad).

## 8. Tareas
- [ ] T1 Revisión con José Miguel fila a fila.
- [ ] T2 Actualizar la documentación (CA-3, CA-4 y CA-5).

## 9. Verificación
_(se rellena al aprobar)_

## 10. Notas y decisiones
- 2026-10-14: propuesta extraída de `01-stack.md §7` a esta spec, a petición de José Miguel.

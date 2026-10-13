# 01 · Stack tecnológico y arquitectura

| Campo | Valor |
|---|---|
| Estado | `borrador`: **pendiente de revisar con José Miguel** |
| Fuente | Dossier inicial ("despliegue del VPS y Supabase") y demo |
| Última actualización | 2026-10-13 |

> ⚠️ Este borrador refleja lo que se planteó en la propuesta. Cada fila tiene una columna
> **Decisión** para dejarla en ✅ (confirmada), 🔄 (cambia) o ❌ (se descarta) en la revisión.

---

## 1. Componentes

| Capa | Propuesta inicial | Alternativas a valorar | Decisión |
|---|---|---|---|
| Frontend web y portal | ❓ (el prototipo es un HTML con Tailwind por CDN) | Astro, Next.js, SvelteKit, React + Vite | ❓ |
| Estilos | Tailwind CSS (con build, no CDN) | — | ❓ |
| Backend / BBDD / Auth | **Supabase** (Postgres + Auth + RLS + Storage + Edge Functions) | Supabase autoalojado en VPS | ✅ **Supabase autoalojado con Coolify** (D-010) |
| Hosting | **VPS** | Vercel / Netlify (frontend) + Supabase Cloud (región UE) | ✅ **VPS en Francia + Coolify** (D-010). Proveedor ❓ (OVHcloud, Scaleway…) |
| Vídeos y voces genéricos | Supabase Storage | Cloudflare R2, Cloudflare Stream, Bunny Stream, Vimeo, YouTube oculto | 🔄 **Cloudflare R2** con enlaces firmados (D-012). Stream solo si hace falta streaming adaptativo |
| Audios personalizados y adjuntos médicos | — | — | ✅ **Supabase Storage privado en el VPS** (datos de salud, D-012) |
| Mensajería omnicanal | **Zernio** (WhatsApp + Instagram) | WhatsApp Cloud API directa | ✅ **Zernio**, plan gratuito (2 redes), solo WhatsApp (D-011) |
| Telefonía | Línea móvil de la clínica con desvío incondicional a un mensaje fijo (operador pendiente) | Centralita virtual "mensaje y colgar" | ✅ Mensaje fijo, sin IA (D-006). Operador ❓ |
| Voz IA | ~~ElevenLabs Conversational AI ("Sofía")~~ | — | ❌ Fuera por ahora (D-006) |
| Agenda y videoconsulta | **Google Calendar + Google Meet** | Cal.com + Meet/Jitsi | ❓ |
| Email transaccional | Resend | Brevo, SMTP de Google Workspace | ❓ |
| Pagos | ❓ | Stripe (suscripciones), Bizum vía TPV | ✅ **Stripe**: Bizum y tarjeta en pagos únicos; tarjeta en suscripciones (D-009) |
| Analítica web | ❓ | Plausible / Umami (sin cookies) | ❓ |
| Repositorio y CI | GitHub (`DevAI82/adela-fisioterapia`) + GitHub Actions | — | ❓ |

## 2. Arquitectura (borrador)

```
   Paciente (web/móvil)          Adela (panel)              Canales externos
          │                           │                 WhatsApp · Instagram · Email
          │                           │            (Teléfono → mensaje fijo → WhatsApp/web)
          ▼                           ▼                         │
   ┌─────────────────────────────────────────┐          ┌──────┴──────┐
   │  Frontend (web pública + portal + CRM)  │          │ Zernio/Email │
   └───────────────────┬─────────────────────┘          └──────┬──────┘
                       │  supabase-js (anon key + RLS)          │ webhooks
                       ▼                                        ▼
   ┌─────────────────────────────────────────────────────────────────┐
   │ Supabase (UE): Postgres + Auth + Storage + Edge Functions       │
   │   RLS: paciente ve solo lo suyo · notas clínicas solo Adela     │
   └───────────────────────────┬─────────────────────────────────────┘
                               ▼
                 Google Calendar/Meet · Email · Pagos
```

## 3. Modelo de datos inicial (borrador, alineado con el prototipo v2)

| Tabla | Contenido | Acceso (RLS) |
|---|---|---|
| `profiles` | Usuario: rol `fisio` / `paciente`, datos de contacto | Cada uno el suyo; la fisio, todos |
| `patients` | Ficha: tipo de problema, diagnóstico, estado, plan activo | Paciente (la suya) y fisio |
| `consents` | Consentimientos con fecha, versión del texto, IP y tipo (salud, documentos, WhatsApp) | Solo inserción; lectura por la fisio |
| `questionnaires` | Respuestas del cuestionario inicial y comentarios | Paciente (las suyas) y fisio |
| `attachments` | Metadatos de informes médicos; el fichero va en un bucket privado | Paciente (los suyos) y fisio; descarga con URL firmada |
| `consult_notes` | Nota de cada consulta: `private_notes` (solo fisio) y `patient_summary` | `private_notes` **solo la fisio** (vista o columna separada) |
| `library_videos` / `library_voices` | Biblioteca: título, etiquetas, duración, ubicación (R2 o bucket privado), paciente si es una voz personalizada | Fisio; el paciente solo los de su rutina |
| `routines` / `routine_items` | Rutina y ejercicios: vídeo, voz, series, repeticiones, frecuencia, duración, nota | Paciente (las suyas) y fisio |
| `session_feedback` | Mini cuestionario de cada sesión: rigidez, EVA, estabilidad, comentario y respuesta de la fisio | Paciente (los suyos) y fisio |
| `appointments` | Citas: tipo, duración, estado (confirmada, no presentado, reagendada), enlace de videollamada | Paciente (las suyas) y fisio |
| `availability` | Franjas de consulta y descanso entre citas | Lectura pública; escritura de la fisio |
| `payments` / `payment_links` | Pagos y enlaces de Stripe (ids, importe, método, estado) | Paciente (los suyos) y fisio; escritura solo desde webhooks |
| `messages` | WhatsApp (Zernio) y mensajes del portal | Fisio; el paciente solo los del portal |
| `audit_log` | Accesos a datos clínicos (quién, qué, cuándo) | Solo inserción; lectura de la fisio |

## 4. Requisitos no funcionales

- **Ubicación de datos:** UE. Supabase autoalojado en un VPS en Francia; vídeos genéricos en Cloudflare R2 (no son datos personales).
- **Seguridad:** RLS en todas las tablas, 2FA para la cuenta de Adela, disco cifrado y copias de seguridad diarias cifradas fuera del VPS (también en la UE).
- **Rendimiento:** web pública con Lighthouse ≥ 90 en móvil.
- **Accesibilidad:** WCAG 2.1 AA.
- **Entornos:** `local` → `staging` → `producción`, cada uno con su `.env`.

## 5. Variables de entorno

Ver [`.env.example`](../.env.example). Se ajusta cuando este documento quede aprobado.

## 6. Preguntas abiertas

1. ~~¿VPS propio o servicios gestionados?~~ → VPS en Francia con Coolify (D-010). Falta elegir proveedor.
2. ¿Qué framework de frontend usamos? → ver la propuesta de §7.
3. ~~¿Zernio o la API oficial de WhatsApp?~~ → Zernio (D-011). Pendiente: compatibilidad con la app de WhatsApp Business en el mismo número (spec 001 §7).
4. ¿Operador de la línea móvil? (pendiente de alta)
5. ~~¿Pasarela de pago?~~ → Stripe (D-009).
6. ¿El prototipo de GitHub Pages se mantiene como demo o lo sustituye la web real?

## 7. Propuesta para cerrar el stack (borrador para la spec 003, **no aprobada**)

Redactada por el agente el 13/10/2026 para agilizar la revisión. Cada punto necesita el ✅ de José Miguel.

| Decisión | Propuesta | Por qué | Alternativa |
|---|---|---|---|
| Frontend | **Next.js (App Router) + Tailwind + `@supabase/ssr`**, una sola aplicación para web, portal y panel | Renderizado en servidor para el SEO de la web pública, autenticación con cookies seguras, gran ecosistema; se despliega como contenedor en Coolify | SvelteKit (más ligero, ecosistema menor) o Astro para la web pública + app aparte |
| Proveedor del VPS | **OVHcloud** o **Scaleway** (centros de datos en Francia), con ≥ 8 GB de RAM | Supabase autoalojado levanta varios contenedores (Postgres, Auth, Storage, Realtime, Studio…); 8 GB dan margen junto a la app y la analítica | Hetzner (más barato, pero sin centro de datos en Francia) |
| Videollamada | **Google Meet** creado desde la API de Google Calendar, con **Google Workspace** (Business Starter) | Adela necesita cuenta de Google de todas formas; Workspace incluye email profesional con su dominio, Calendar, Meet y contrato de encargado del tratamiento | Jitsi autoalojado (más trabajo de mantenimiento) o un servicio de vídeo embebido de pago |
| Email transaccional | Servicio con **servidores en la UE** (por ejemplo Brevo) o el SMTP de Google Workspace para el volumen inicial | Confirmaciones, recordatorios y justificantes; volumen bajo | Resend (verificar la opción de región UE) |
| Copias de seguridad | `pg_dump` diario cifrado + snapshot semanal del VPS, en almacenamiento de objetos en la UE; restauración probada cada mes | Exigencia RGPD y Ley 41/2002 | Backups gestionados del proveedor |
| Analítica web | **Umami** autoalojado en Coolify (sin cookies) | No requiere banner de cookies para analítica | Plausible |
| Facturación | Fuera del CRM en la fase 1: el CRM registra los pagos de Stripe y la gestoría emite las facturas | Evita VeriFactu en el MVP | Software de facturación homologado conectado por API |
| Calidad | GitHub Actions: lint, typecheck, tests (Vitest y Playwright) y pruebas de RLS contra un Supabase local | Las políticas RLS son la principal garantía de privacidad: deben tener tests | — |

Si se aprueba, se convierte en la spec `003-stack-definitivo` y se actualizan `.env.example` y `AGENTS.md §3` con la estructura del código.
